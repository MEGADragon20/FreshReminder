from flask_login import LoginManager, login_required, login_user
from models import User
login_manager = LoginManager

@login_manager.user_loader
def load_user(user_id):
    return User.query.filter_by(user_id = user_id).first()