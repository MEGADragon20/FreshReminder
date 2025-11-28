from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    push_token = db.Column(db.String(255))
    notification_time = db.Column(db.Integer, default=18)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class ShoppingTrip(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    token = db.Column(db.String(64), unique=True, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    imported = db.Column(db.Boolean, default=False)
    store_name = db.Column(db.String(100))

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    trip_id = db.Column(db.Integer, db.ForeignKey('shopping_trip.id'))
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    name = db.Column(db.String(200), nullable=False)
    category = db.Column(db.String(100))
    expiration_date = db.Column(db.Date, nullable=False)
    added_at = db.Column(db.DateTime, default=datetime.utcnow)
    removed_at = db.Column(db.DateTime, nullable=True)
    removed_by = db.Column(db.String(20))
