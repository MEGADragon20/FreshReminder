from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy
import uuid

db = SQLAlchemy()


def gen_uuid():
    return str(uuid.uuid4())


class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    token = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password): 
        return check_password_hash(self.password_hash, password)

class Store(db.Model):
    __tablename__ = 'stores'
    store_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    store_name = db.Column(db.String(255), nullable=False)
    manager_id = db.Column(db.String(36), db.ForeignKey('employees.employee_id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Employee(db.Model):
    __tablename__ = 'employees'
    employee_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    store_id = db.Column(db.String(36), db.ForeignKey('stores.store_id'), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    is_manager = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Product(db.Model): #In store
    __tablename__ = 'products'
    store_id = db.Column(db.String(36), db.ForeignKey('stores.store_id'), nullable=False)
    product_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    product_name = db.Column(db.String(255), nullable=False)
    best_before_date = db.Column(db.DateTime, nullable=False)
    price = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Cart(db.Model): #User's Cart
    __tablename__ = 'carts'
    cart_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    user_id = db.Column(db.String(36), db.ForeignKey('users.user_id'), nullable=False)
    payed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
class CartItem(db.Model): #In Cart
    __tablename__ = 'cart_items'
    cart_id = db.Column(db.String(36), db.ForeignKey('carts.cart_id'), nullable=False)
    cart_item_id = db.Column(db.String(36), unique=True, nullable=False, primary_key=True, default=gen_uuid)
    #user_id = db.Column(db.String(36), db.ForeignKey('users.user_id'), nullable=False) # Not needed since we can get user_id from Cart_id
    product_id = db.Column(db.String(36), db.ForeignKey('products.product_id'), nullable=False)
    quantity = db.Column(db.Integer, default=1)
    added_at = db.Column(db.DateTime, default=datetime.utcnow)

class FridgeItem(db.Model): #In Fridge
    __tablename__ = 'fridge_items'
    fridge_item_id = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    user_id = db.Column(db.String(36), db.ForeignKey('users.user_id'), nullable=False)
    product_name = db.Column(db.String(255), nullable=False)
    quantity = db.Column(db.Integer, default=1)
    best_before_date = db.Column(db.Date, nullable=False)
    added_at = db.Column(db.DateTime, default=datetime.utcnow)
    consumed_at = db.Column(db.DateTime, nullable=True, default=None)
    status = db.Column(db.String(20), default='active')

    def as_dict(self):
        """Not finished"""
        return {
            'fridge_item_id': self.fridge_item_id,
            'user_id': self.user_id,
            'product_name': self.product_name,
            'quantity': self.quantity,
            'best_before_date': self.best_before_date.isoformat(),
            'status': self.status,
        }


def seed_default_items_for_user(db_session, user_id):
    # Create three default test items with future expiry dates
    items = [
        ('Milk', 1, datetime.utcnow().date() + timedelta(days=7)),
        ('Eggs', 12, datetime.utcnow().date() + timedelta(days=14)),
        ('Butter', 1, datetime.utcnow().date() + timedelta(days=30)),
    ]
    for name, qty, bbd in items:
        fi = FridgeItem(user_id=user_id, product_name=name, quantity=qty, best_before_date=bbd)
        db_session.add(fi)
    db_session.commit()
