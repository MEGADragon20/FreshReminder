from flask import Flask, jsonify
import os

from models import db


def create_app():
    app = Flask(__name__)
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        SQLALCHEMY_DATABASE_URI=os.environ.get('DATABASE_URL', 'sqlite:///freshreminder.db'),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
    )

    db.init_app(app)

    # Register blueprints
    try:
        from auth import auth_bp
        from products import products_bp
        from cart import cart_bp
        from fridge import fridge_bp

        app.register_blueprint(auth_bp, url_prefix='/auth')
        app.register_blueprint(products_bp, url_prefix='/products')
        app.register_blueprint(cart_bp, url_prefix='/cart')
        app.register_blueprint(fridge_bp, url_prefix='/fridge')
    except Exception:
        # Best-effort import if running as script
        try:
            from .auth import auth_bp
            from .products import products_bp
            from .cart import cart_bp
            app.register_blueprint(auth_bp, url_prefix='/auth')
            app.register_blueprint(products_bp, url_prefix='/products')
            app.register_blueprint(cart_bp, url_prefix='/cart')
        except Exception:
            pass

    @app.route('/')
    def index():
        return jsonify({'service': 'FreshReminder Backend', 'status': 'ok'})

    # Ensure DB tables exist
    with app.app_context():
        db.drop_all()  # For development, drop existing tables to reset state
        db.create_all()

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)), debug=True)
