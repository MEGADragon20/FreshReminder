from flask import Blueprint, request, jsonify
import uuid
from .qr_functions import create_qr_beta

cart_bp = Blueprint('cart', __name__)

# database connection and models
from .models import db, Cart, CartItem, Product


@cart_bp.route('/create', methods=['POST'])
def create_cart():
    data = request.get_json()
    if not data or 'user_id' not in data or 'store_id' not in data:
        return jsonify({'error': 'user_id and store_id are required'}), 400
    cart_id = str(uuid.uuid4())
    cart = {
        'cart_id': cart_id,
        'user_id': data.get('user_id'),
        'store_id': data.get('store_id'),
        'status': 'active',
        'items': []
    }
    db.session.add(Cart(cart_id=cart_id, user_id=data.get('user_id'), payed=False, price=0.0))
    db.session.commit()
    return jsonify(cart), 201

@cart_bp.route('/remove/<cart_id>', methods=['DELETE'])
def remove_cart(cart_id):
    if not cart_id:
        return jsonify({'error': 'cart_id is required'}), 400
    if not Cart.query.filter_by(cart_id=cart_id).first():
        return jsonify({'error': 'Cart not found'}), 404
    Cart.query.filter_by(cart_id=cart_id).delete()
    db.session.commit()
    return jsonify({'message': 'Cart removed'}), 200

@cart_bp.route('/<cart_id>', methods=['GET'])
def get_cart(cart_id):
    cart = Cart.query.filter_by(cart_id=cart_id).first()
    if not cart:
        return jsonify({'error': 'Cart not found'}), 404
    return jsonify({
        'cart_id': cart.cart_id,
        'user_id': cart.user_id,
        'payed': cart.payed,
        'price': cart.price,
        'created_at': cart.created_at
    })
@cart_bp.route('/<cart_id>/add', methods=['POST'])
def add_item(cart_id):
    cart = Cart.query.filter_by(cart_id=cart_id).first()
    if not cart:
        return jsonify({'error': 'Cart not found'}), 404
    data = request.get_json()
    if not data or 'product_id' not in data:
        return jsonify({'error': 'product_id is required'}), 400
    #check if product exists in the store
    if not Product.query.filter_by(product_id=data.get('product_id')).first():
        return jsonify({'error': 'Product not found in store'}), 404
    # check if product is already in cart
    existing_item = CartItem.query.filter_by(cart_id=cart_id, product_id=data.get('product_id')).first()
    if existing_item:
        existing_item.quantity += data.get('quantity', 1)
        db.session.commit()
        return jsonify({
            'cart_item_id': existing_item.cart_item_id,
            'product_id': data.get('product_id'),
            'quantity': existing_item.quantity
        }), 200
    else:
        cart_item_id = str(uuid.uuid4())
        cart_item = CartItem(cart_id=cart_id, cart_item_id=cart_item_id, product_id=data.get('product_id'), quantity=1)
        db.session.add(cart_item)
        db.session.commit()
        return jsonify({
            'cart_item_id': cart_item_id,
            'product_id': data.get('product_id'),
            'quantity': data.get('quantity', 1)
        }), 201

@cart_bp.route('/<cart_id>/remove/<cart_item_id>', methods=['DELETE'])
def remove_item(cart_id, cart_item_id):
    cart_item = CartItem.query.filter_by(cart_id=cart_id, cart_item_id=cart_item_id).first()
    if not cart_item:
        return jsonify({'error': 'Cart item not found'}), 404
    db.session.delete(cart_item)
    db.session.commit()
    return jsonify({'message': 'Cart item removed'}), 200

@cart_bp.route('/<cart_id>/update/<cart_item_id>/<quantity>', methods=['PUT'])
def update_item(cart_id, cart_item_id, quantity):
    """
    Updates the quantity of a cart item.
    """
    cart_item = CartItem.query.filter_by(cart_id=cart_id, cart_item_id=cart_item_id).first()
    if not cart_item:
        return jsonify({'error': 'Cart item not found'}), 404
    cart_item.quantity = int(quantity)
    db.session.commit()
    return jsonify({
        'cart_item_id': cart_item.cart_item_id,
        'product_id': cart_item.product_id,
        'quantity': cart_item.quantity
    }), 200

@cart_bp.route('/<cart_id>/checkout', methods=['POST'])
def checkout(cart_id):
    cart = Cart.query.filter_by(cart_id=cart_id).first()
    if not cart:
        return jsonify({'error': 'Cart not found'}), 404
    if cart.payed:
        return jsonify({'error': 'Cart already payed'}), 400
    create_qr_beta(cart)