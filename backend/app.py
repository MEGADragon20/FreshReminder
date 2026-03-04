from flask import Flask, jsonify
import os
from models import db
from .extensions import login_manager


def create_app():
    app = Flask(__name__)
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        SQLALCHEMY_DATABASE_URI=os.environ.get('DATABASE_URL', 'sqlite:///freshreminder.db'),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
    )
    login_manager.init_app(app)
    db.init_app(app)

    from auth import auth_bp
    from products import products_bp
    from cart import cart_bp
    from fridge import fridge_bp
    from checkout import checkout_bp
    from payment import payment_bp
    from store import store_bp

    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(products_bp, url_prefix='/products')
    app.register_blueprint(cart_bp, url_prefix='/cart')
    app.register_blueprint(fridge_bp, url_prefix='/fridge')
    app.register_blueprint(store_bp, url_prefix='/store')
    app.register_blueprint(payment_bp, url_prefix='/payment')
    app.register_blueprint(checkout_bp, url_prefix='/checkout')

    @app.route('/')
    def index():
        return 200

    @app.route('/health')
    def health():
        return jsonify({'service': 'FreshReminder Backend', 'status': 'ok'})

    # Ensure DB tables exist
    with app.app_context():
        db.drop_all()  # For development, drop existing tables to reset state
        db.create_all()

    return app


if __name__ == '__main__':
    app = create_app()
    #app.config["SERVER_NAME"] = ""
    app.url_map.default_subdomain = "api"
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)), debug=True)
