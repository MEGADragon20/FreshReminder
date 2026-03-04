from flask_login import LoginManager, login_required, login_user
from models import User
login_manager = LoginManager()


@login_manager.request_loader
def load_user_from_request(request):
    token = request.args.get('token')
    if token:
        user = User.query.filter_by(api_key=token).first()
        if user:
            return user

    return None
