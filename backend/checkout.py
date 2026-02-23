from flask import Blueprint, request, jsonify, abort
import os
from dotenv import load_dotenv
from .qr_functions import verify_token
from .model_functions import compute_cart_price, send_receipt_email

checkout_bp = Blueprint('checkout', __name__)

# database connection and models
from .models import db, Cart, User, CartItem, Product, FridgeItem
load_dotenv()
OWN_EMAIL = os.getenv("OWN_EMAIL", "test@example.com")

@checkout_bp.route('/<store_id>/<cart_id>', methods=['POST'])
def checkout_cart(cart_id, store_id):
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
        abort(403, "Missing user_id in token")

    #chgeck if user exists
    if not User.query.filter_by(user_id=user_id).first():
        abort(403, "User not found")

    # Check if the cart belongs to the user
    cart = Cart.query.get(cart_id)
    if not cart or cart.user_id != user_id:
        abort(403, "Cart does not belong to the user")

    # Proceed with checkout logic
    # Now a few things need to happen:
    # 1. Compute the price of the cart
    price = compute_cart_price(cart_id)
    # 2. Send this price to the payment gateway of the checkout. I don't know how to this, so I'll ask a supermarket
    # 3. Maybe in some other place, get a confirmation of the success of the payment
    # 4. Mark cart as payed
    cart.payed = True
    db.session.commit()
    # 5. Send the reciept to the user 
    user_email = User.query.get(user_id).email
    fr_email = OWN_EMAIL
    items = []
    cart_items = CartItem.query.filter_by(cart_id=cart_id).all()
    for item in cart_items:
        product = Product.query.get(item.product_id)
        items.append({
            "name": product.name,
            "quantity": item.quantity,
            "price": product.price
        })
    send_receipt_email(user_email, fr_email, items, price)
    # 6. Add all items to fridge
    for item in cart_items:
        FridgeItem.from_cart_item(item)

    return {"status": "success", "price": price}

