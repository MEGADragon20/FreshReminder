from flask import Blueprint, request, jsonify
import uuid
from .qr_functions import create_qr_beta
from .models import db, Cart
from auth import login_required # or somethging similar, actually everything should need this
from model_functions import compute_cart_price

payment_bp = Blueprint('payment', __name__)

@payment_bp.route("/cart", methods=["POST"])
@login_required
def pay_cart():
    data = request.get_json()
    if "id" not in data or not data:
        return jsonify({'error':'id is required'}), 400
    cart_id = data["id"]
    price = compute_cart_price(cart_id)
    # something with stripe or similar here

    
