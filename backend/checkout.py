from flask import Blueprint, request, jsonify, abort
import stripe, os
from models import db, Cart, User, CartItem, Product, FridgeItem
from model_functions import compute_cart_price, send_receipt_email, get_store_from_cart_id
from qr_functions import verify_token

OWN_EMAIL = ""

checkout_bp = Blueprint('checkout', __name__)

@checkout_bp.route('/<cart_id>', methods=['POST'])
def checkout_cart(cart_id):

    token = request.json.get("token")
    if not token:
        abort(400, "Missing token")

    payload = verify_token(token)
    if not payload:
        abort(403, "Invalid or expired token")

    if str(payload["cart_id"]) != str(cart_id):
        abort(403, "Cart ID mismatch")

    user_id = payload.get("user_id")
    if not user_id:
        abort(403, "Missing user_id")

    cart = Cart.query.get(cart_id)
    if not cart or cart.user_id != user_id:
        abort(403, "Cart does not belong to user")

    store_id = get_store_from_cart_id(cart_id).store_id

    price = compute_cart_price(cart_id)

    if price <= 0:
        abort(400, "Cart total must be greater than 0")

    session = stripe.checkout.Session.create(
        payment_method_types=["card"],
        mode="payment",
        line_items=[{
            "price_data": {
                "currency": "usd",
                "product_data": {
                    "name": f"Store {store_id} - Cart {cart_id}",
                },
                "unit_amount": int(price * 100),
            },
            "quantity": 1,
        }],
        success_url="http://localhost:3000/success",
        cancel_url="http://localhost:3000/cancel",
        metadata={
            "cart_id": cart_id,
            "user_id": user_id
        }
    )

    return jsonify({
        "checkout_url": session.url
    })

@checkout_bp.route('/webhook', methods=['POST'])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except Exception:
        return "Invalid payload", 400

    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']

        cart_id = session['metadata']['cart_id']
        user_id = session['metadata']['user_id']

        cart = Cart.query.get(cart_id)
        if not cart:
            return "Cart not found", 400

        if not cart.payed:
            cart.payed = True
            db.session.commit()

            # send receipt
            user = User.query.get(user_id)
            cart_items = CartItem.query.filter_by(cart_id=cart_id).all()

            items = []
            for item in cart_items:
                product = Product.query.get(item.product_id)
                items.append({
                    "name": product.name,
                    "quantity": item.quantity,
                    "price": product.price
                })

            price = compute_cart_price(cart_id)
            send_receipt_email(user.email, OWN_EMAIL, items, price)

            # move to fridge
            for item in cart_items:
                FridgeItem.from_cart_item(item)

    return "Success", 200