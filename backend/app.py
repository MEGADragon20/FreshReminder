from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from models import db
from config import config

app = Flask(__name__)
app.config.from_object(config)
CORS(app)
jwt = JWTManager(app)
db.init_app(app)

# Import Blueprints
from api.products import products_bp
from api.imports import imports_bp
from api.users import users_bp

app.register_blueprint(products_bp, url_prefix='/api/products')
app.register_blueprint(imports_bp, url_prefix='/api/import')
app.register_blueprint(users_bp, url_prefix='/api/users')

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

# Create database tables
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
