from flask import Blueprint, request, jsonify
import uuid
from models import Product, db, Store, Employee
from functools import wraps

def store_employee_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        store_id = request.view_args.get("store_id")
        auth = request.headers.get('Authorization')
        if not auth or not auth.startswith('Bearer '):
            return jsonify({'error': 'missing authorization'}), 401

        token = auth.replace('Bearer ', '')
        store_token = Store.query.filter_by(store_id=store_id).first().token
        if not store_token or token != store_token:
            return jsonify({'error': 'invalid token'}), 401
        if token == store_token:
            return jsonify({'error': 'invalid token'}), 401

        return f(*args, **kwargs)

    return decorated

def store_manager_required(f): #TODO
    @wraps(f)
    def decorated(*args, **kwargs):
        pass
    return decorated

store_bp = Blueprint('store', __name__)

@store_bp.route('/<store_id>/products', methods=['GET'])
@store_employee_required
def list_products(store_id): # same as /products/store/<store_id>
    products = Product.query.filter_by(store_id=store_id).all()
    return jsonify({'products': [p.to_dict() for p in products]}), 200

@store_bp.route('/<store_id>/employees', methods=['GET'])
@store_employee_required
def display_employees(store_id):
    store = Store.query.filter_by(store_id=store_id).first()
    if not store:
        return jsonify({'error': 'store not found'}), 404
    employees = Employee.query.filter_by(store_id=store_id).all()
    return jsonify({'employees': [e.to_dict() for e in employees]}), 200

@store_bp.route('/<store_id>/products', methods=['POST'])
@store_employee_required
def create_product(store_id): # needs to be adapted to what frontend can provide
    data = request.get_json() or {}
    product_id = str(uuid.uuid4())
    product = {
        'product_id': product_id,
        'store_id': store_id,
        'barcode': data.get('barcode'),
        'product_name': data.get('product_name'),
        'brand': data.get('brand'), 
         'category': data.get('category'),
        'default_shelf_life_days': data.get('default_shelf_life_days')
    }
    db.session.add(Product(**product))
    db.session.commit()
    return jsonify(product), 201

@store_bp.route('/<store_id>/products/<product_id>', methods=['DELETE'])
@store_employee_required
def delete_product(store_id, product_id):
    product = Product.query.filter_by(store_id=store_id, product_id=product_id).first()
    if not product:
        return jsonify({'error': 'not found'}), 404
    try:
        db.session.delete(product)
        db.session.commit()
        return jsonify({'status': 'deleted'}), 200
    except Exception as e:
        return jsonify({'error': 'failed', 'msg': str(e)}), 500

@store_bp.route('/<store_id>/employees/<employee_id>', methods=['DELETE'])
@store_manager_required
def delete_employee(store_id, employee_id):
    employee = Employee.query.filter_by(store_id=store_id, employee_id=employee_id).first()
    if not employee:
        return jsonify({'error': 'not found'}), 404
    try:
        db.session.delete(employee)
        db.session.commit()
        return jsonify({'status': 'deleted'}), 200
    except Exception as e:
        return jsonify({'error': 'failed', 'msg': str(e)}), 500

@store_bp.route('/<store_id>/employees', methods=['POST'])
@store_manager_required
def create_employee(store_id):
    data = request.get_json() or {}
    employee_id = str(uuid.uuid4())
    employee = {
        'employee_id': employee_id,
        'store_id': store_id,
        'email': data.get('email'),
        'password_hash': data.get('password'), # In a real app, hash this!
        'is_manager': data.get('is_manager', False)
    }
    db.session.add(Employee(**employee))
    db.session.commit()
    return jsonify(employee), 201