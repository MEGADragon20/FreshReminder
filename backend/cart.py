from flask import Blueprint, request, jsonify
import uuid

cart_bp = Blueprint('cart', __name__)

# Minimal in-memory carts
_carts = {}


@cart_bp.route('/create', methods=['POST'])
def create_cart():
    data = request.get_json() or {}
    cart_id = str(uuid.uuid4())
    cart = {
        'cart_id': cart_id,
        'user_id': data.get('user_id'),
        'store_id': data.get('store_id'),
        'status': 'active',
        'items': []
    }
    _carts[cart_id] = cart
    return jsonify(cart), 201


@cart_bp.route('/<cart_id>', methods=['GET'])
def get_cart(cart_id):
    cart = _carts.get(cart_id)
    if not cart:
        return jsonify({'error': 'not found'}), 404
    return jsonify(cart)


@cart_bp.route('/<cart_id>/items', methods=['POST'])
def add_item(cart_id):
    cart = _carts.get(cart_id)
    if not cart:
        return jsonify({'error': 'not found'}), 404
    data = request.get_json() or {}
    item = {
        'cart_item_id': str(uuid.uuid4()),
        'lot_id': data.get('lot_id'),
        'quantity': data.get('quantity', 1)
    }
    cart['items'].append(item)
    return jsonify(item), 201
