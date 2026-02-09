from flask import Blueprint, request, jsonify
from models import User, FridgeItem

fridge_bp = Blueprint('fridge', __name__)


@fridge_bp.route('/', methods=['GET'])
def list_fridge():
    # Expect Authorization: Bearer <token>
    auth = request.headers.get('Authorization')
    if not auth or not auth.startswith('Bearer '):
        return jsonify({'error': 'missing authorization'}), 401
    token = auth.replace('Bearer ', '')
    user = User.query.filter_by(token=token).first()
    if not user:
        return jsonify({'error': 'invalid token'}), 401

    items = FridgeItem.query.filter_by(user_id=user.user_id).all()
    return jsonify({'items': [it.as_dict() for it in items]})
