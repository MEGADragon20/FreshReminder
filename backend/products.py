from flask import Blueprint, request, jsonify
import uuid
from models import Product, db, Store
from functools import wraps

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization')
        if not auth or not auth.startswith('Bearer '):
            return jsonify({'error': 'missing authorization'}), 401

        token = auth.replace('Bearer ', '')
        # Here you would normally verify the token and check if the user is an admin
        # For simplicity, we'll just check if the token is "admin-token"
        if token != "admin-token":
            return jsonify({'error': 'invalid token'}), 401

        return f(*args, **kwargs)

    return decorated

def store_employee_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        store_id = request.view_args.get("store_id")
        auth = request.headers.get('Authorization')
        if not auth or not auth.startswith('Bearer '):
            return jsonify({'error': 'missing authorization'}), 401

        token = auth.replace('Bearer ', '')
        # Here you would normally verify the token and check if the user is a shop owner
        # For simplicity, we'll just check if the token is "shop-owner-token"
        store_token = Store.query.filter_by(store_id=store_id).first().token
        if not store_token or token != store_token:
            return jsonify({'error': 'invalid token'}), 401
        if token == store_token:
            return jsonify({'error': 'invalid token'}), 401

        return f(*args, **kwargs)

    return decorated

products_bp = Blueprint('products', __name__)



@products_bp.route('/', methods=['GET'])
@admin_required
def list_products():
    q = request.args.get('q')
    items = Product.query.all()
    if q:
        items = [p for p in items if q.lower() in p.product_name.lower()]
    return jsonify({'products': [p.to_dict() for p in items]})

@products_bp.route('/<product_id>', methods=['GET'])
def get_product(product_id):
    p = Product.query.get(product_id)
    if not p:
        return jsonify({'error': 'not found'}), 404
    return jsonify(p.to_dict())

@products_bp.route('/store/<store_id>', methods=['DELETE'])
@store_employee_required
def display_products_in_store(store_id):
    products = Product.query.filter_by(store_id=store_id).all()
    return jsonify({'products': [p.to_dict() for p in products]}), 200


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
    db.session.add(Product(**product))
    db.session.commit()
    return jsonify(product), 201
