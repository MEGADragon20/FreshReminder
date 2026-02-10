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


@fridge_bp.route('/remove/<string:id>', methods=['POST'])
def remove_fridge_item(id):
    auth = request.headers.get('Authorization')
    if not auth or not auth.startswith('Bearer '):
        return jsonify({'error': 'missing authorization'}), 401
    token = auth.replace('Bearer ', '')
    user = User.query.filter_by(token=token).first()
    if not user:
        return jsonify({'error': 'invalid token'}), 401

    # Try to find fridge item by id
    it = FridgeItem.query.filter_by(fridge_item_id=id, user_id=user.user_id).first()
    if not it:
        return jsonify({'error': 'not found'}), 404

    try:
        # Remove the item
        from models import db

        db.session.delete(it)
        db.session.commit()
        return jsonify({'status': 'removed'}), 200
    except Exception as e:
        return jsonify({'error': 'failed', 'msg': str(e)}), 500


@fridge_bp.route('/add/<string:id>', methods=['POST'])
def add_fridge_item(id):
    auth = request.headers.get('Authorization')
    if not auth or not auth.startswith('Bearer '):
        return jsonify({'error': 'missing authorization'}), 401
    token = auth.replace('Bearer ', '')
    user = User.query.filter_by(token=token).first()
    if not user:
        return jsonify({'error': 'invalid token'}), 401

    # Basic behaviour: if id matches a product_id, try to use product info
    # Otherwise, treat id as product name and create a default fridge item
    try:
        from models import db, Product
        product = Product.query.filter_by(product_id=id).first()
        if product:
            # best_before_days may be stored differently; fall back to 7 days
            try:
                days = int(getattr(product, 'best_before_days', 7))
            except Exception:
                days = 7
            from datetime import datetime, timedelta
            bbd = (datetime.utcnow().date() + timedelta(days=days))
            fi = FridgeItem(user_id=user.user_id, product_name=product.product_name, quantity=1, best_before_date=bbd)
        else:
            # treat id as plain name
            from datetime import datetime, timedelta
            bbd = (datetime.utcnow().date() + timedelta(days=7))
            fi = FridgeItem(user_id=user.user_id, product_name=id, quantity=1, best_before_date=bbd)

        db.session.add(fi)
        db.session.commit()
        return jsonify({'status': 'added', 'item': fi.as_dict()}), 200
    except Exception as e:
        return jsonify({'error': 'failed', 'msg': str(e)}), 500


@fridge_bp.route('/add', methods=['POST'])
def add_fridge_item_body():
    auth = request.headers.get('Authorization')
    if not auth or not auth.startswith('Bearer '):
        return jsonify({'error': 'missing authorization'}), 401
    token = auth.replace('Bearer ', '')
    user = User.query.filter_by(token=token).first()
    if not user:
        return jsonify({'error': 'invalid token'}), 401

    data = request.get_json(silent=True) or {}
    name = data.get('product_name')
    quantity = data.get('quantity', 1)
    bbd = data.get('best_before_date')
    if not name or not bbd:
        return jsonify({'error': 'missing fields'}), 400

    try:
        from models import db
        from datetime import datetime
        # Accept date in ISO format YYYY-MM-DD
        try:
            bbd_date = datetime.fromisoformat(bbd).date()
        except Exception:
            return jsonify({'error': 'invalid date format'}), 400

        fi = FridgeItem(user_id=user.user_id, product_name=name, quantity=int(quantity), best_before_date=bbd_date)
        db.session.add(fi)
        db.session.commit()
        return jsonify({'status': 'added', 'item': fi.as_dict()}), 200
    except Exception as e:
        return jsonify({'error': 'failed', 'msg': str(e)}), 500
