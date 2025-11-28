from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, ShoppingTrip, Product
from datetime import datetime, timedelta
import secrets

imports_bp = Blueprint('imports', __name__)

@imports_bp.route('/<token>', methods=['GET'])
@jwt_required()
def import_shopping_trip(token):
    """
    User scannt QR-Code -> App ruft diesen Endpoint auf
    """
    user_id = get_jwt_identity()
    
    # Finde Shopping Trip
    trip = ShoppingTrip.query.filter_by(token=token).first()
    
    if not trip:
        return jsonify({'error': 'Ungültiger QR-Code'}), 404
    
    # Check Token-Alter (24h Limit)
    if datetime.utcnow() - trip.timestamp > timedelta(hours=24):
        return jsonify({'error': 'QR-Code abgelaufen'}), 410
    
    if trip.imported:
        return jsonify({'error': 'Bereits importiert'}), 409
    
    # Markiere als importiert
    trip.imported = True
    trip.user_id = user_id
    db.session.commit()
    
    # Lade Produkte
    products = Product.query.filter_by(trip_id=trip.id).all()
    
    # Update user_id für alle Produkte
    for p in products:
        p.user_id = user_id
    db.session.commit()
    
    return jsonify({
        'trip_id': trip.id,
        'store': trip.store_name,
        'timestamp': trip.timestamp.isoformat(),
        'products': [{
            'id': p.id,
            'name': p.name,
            'category': p.category,
            'expiration_date': p.expiration_date.isoformat()
        } for p in products]
    })

@imports_bp.route('/generate', methods=['POST'])
def generate_qr_token():
    """
    Supermarkt-Kasse generiert QR-Code
    (Später: Nur für autorisierte Partner)
    """
    data = request.json
    products_data = data.get('products', [])
    store_name = data.get('store_name', 'Unknown')
    
    # Generiere Token
    token = secrets.token_urlsafe(16)
    
    # Erstelle Shopping Trip
    trip = ShoppingTrip(
        token=token,
        store_name=store_name
    )
    db.session.add(trip)
    db.session.commit()
    
    # Füge Produkte hinzu
    for prod in products_data:
        product = Product(
            trip_id=trip.id,
            name=prod['name'],
            category=prod.get('category', 'Sonstiges'),
            expiration_date=datetime.fromisoformat(prod['expiration_date'])
        )
        db.session.add(product)
    
    db.session.commit()
    
    return jsonify({
        'token': token,
        'qr_url': f'https://api.freshreminder.de/import/{token}',
        'expires_at': (datetime.utcnow() + timedelta(hours=24)).isoformat()
    })