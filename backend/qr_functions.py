import time
import jwt
import os
from dotenv import load_dotenv

SECRET_KEY = os.getenv("SECRET_KEY", "secret_key_standart")

def generate_checkout_token(cart_id, user_id):
    payload = {
        "cart_id": cart_id,
        "user_id": user_id,
        "exp": int(time.time()) + 300  # expires in 5 minutes
    }

    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

    return token

def verify_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception:
        return None

def create_qr_beta(cart):
    # Generate a QR code for the cart
    # This is a placeholder function
    print(f"Generating QR code for cart: {cart.cart_id}")