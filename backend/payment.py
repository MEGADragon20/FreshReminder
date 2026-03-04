from flask import Blueprint, request, jsonify
import uuid
from qr_functions import create_qr_beta
from models import db, Cart, User
from extensions import login_required
from model_functions import compute_cart_price

payment_bp = Blueprint('payment', __name__)

@payment_bp.route("/cart", methods=["POST"])
@login_required
def pay_cart():
    data = request.get_json()
    if "id" not in data or not data:
        return jsonify({'error':'id is required'}), 400
    cart_id = data["id"]
    cart = Cart.query.filter_by(cart_id = cart_id)
    price = compute_cart_price(cart_id)
    user = User.query.filter_by(user_id = cart.user_id)
    # something with stripe or similar here