# 🍃 FreshReminder

A modern Flutter app with Flask backend to help users manage food expiration dates and reduce food waste.

**Status:** ✅ MVP Complete - Core features implemented and tested

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Running the App](#running-the-app)
6. [Testing](#testing)
7. [API Documentation](#api-documentation)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Python 3.8+
- Flutter 3.10+
- Linux/Android/iOS/macOS device or emulator

### Backend Setup
```bash
cd ../backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

**Expected output:**
```
Running on http://127.0.0.1:5000
```

### Frontend Setup
```bash
flutter pub get
flutter run -d linux    # or 'flutter run' for emulator
```

**Test credentials:**
```
Email: test@example.com
Password: 123456
```

---

## ✨ Features

### ✅ Implemented
- **User Authentication**
  - Email/password registration
  - JWT-based login with 30-day tokens
  - Secure password hashing
  - Session persistence

- **Product Management**
  - Add products with name, category, expiration date
  - Auto-sorted by expiration (soonest first)
  - Color-coded urgency (green → yellow → red)
  - Delete products (long-press)
  - Persistent storage (survives restarts)
  - Per-user product isolation

- **Database**
  - SQLite for development
  - PostgreSQL support for production
  - User products stored in database
  - Automatic timestamp tracking

- **UI/UX**
  - Material Design 3
  - Custom earthy color scheme ( #181F1C, #274029, #315C2B, #60712F, #9EA93F)
  - Responsive layout
  - Dark mode support
  - Tab-based navigation (Products, Scanner, Profile)

- **Cross-Platform**
  - Linux desktop ✅
  - Android phone ✅
  - iOS support
  - Web (Chrome)
  - macOS/Windows

### 🚧 Planned
- QR code scanning for receipts
- Push notifications
- Product image capture
- Email reminders
- Cloud backup/sync

---

## 🏗️ Architecture

### Technology Stack
| Component | Technology | Version |
|-----------|-----------|---------|
| **Frontend** | Flutter | 3.10+ |
| **Backend** | Flask | 2.3.3 |
| **Database** | SQLite/PostgreSQL | Latest |
| **Auth** | JWT (Flask-JWT-Extended) | 4.5.2 |
| **State Mgmt** | Provider | 6.1.1 |
| **HTTP** | http + shared_preferences | Latest |

### Backend Structure
```
backend/
├── app.py                   # Main Flask app
├── config.py               # Database config
├── models.py               # SQLAlchemy models
├── api/
│   ├── users.py           # Auth endpoints
│   ├── products.py        # Product CRUD
│   └── imports.py         # QR import
├── services/
│   ├── expiration.py      # Expiration logic
│   └── notification.py    # Notifications
├── requirements.txt        # Python dependencies
├── init_db.py             # Database init script
└── freshreminder.db       # SQLite database
```

### Frontend Structure
```
freshreminder/
├── lib/
│   ├── main.dart              # App root & home screen
│   ├── models/
│   │   └── product.dart       # Product data model
│   ├── providers/
│   │   ├── auth_provider.dart       # Auth state
│   │   └── product_provider.dart    # Product state
│   ├── services/
│   │   └── api_service.dart   # HTTP client
│   └── screens/
│       ├── auth_wrapper.dart   # Route guard
│       ├── login_screen.dart   # Login UI
│       └── register_screen.dart # Registration UI
├── pubspec.yaml           # Flutter dependencies
└── README.md             # This file
```

---

## 📦 Installation

### Backend

**1. Create virtual environment:**
```bash
cd ../backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
```

**2. Install dependencies:**
```bash
pip install -r requirements.txt
```

**3. Initialize database:**
```bash
python init_db.py
```

**4. Set environment variables:**
```bash
cp .env.example .env
# Edit .env with your settings
```

**Configuration (.env):**
```
FLASK_ENV=development
JWT_SECRET_KEY=your-secret-key-change-this
DATABASE_URL=sqlite:////absolute/path/to/freshreminder.db
```

### Frontend

**1. Get dependencies:**
```bash
flutter pub get
```

**2. Configure API URL:**
Edit `lib/services/api_service.dart`:
```dart
// For Linux/local development:
static const String baseUrl = 'http://localhost:5000/api';

// For Android/phone (replace with your Linux IP):
static const String baseUrl = 'http://192.168.1.100:5000/api';
```

---

## ▶️ Running the App

### Start Backend (Terminal 1)
```bash
cd ../backend
source venv/bin/activate
python app.py
```

**Check health:**
```bash
curl http://localhost:5000/health
# Response: {"status": "ok"}
```

### Start Frontend (Terminal 2)

**Linux desktop:**
```bash
flutter run -d linux
```

**Android phone:**
```bash
flutter run
# Select device when prompted
```

**iOS:**
```bash
flutter run -d ios
```

---

## 🧪 Testing

### 1. Automated Backend Tests

**Run all API tests:**
```bash
cd ../backend
bash test_api.sh
```

**Tests cover:**
- Health check
- User registration
- User login
- Profile retrieval
- Error cases (wrong password, duplicates)
- Product CRUD
- Authorization checks

### 2. Manual API Testing

**Register user:**
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
export TOKEN="eyJhbGci..."  # Save token
```

**Add product:**
```bash
curl -X POST http://localhost:5000/api/products/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Milk",
    "category": "Dairy",
    "expiration_date": "2025-12-05"
  }'
```

**Get products:**
```bash
curl -X GET http://localhost:5000/api/products/ \
  -H "Authorization: Bearer $TOKEN"
```

**Delete product:**
```bash
curl -X DELETE http://localhost:5000/api/products/1 \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Frontend UI Testing

**Registration:**
1. Launch app → Click "Register" link
2. Enter email, password, confirm password
3. Submit → Should see Home screen with products list

**Login:**
1. Enter existing credentials
2. Submit → Products load from database automatically

**Add Product:**
1. Click **+** button
2. Enter name, category, expiration date
3. Click Add → Product saved to database
4. Verify: Product persists after app restart

**Delete Product:**
1. Long-press any product card
2. Confirm delete
3. Product removed and deletion persists

**Product Features:**
- Products auto-sort by expiration date
- Color-coded: Green (>3 days), Yellow (1-3 days), Red (expired)
- Each user only sees their products
- Products load automatically on login

### 4. Android Testing

**Enable USB Debugging:**
1. Settings → About phone → Build number (tap 7x)
2. Settings → Developer options → USB Debugging (ON)

**Connect and run:**
```bash
adb devices  # Should show your phone
flutter run  # Select your device
```

**Important:** Update API URL in `lib/services/api_service.dart` to use your Linux machine's IP address instead of localhost.

### 5. Database Verification

**Check database contents:**
```bash
cd ../backend
sqlite3 freshreminder.db

SELECT id, email FROM user;
SELECT id, user_id, name, category, expiration_date FROM product;
```

---

## 📡 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints

**POST /users/register**
- Register new user
- Body: `{email, password}`
- Returns: `{token, user_id}` (Status: 201)

**POST /users/login**
- Login existing user
- Body: `{email, password}`
- Returns: `{token, user_id}` (Status: 200)

**GET /users/profile**
- Get user profile (requires auth)
- Returns: `{email, notification_time, created_at}` (Status: 200)

### Product Endpoints

**GET /products/**
- Get all user products (requires auth)
- Returns: `[{id, name, category, expiration_date, added_at}]` (Status: 200)

**POST /products/**
- Add new product (requires auth)
- Body: `{name, category, expiration_date: "YYYY-MM-DD"}`
- Returns: `{id, message}` (Status: 201)

**DELETE /products/{id}**
- Delete product (requires auth)
- Returns: `{message}` (Status: 200)

### Error Responses

All errors return JSON with error message:
```json
{"error": "Error description"}
```

Status codes:
- **400** - Bad request (missing/invalid fields)
- **401** - Unauthorized (missing/invalid token)
- **404** - Not found (product doesn't exist)
- **422** - Validation error (invalid data format)
- **500** - Server error

---

## 🐛 Troubleshooting

### 422 Error When Adding Products
**Cause:** Date format mismatch
**Fix:** Ensure expiration_date is sent as `YYYY-MM-DD` (not full datetime)
```dart
// Correct:
'expiration_date': DateTime.now().toIso8601String().split('T')[0]

// Wrong:
'expiration_date': DateTime.now().toIso8601String()  // Has time component
```

### Backend Issues

**Port 5000 already in use:**
```bash
lsof -i :5000
kill -9 <PID>
```

**Can't connect from Flutter:**
```bash
# Check backend is running
curl http://localhost:5000/health

# On Android: use your Linux IP, not localhost
# Find your IP: hostname -I
```

**Products don't persist:**
- Check backend is running
- Verify database exists: `ls backend/freshreminder.db`
- Check logs for SQL errors

### Frontend Issues

**App won't compile:**
```bash
flutter clean
flutter pub get
flutter run -d linux
```

**Long-press delete not working:**
- Product must have been saved to backend (has ID)
- Products created locally won't have ID until saved
- Add product properly through the + button

**Products not loading on login:**
- Wait a moment for API call to complete
- Check network logs: `flutter logs`
- Verify backend is accessible

---

## 🌐 Deployment

### Backend (Flask)

**For production:**
```bash
# Use PostgreSQL instead of SQLite
export DATABASE_URL=postgresql://user:pass@localhost/freshreminder

# Set strong secret key
export JWT_SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')

# Disable debug
export FLASK_ENV=production

# Run with production server (gunicorn)
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Frontend (Flutter)

**Build for Android:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Build for iOS:**
```bash
flutter build ios --release
```

---

## 📚 Additional Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Flask Docs](https://flask.palletsprojects.com/)
- [SQLAlchemy ORM](https://docs.sqlalchemy.org/)
- [Material Design 3](https://m3.material.io/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Version:** 1.0.0-MVP | **Last Updated:** 29 November 2025

**Happy building! 🌱**
