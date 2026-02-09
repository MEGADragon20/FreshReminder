from flask import Blueprint, request, jsonify
import uuid

products_bp = Blueprint('products', __name__)

# Simple in-memory product catalog for scaffold/demo
_products = {}


@products_bp.route('/', methods=['GET'])
def list_products():
    q = request.args.get('q')
    items = list(_products.values())
    if q:
        items = [p for p in items if q.lower() in p.get('product_name', '').lower()]
    return jsonify({'products': items})


@products_bp.route('/<product_id>', methods=['GET'])
def get_product(product_id):
    p = _products.get(product_id)
    if not p:
        return jsonify({'error': 'not found'}), 404
    return jsonify(p)


@products_bp.route('/', methods=['POST'])
def create_product():
    data = request.get_json() or {}
    product_id = str(uuid.uuid4())
    product = {
        'product_id': product_id,
        'barcode': data.get('barcode'),
        'product_name': data.get('product_name'),
        'brand': data.get('brand'),
        'category': data.get('category'),
        'default_shelf_life_days': data.get('default_shelf_life_days')
    }
    _products[product_id] = product
    return jsonify(product), 201
