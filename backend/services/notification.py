import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate('firebase-key.json')
firebase_admin.initialize_app(cred)

def send_expiration_notification(user_token, product_name, days_left):
    message = messaging.Message(
        notification=messaging.Notification(
            title='FreshReminder',
            body=f'{product_name} läuft in {days_left} Tagen ab!',
        ),
        token=user_token,
    )
    
    response = messaging.send(message)
    return response