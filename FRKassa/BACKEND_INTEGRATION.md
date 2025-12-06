# FRKassa - Backend Integration Guide

This guide explains how to integrate the FRKassa employee app with your FreshReminder backend.

## Overview

FRKassa is the employee-facing mobile app that:
1. Scans QR codes containing product information
2. Builds a shopping cart of scanned products
3. Submits the cart to the backend as a CloudCart
4. The CloudCart is accessible via API for 24 hours

## Backend Requirements

### 1. CloudCart Model

You need to add a CloudCart model to your backend database:

```python
from datetime import datetime, timedelta

class CloudCart(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    unique_id = db.Column(db.String(64), unique=True, nullable=False)  # Unique identifier for the cart
    products = db.Column(db.JSON, nullable=False)  # List of products
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, default=lambda: datetime.utcnow() + timedelta(hours=24))
    
    def is_expired(self):
        return datetime.utcnow() > self.expires_at
```

### 2. API Endpoint

Add a new blueprint for CloudCart operations:

**File: `backend/api/cloudcart.py`**

```python
from flask import Blueprint, request, jsonify
from models import db, CloudCart
from datetime import datetime, timedelta
import uuid

cloudcart_bp = Blueprint('cloudcart', __name__)

@cloudcart_bp.route('/<unique_id>', methods=['POST'])
def create_or_update_cloudcart(unique_id):
    """
    Create or update a CloudCart with scanned products.
    
    Request:
    {
        "products": [
            {
                "name": "Product Name",
                "bestBeforeDate": "2025-12-15",
                "additionalInfo": "Optional"
            }
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'products' not in data:
            return jsonify({'error': 'Missing products field'}), 400
        
        # Check if cart exists
        cart = CloudCart.query.filter_by(unique_id=unique_id).first()
        
        if not cart:
            # Create new cart
            cart = CloudCart(
                unique_id=unique_id,
                products=data['products'],
                expires_at=datetime.utcnow() + timedelta(hours=24)
            )
            db.session.add(cart)
        else:
            # Update existing cart (replace products)
            cart.products = data['products']
            cart.expires_at = datetime.utcnow() + timedelta(hours=24)
        
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': 'CloudCart created/updated successfully',
            'cloudCartId': cart.unique_id,
            'productCount': len(data['products']),
            'expiresAt': cart.expires_at.isoformat()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Error creating CloudCart: {str(e)}")  # Print to backend terminal
        return jsonify({'error': 'Internal server error'}), 500

@cloudcart_bp.route('/<unique_id>', methods=['GET'])
def get_cloudcart(unique_id):
    """
    Retrieve a CloudCart by unique ID.
    """
    try:
        cart = CloudCart.query.filter_by(unique_id=unique_id).first()
        
        if not cart:
            return jsonify({'error': 'CloudCart not found'}), 404
        
        if cart.is_expired():
            # Could optionally delete it here
            return jsonify({'error': 'CloudCart expired'}), 404
        
        return jsonify({
            'cloudCartId': cart.unique_id,
            'products': cart.products,
            'createdAt': cart.created_at.isoformat(),
            'expiresAt': cart.expires_at.isoformat()
        }), 200
        
    except Exception as e:
        print(f"Error retrieving CloudCart: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@cloudcart_bp.route('/<unique_id>', methods=['DELETE'])
def delete_cloudcart(unique_id):
    """
    Delete a CloudCart by unique ID.
    """
    try:
        cart = CloudCart.query.filter_by(unique_id=unique_id).first()
        
        if not cart:
            return jsonify({'error': 'CloudCart not found'}), 404
        
        db.session.delete(cart)
        db.session.commit()
        
        return jsonify({'status': 'success', 'message': 'CloudCart deleted'}), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Error deleting CloudCart: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500
```

### 3. Register Blueprint

In `backend/app.py`, add:

```python
from api.cloudcart import cloudcart_bp

# ... other blueprint registrations ...

app.register_blueprint(cloudcart_bp, url_prefix='/api/CloudCart')
```

### 4. Database Migration

If using Alembic, create a migration for the new CloudCart table:

```bash
flask db migrate -m "Add CloudCart model"
flask db upgrade
```

Or simply ensure the table is created:

```bash
python init_db.py
```

### 5. Cleanup Task (Optional)

Add a periodic task to clean up expired CloudCarts:

**File: `backend/services/cleanup.py`**

```python
from models import db, CloudCart
from datetime import datetime

def cleanup_expired_cloudcarts():
    """Remove CloudCarts that have expired."""
    try:
        expired_carts = CloudCart.query.filter(
            CloudCart.expires_at < datetime.utcnow()
        ).all()
        
        count = len(expired_carts)
        for cart in expired_carts:
            db.session.delete(cart)
        
        db.session.commit()
        print(f"Cleaned up {count} expired CloudCarts")
        
    except Exception as e:
        print(f"Error cleaning up CloudCarts: {str(e)}")
        db.session.rollback()
```

## Frontend Integration (FRKassa App)

The FRKassa app is ready for integration. You need to implement the API call in `lib/screens/cart_overview_screen.dart`:

Replace the TODO section in `_submitCart()` with:

```dart
Future<void> _submitCartToBackend(String cloudCartId, List<ScannedProduct> products) async {
  final client = http.Client();
  
  try {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/CloudCart/$cloudCartId');
    
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'products': products.map((p) => {
          'name': p.name,
          'bestBeforeDate': p.bestBeforeDate.toString().split(' ')[0],
          'additionalInfo': p.additionalInfo,
        }).toList(),
      }),
    ).timeout(ApiConfig.apiTimeout);
    
    if (response.statusCode == 200) {
      // Success
      return;
    } else if (response.statusCode == 404) {
      throw Exception('CloudCart ID not found or expired');
    } else {
      throw Exception('Failed to submit cart: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
```

## QR Code Generation (FRKassa Cashier Interface)

When creating a QR code in FRKassa, generate it as:

```
{productName}|{YYYY-MM-DD}|{optionalInfo}
```

Example for encoding the CloudCart URL:
```
https://yourdomain.com/api/CloudCart/unique-cart-id
```

This URL should be the destination when employees scan the cart identification QR code.

## Testing the Integration

### 1. Test CloudCart Creation

```bash
curl -X POST http://localhost:5000/api/CloudCart/test-cart-1 \
  -H "Content-Type: application/json" \
  -d '{
    "products": [
      {
        "name": "Milk",
        "bestBeforeDate": "2025-12-15",
        "additionalInfo": "Full Fat 1L"
      },
      {
        "name": "Bread",
        "bestBeforeDate": "2025-12-10",
        "additionalInfo": "Whole Wheat"
      }
    ]
  }'
```

### 2. Test CloudCart Retrieval

```bash
curl http://localhost:5000/api/CloudCart/test-cart-1
```

### 3. Test CloudCart Deletion

```bash
curl -X DELETE http://localhost:5000/api/CloudCart/test-cart-1
```

## Error Handling

The FRKassa app handles these backend responses:

| Status Code | Action |
|-------------|--------|
| 200 | Show success message, clear cart |
| 400 | Show error: "Invalid CloudCart ID" |
| 404 | Show error: "CloudCart not found or expired" |
| 500 | Show error: "Server error" |

Backend errors (500) are logged to the backend terminal without showing to the user.

## Production Deployment

### Environment Configuration

1. Set the backend URL when building:
   ```bash
   flutter build apk --release --dart-define=API_URL=https://yourdomain.com
   ```

2. Ensure CORS is properly configured in your Flask backend:
   ```python
   CORS(app, resources={
       r"/api/*": {
           "origins": ["*"],
           "methods": ["GET", "POST", "PUT", "DELETE"],
           "allow_headers": ["Content-Type"]
       }
   })
   ```

### Database Backup

Before production, ensure you have:
- Database backups
- Cleanup tasks scheduled
- Error monitoring enabled

## Next Steps

1. Implement CloudCart model in backend
2. Add API endpoints for CloudCart operations
3. Set up 24-hour expiration cleanup
4. Test with FRKassa app
5. Deploy to production with proper CORS and SSL
6. Monitor CloudCart creation/deletion logs

## Support

For issues or questions, refer to the main README.md files in both FRKassa and backend directories.
