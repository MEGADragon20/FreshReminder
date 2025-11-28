# FreshReminder - Complete Setup Guide

## 📱 Project Overview

FreshReminder is a mobile/desktop app that helps you track food expiration dates. It consists of:

- **Frontend**: Flutter app (Android, iOS, Web, Linux, Windows, macOS)
- **Backend**: Flask API with SQLite/PostgreSQL database
- **Authentication**: JWT-based token authentication

---

## 🚀 Quick Start

### 1. Backend Setup (Flask API)

```bash
# Navigate to backend directory
cd path/to/repo/FreshReminder/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# or on Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Initialize database (creates SQLite database and tables)
python init_db.py

# Start the server
python app.py
```

The API will be available at: `http://localhost:5000/api`

### 2. Frontend Setup (Flutter App)

```bash
# Navigate to frontend directory
cd path/to/repo/FreshReminder/freshreminder

# Get dependencies
flutter pub get

# Run on Linux (for development)
flutter run -d linux

# Run on other devices/emulators
flutter run -d <device_id>
```

---

## 📊 Database Architecture

### Database Models

The application uses three main database models:

#### **User Model**
Stores user account information

```
Columns:
├─ id (Integer, PK)
├─ email (String, Unique)
├─ password_hash (String)
├─ push_token (String, Optional)
├─ notification_time (Integer, Default: 18)
└─ created_at (DateTime)
```

#### **Product Model**
Stores product information for each user

```
Columns:
├─ id (Integer, PK)
├─ user_id (FK → User)
├─ trip_id (FK → ShoppingTrip, Optional)
├─ name (String)
├─ category (String)
├─ expiration_date (Date)
├─ added_at (DateTime)
├─ removed_at (DateTime, Optional)
└─ removed_by (String, Optional)
```

#### **ShoppingTrip Model**
Stores information about QR-code scanned shopping trips

```
Columns:
├─ id (Integer, PK)
├─ user_id (FK → User, Optional)
├─ token (String, Unique)
├─ timestamp (DateTime)
├─ imported (Boolean)
└─ store_name (String)
```

### Database Setup Options

#### Option 1: SQLite (Default - Development)
```bash
# Already configured in config.py
# Database file: freshreminder.db (24KB)
# No additional setup needed
```

#### Option 2: PostgreSQL (Recommended - Production)

**Install PostgreSQL:**
```bash
# macOS
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Create database and user:**
```bash
sudo -u postgres psql

CREATE USER freshreminder WITH PASSWORD 'your_secure_password';
CREATE DATABASE freshreminder OWNER freshreminder;
GRANT ALL PRIVILEGES ON DATABASE freshreminder TO freshreminder;
\q
```

**Update .env:**
```bash
DATABASE_URL=postgresql://freshreminder:your_secure_password@localhost:5432/freshreminder
FLASK_ENV=production
```

---

## 🔐 Authentication Flow

### 1. User Registration
```bash
POST /api/users/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password_123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user_id": 1
}
```

### 2. User Login
```bash
POST /api/users/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password_123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user_id": 1
}
```

### 3. Using the Token
All subsequent requests must include the token:
```bash
Authorization: Bearer <your_token_here>
```

Token Lifespan: 30 days (configurable in `config.py`)

---

## 📡 API Endpoints

### Authentication Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---|
| POST | `/api/users/register` | Register new user | No |
| POST | `/api/users/login` | Login user | No |
| GET | `/api/users/profile` | Get user profile | Yes |
| POST | `/api/users/push-token` | Update push notification token | Yes |

### Product Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---|
| GET | `/api/products/` | List all user products | Yes |
| POST | `/api/products/` | Add new product | Yes |
| DELETE | `/api/products/{id}` | Delete product | Yes |

### QR Import Endpoints
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---|
| GET | `/api/import/{token}` | Import products from QR code | Yes |
| POST | `/api/import/generate` | Generate QR token (for supermarkets) | No |

---

## 🧪 Testing the API

### Test Registration
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the returned token and use it for authenticated requests:
```bash
export TOKEN="your_token_here"

# Get user profile
curl -X GET http://localhost:5000/api/users/profile \
  -H "Authorization: Bearer $TOKEN"

# Add a product
curl -X POST http://localhost:5000/api/products/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Milk",
    "category": "Dairy",
    "expiration_date": "2025-12-15"
  }'

# List products
curl -X GET http://localhost:5000/api/products/ \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🐛 Troubleshooting

### Port 5000 Already in Use
```bash
# Find process using port 5000
lsof -i :5000

# Kill the process
kill -9 <PID>

# Or use a different port in app.py:
# app.run(port=5001)
```

### Database Connection Error
```bash
# Reset SQLite database
rm freshreminder.db
python init_db.py

# For PostgreSQL, check connection
psql -U freshreminder -d freshreminder -h localhost
```

### JWT Token Expired
- Tokens expire after 30 days
- User must login again to get a new token
- For testing, you can change expiration in `config.py`:
  ```python
  JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
  ```

### CORS Issues in Flutter
- CORS is enabled for development
- For production, restrict to your domain in `app.py`:
  ```python
  CORS(app, origins=["https://yourdomain.com"])
  ```

---

## 📦 Environment Variables

Create `.env` file in backend directory:

```bash
# Flask Configuration
FLASK_ENV=development  # or 'production'

# Database
DATABASE_URL=sqlite:///./freshreminder.db

# Security
JWT_SECRET_KEY=change-this-to-a-secure-random-string-in-production

# Optional
# SQLALCHEMY_ECHO=True  # Logs all SQL queries
```

---

## 🔒 Security Notes

### Development vs Production

**Development (.env):**
```bash
FLASK_ENV=development
JWT_SECRET_KEY=dev-key-not-secure
DATABASE_URL=sqlite:///./freshreminder.db
```

**Production (.env):**
```bash
FLASK_ENV=production
JWT_SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')
DATABASE_URL=postgresql://user:pass@db-server/freshreminder
```

### Additional Production Steps
1. Use HTTPS/SSL certificates
2. Deploy with Gunicorn: `gunicorn -w 4 app:app`
3. Use Nginx as reverse proxy
4. Enable database backups
5. Use strong passwords for database users
6. Restrict CORS to your domain
7. Rate limit API endpoints
8. Keep dependencies updated

---

## 🎯 Flutter Client Configuration

In `lib/services/api_service.dart`, update the base URL:

```dart
// Development
static const String baseUrl = 'http://localhost:5000/api';

// Production
static const String baseUrl = 'https://api.freshreminder.de/api';
```

---

## 📚 Project Structure

```
FreshReminder/
├── backend/                    # Flask API
│   ├── venv/                   # Virtual environment
│   ├── api/
│   │   ├── users.py           # User endpoints
│   │   ├── products.py        # Product endpoints
│   │   └── imports.py         # QR import endpoints
│   ├── app.py                 # Flask application
│   ├── config.py              # Configuration
│   ├── models.py              # Database models
│   ├── requirements.txt        # Python dependencies
│   ├── .env                   # Environment variables
│   └── freshreminder.db       # SQLite database
│
└── freshreminder/             # Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   ├── services/
    │   ├── providers/
    │   └── screens/
    └── pubspec.yaml           # Flutter dependencies
```

---

## ✅ Verification Checklist

- [ ] Backend dependencies installed: `pip install -r requirements.txt`
- [ ] Database initialized: `python init_db.py` creates `freshreminder.db`
- [ ] Flask server running: `python app.py` shows "Running on http://127.0.0.1:5000"
- [ ] Health endpoint works: `curl http://localhost:5000/health`
- [ ] Flutter dependencies installed: `flutter pub get`
- [ ] Flutter app compiles: `flutter run -d linux`
- [ ] Can register user: POST to `/api/users/register`
- [ ] Can login user: POST to `/api/users/login` returns token
- [ ] Can add product with token: POST to `/api/products/`
- [ ] Token validation works: Requests without token get 401 error

---

## 📞 Support

For issues, check:
1. Flask logs for backend errors
2. Browser console for Flutter web errors
3. `SETUP.md` in backend directory
4. Database integrity with SQLite Browser

Generated: 28 November 2025
