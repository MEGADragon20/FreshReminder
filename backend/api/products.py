from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Product
from datetime import datetime

products_bp = Blueprint('products', __name__)

@products_bp.route('/', methods=['GET'])
@jwt_required()
def get_products():
    """Alle aktiven Produkte des Users"""
    user_id = get_jwt_identity()
    products = Product.query.filter_by(
        user_id=user_id,
        removed_at=None
    ).order_by(Product.expiration_date).all()
    
    return jsonify([{
        'id': p.id,
        'name': p.name,
        'category': p.category,
        'expiration_date': p.expiration_date.isoformat(),
        'added_at': p.added_at.isoformat()
    } for p in products])

@products_bp.route('/', methods=['POST'])
@jwt_required()
def add_product():
    """Manuell Produkt hinzufügen"""
    user_id = get_jwt_identity()
    data = request.json
    
    product = Product(
        user_id=user_id,
        name=data['name'],
        category=data.get('category', 'Sonstiges'),
        expiration_date=datetime.fromisoformat(data['expiration_date'])
    )
    db.session.add(product)
    db.session.commit()
    
    return jsonify({'id': product.id, 'message': 'Produkt hinzugefügt'}), 201

@products_bp.route('/<int:product_id>', methods=['DELETE'])
@jwt_required()
def remove_product(product_id):
    """Produkt entfernen"""
    user_id = get_jwt_identity()
    product = Product.query.filter_by(id=product_id, user_id=user_id).first()
    
    if not product:
        return jsonify({'error': 'Produkt nicht gefunden'}), 404
    
    product.removed_at = datetime.utcnow()
    product.removed_by = 'user'
    db.session.commit()
    
    return jsonify({'message': 'Produkt entfernt'})