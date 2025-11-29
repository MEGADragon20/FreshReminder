from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from models import db, User

users_bp = Blueprint('users', __name__)

@users_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'Email bereits registriert'}), 409
    
    user = User(
        email=email,
        password_hash=generate_password_hash(password)
    )
    db.session.add(user)
    db.session.commit()
    
    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user_id': user.id}), 201

@users_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    user = User.query.filter_by(email=data['email']).first()
    
    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({'error': 'Ungültige Anmeldedaten'}), 401
    
    token = create_access_token(identity=str(user.id))
    return jsonify({'token': token, 'user_id': user.id})

@users_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    return jsonify({
        'email': user.email,
        'notification_time': user.notification_time,
        'created_at': user.created_at.isoformat()
    })

@users_bp.route('/push-token', methods=['POST'])
@jwt_required()
def update_push_token():
    user_id = int(get_jwt_identity())
    token = request.json.get('token')
    
    user = User.query.get(user_id)
    user.push_token = token
    db.session.commit()
    
    return jsonify({'message': 'Push Token aktualisiert'})