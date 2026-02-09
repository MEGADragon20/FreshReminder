from flask import Blueprint, request, jsonify
from models import db, User, seed_default_items_for_user
from werkzeug.security import generate_password_hash

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400

    existing = User.query.filter_by(email=email).first()
    if existing:
        return jsonify({'error': 'user exists'}), 409

    user = User(email=email)
    user.set_password(password)
    # create a simple token placeholder
    user.token = generate_password_hash(email + str(db.func.now()))
    db.session.add(user)
    db.session.commit()

    # Seed default fridge items
    seed_default_items_for_user(db.session, user.user_id)

    return jsonify({'user_id': user.user_id, 'email': user.email, 'access_token': user.token}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400

    user = User.query.filter_by(email=email).first()
    if user and user.check_password(password):
        # In real impl issue JWT; here return stored token
        return jsonify({'access_token': user.token, 'user': {'user_id': user.user_id, 'email': user.email}})

    return jsonify({'error': 'invalid credentials'}), 401


@auth_bp.route('/verify-2fa', methods=['POST'])
def verify_2fa():
    return jsonify({'verified': True})


@auth_bp.route('/refresh-token', methods=['POST'])
def refresh_token():
    return jsonify({'access_token': 'refreshed-fake-token'})


@auth_bp.route('/logout', methods=['POST'])
def logout():
    return jsonify({'logged_out': True})


@auth_bp.route('/me', methods=['GET'])
def me():
    # Simple implementation: read token from header and lookup user
    auth = request.headers.get('Authorization')
    if not auth:
        return jsonify({'user': None})
    token = auth.replace('Bearer ', '')
    user = User.query.filter_by(token=token).first()
    if not user:
        return jsonify({'user': None})
    return jsonify({'user_id': user.user_id, 'email': user.email})
