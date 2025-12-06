# FreshReminder - Complete Food Tracking System

A comprehensive supermarket and customer-facing application system for tracking food expiration dates and managing shopping trips with QR code integration.

## 🎯 System Overview

FreshReminder is a three-part system:

1. **FRKassa** - Employee/Cashier application for scanning products and generating shopping trips
2. **FreshReminder** - Customer application for importing shopping trips and tracking product expiration
3. **Backend API** - Flask-based REST API managing data storage and QR code token system

### Architecture Diagram

```
PHASE 1: CASHIER CREATES SHOPPING TRIP
────────────────────────────────────────

  FRKassa (Employee App)          Backend (Flask API)         Database (SQLite)
  
  1. Scan QR codes
  2. Scan QR codes
  3. Review cart
  4. Click "Create"
       │
       ├──→ POST /api/import/generate
       │    {products, store_name}
       │                    │
       │                    ├─→ Generate token
       │                    ├─→ Create ShoppingTrip ────→ ✓ Saved
       │                    ├─→ Create Products ────────→ ✓ Saved
       │                    │
       ← ─ ─ Response ─ ─ ─ ← {token, qr_url, expires_at}
       │
  5. Display QR code
  6. Cashier prints/shows to customer


PHASE 2: CUSTOMER SCANS AND IMPORTS
────────────────────────────────────

  FreshReminder (Customer App)     Backend (Flask API)         Database (SQLite)
  
  1. See QR code from cashier
  2. Tap "Scan" button
  3. Point camera at QR
       │
       ├─→ Scans QR code
       ├─→ Extracts token
       ├─→ GET /api/import/{token}
       │   (with JWT auth)
       │                    │
       │                    ├─→ Validate token
       │                    ├─→ Check: Not expired?
       │                    ├─→ Check: Not imported?
       │                    ├─→ Mark as imported ───────→ ✓ Updated
       │                    ├─→ Set user_id ───────────→ ✓ Updated
       │                    │
       ← ─ ─ Response ─ ─ ─ ← {products list}
       │
  4. Products appear in app
  5. Customer tracks expiration dates
```

## 📋 Project Structure

```
FreshReminder/
├── README.md .......................... This file (system overview)
├── backend/ ........................... Flask API server
│   ├── Backend.md ..................... API documentation
│   ├── app.py ......................... Flask app entry point
│   ├── models.py ...................... Database models
│   ├── config.py ...................... Configuration
│   ├── requirements.txt ............... Python dependencies
│   ├── venv/ .......................... Python virtual environment
│   ├── api/
│   │   ├── imports.py ................. ShoppingTrip endpoints
│   │   ├── products.py ................ Product endpoints
│   │   └── users.py ................... User endpoints
│   └── freshreminder.db ............... SQLite database
├── FRKassa/ ........................... Employee app (Flutter)
│   ├── FRKassa.md ..................... Employee app documentation
│   ├── pubspec.yaml ................... Flutter dependencies
│   ├── lib/
│   │   ├── main.dart .................. App entry point
│   │   ├── models/
│   │   │   └── scanned_product.dart ... Product model
│   │   ├── providers/
│   │   │   └── cloud_cart_provider.dart  Cart state management
│   │   ├── screens/
│   │   │   ├── scanner_screen.dart ... QR scanner interface
│   │   │   └── cart_overview_screen.dart  Cart & submission
│   │   └── config/
│   │       └── api_config.dart ........ Backend URL config
│   └── build/ ......................... Compiled binaries
└── freshreminder/ ..................... Customer app (Flutter)
    ├── FreshReminder.md ............... Customer app documentation
    ├── pubspec.yaml ................... Flutter dependencies
    ├── lib/
    │   ├── main.dart .................. App entry point
    │   ├── screens/ ................... UI screens
    │   └── services/ .................. API & data services
    └── build/ ......................... Compiled binaries
```

## 🚀 Quick Start

### Prerequisites

- **Flutter 3.38.3+** (https://flutter.dev/docs/get-started/install)
- **Python 3.10+** (https://www.python.org/downloads/)
- **Git**

### 1. Start the Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

Backend will run at `http://localhost:5000`

### 2. Run FRKassa (Employee App)

```bash
cd FRKassa
flutter pub get
flutter run -d linux    # or: android, ios, web, windows, macos
```

### 3. Run FreshReminder (Customer App)

```bash
cd freshreminder
flutter pub get
flutter run -d linux    # or: android, ios, web, windows, macos
```

## 📚 Documentation

Each component has detailed documentation:

- **[Backend.md](backend/Backend.md)** - API endpoints, database schema, configuration
- **[FRKassa.md](FRKassa/FRKassa.md)** - Employee app features, QR format, cart submission
- **[FreshReminder.md](freshreminder/FreshReminder.md)** - Customer app features, product tracking

## 🔄 System Flow

### Complete User Journey

1. **Cashier (FRKassa)**
   - Opens FRKassa employee app
   - Scans product QR codes (format: `ProductName|YYYY-MM-DD|Category`)
   - Reviews products in cart
   - Clicks "Warenkorb erstellen" (Create Cart)
   - Receives unique token and QR code

2. **Customer (FreshReminder)**
   - Opens FreshReminder app
   - Scans QR code shown by cashier
   - App imports products into their list
   - Products appear with expiration date tracking
   - Can mark items as consumed or removed

3. **Backend (Flask API)**
   - Receives product submission from FRKassa
   - Generates secure 22-character token
   - Stores ShoppingTrip and Products in database
   - Validates customer's token when importing
   - Updates database with customer associations

## 💾 Database Schema

### ShoppingTrip Table
```
┌──────────────┬──────────┬─────────────────────────────┐
│ Field        │ Type     │ Purpose                     │
├──────────────┼──────────┼─────────────────────────────┤
│ id           │ Integer  │ Primary key                 │
│ token        │ String   │ Unique QR code token        │
│ store_name   │ String   │ Which store created it      │
│ timestamp    │ DateTime │ When created (auto)         │
│ imported     │ Boolean  │ Whether customer imported   │
│ user_id      │ Integer  │ Which customer imported     │
└──────────────┴──────────┴─────────────────────────────┘
```

### Product Table
```
┌──────────────────┬──────────┬─────────────────────────────┐
│ Field            │ Type     │ Purpose                     │
├──────────────────┼──────────┼─────────────────────────────┤
│ id               │ Integer  │ Primary key                 │
│ trip_id          │ Integer  │ Links to ShoppingTrip       │
│ name             │ String   │ Product name                │
│ category         │ String   │ Product category            │
│ expiration_date  │ Date     │ When product expires        │
│ added_at         │ DateTime │ When added (auto)           │
│ user_id          │ Integer  │ Which customer owns this    │
│ removed_at       │ DateTime │ When marked as consumed     │
│ removed_by       │ String   │ 'app', 'store', or 'admin'  │
└──────────────────┴──────────┴─────────────────────────────┘
```

### User Table
```
┌──────────────────┬──────────┬─────────────────────────────┐
│ Field            │ Type     │ Purpose                     │
├──────────────────┼──────────┼─────────────────────────────┤
│ id               │ Integer  │ Primary key                 │
│ email            │ String   │ Login email                 │
│ password_hash    │ String   │ Bcrypt hashed password      │
│ push_token       │ String   │ Notification token          │
│ notification_time│ Integer  │ Hour to notify (0-23)       │
│ created_at       │ DateTime │ Account creation date       │
└──────────────────┴──────────┴─────────────────────────────┘
```

## 🔒 Security Features

### Token System
- **Generation**: Cryptographically secure (22-character URL-safe)
- **Expiration**: 24-hour validity window
- **Uniqueness**: Unique constraint in database
- **One-time use**: Marked as imported after customer scans

### API Security
- JWT authentication for customer endpoints
- Password hashing for user accounts
- CORS enabled for cross-origin requests
- Input validation on all endpoints

### Data Protection
- No sensitive data in QR codes (only token)
- User association only after authentication
- Audit trail of removed items (removed_by field)
- Database backups recommended for production

## 📊 API Endpoints

### Public Endpoints (No Authentication Required)
```
POST /api/import/generate
  Purpose: Create shopping trip (cashier endpoint)
  Body: {products: [...], store_name: string}
  Returns: {token, qr_url, expires_at}

GET /health
  Purpose: Check backend status
  Returns: {status: "ok"}
```

### Protected Endpoints (JWT Required)
```
GET /api/import/{token}
  Purpose: Import shopping trip (customer endpoint)
  Auth: Bearer JWT token
  Returns: {trip_id, store, products: [...]}

GET /api/products
  Purpose: Get user's products
  Auth: Bearer JWT token
  Returns: {products: [...]}

POST /api/users/register
  Purpose: Create customer account
  Body: {email, password}
  Returns: {user_id, token}

POST /api/users/login
  Purpose: Login to account
  Body: {email, password}
  Returns: {token}
```

See [Backend.md](backend/Backend.md) for complete API documentation.

## 🛠 Configuration

### Backend (.env)
```bash
FLASK_ENV=development
DATABASE_URL=sqlite:///freshreminder.db
JWT_SECRET_KEY=your-secret-key-change-in-production
API_URL=http://localhost:5000
```

### FRKassa & FreshReminder
- Configured automatically via `api_config.dart`
- Default: `http://localhost:5000`
- For production, set via `--dart-define` flag:
  ```bash
  flutter run --dart-define=API_URL=https://api.yourdomain.com
  ```

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Supported | APK/AAB builds available |
| **iOS** | ✅ Supported | IPA builds available |
| **Web** | ✅ Supported | Progressive web app |
| **Linux** | ✅ Supported | Desktop application |
| **Windows** | ✅ Supported | Desktop application |
| **macOS** | ✅ Supported | Desktop application |

## 🧪 Testing

### Test the Complete Flow

1. **Start Backend**
   ```bash
   cd backend
   . venv/bin/activate
   python3 app.py
   ```

2. **Test with curl**
   ```bash
   curl -X POST http://localhost:5000/api/import/generate \
     -H "Content-Type: application/json" \
     -d '{
       "products": [{"name": "Milk", "category": "Dairy", "expiration_date": "2025-12-15"}],
       "store_name": "Test Store"
     }'
   ```

3. **Verify Database**
   ```bash
   cd backend
   python3 << 'EOF'
   from app import app, db
   from models import ShoppingTrip, Product
   with app.app_context():
       trips = db.session.query(ShoppingTrip).all()
       print(f"ShoppingTrips: {len(trips)}")
       for trip in trips:
           products = db.session.query(Product).filter_by(trip_id=trip.id).all()
           print(f"  - Token: {trip.token}, Products: {len(products)}")
   EOF
   ```

## 🚢 Deployment

### Production Checklist

- [ ] Change `JWT_SECRET_KEY` to random value
- [ ] Set `FLASK_ENV=production`
- [ ] Use PostgreSQL instead of SQLite
- [ ] Deploy with Gunicorn/uWSGI (not Flask development server)
- [ ] Set up HTTPS/SSL certificates
- [ ] Configure proper API_URL for apps
- [ ] Set up database backups
- [ ] Configure CORS for production domain
- [ ] Enable rate limiting
- [ ] Set up monitoring and logging

See [Backend.md](backend/Backend.md) for deployment details.

## 📞 Troubleshooting

### Common Issues

**Backend won't start:**
- Ensure Python 3.10+ installed
- Check `freshreminder.db` file exists and is writable
- Verify port 5000 is available
- Check virtual environment is activated

**FRKassa gets 404 error:**
- Verify backend is running on port 5000
- Check API path is `/api/import/generate`
- Ensure `api_config.dart` has correct base URL

**Linux build fails:**
- Run `flutter clean` before building
- Check CMakeLists.txt is not corrupted
- Verify GTK development packages installed

See specific app documentation for more troubleshooting.

## 📝 License

All components are part of the FreshReminder project.

## 👥 Contributing

For contributions, please:
1. Test on all supported platforms
2. Update relevant documentation
3. Ensure database migrations work
4. Follow existing code style

## 🔗 Documentation Links

- [Backend Documentation](backend/Backend.md)
- [FRKassa Employee App](FRKassa/FRKassa.md)
- [FreshReminder Customer App](freshreminder/FreshReminder.md)
