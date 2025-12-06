# Backend API Documentation

Complete Flask-based REST API for FreshReminder system managing ShoppingTrips, Products, and user authentication.

## 🎯 Overview

The backend is a Flask application that:
- Handles QR code token generation for cashiers
- Manages product shopping trips
- Validates and imports customer purchases
- Authenticates users with JWT
- Persists data to SQLite database

## 🚀 Quick Start

### Installation

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Running the Server

```bash
python3 app.py
```

**Output:**
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

The server will be available at `http://localhost:5000`

## 📦 Dependencies

```
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-CORS==4.0.0
Flask-JWT-Extended==4.5.2
Werkzeug==2.3.7
python-dotenv==1.0.0
```

## 🗄️ Database Schema

### User Table
Stores customer accounts for FreshReminder app users.

```sql
CREATE TABLE user (
  id INTEGER PRIMARY KEY,
  email VARCHAR(120) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  push_token VARCHAR(255),
  notification_time INTEGER DEFAULT 18,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Fields:**
- `id`: Primary key
- `email`: Unique email for login
- `password_hash`: Bcrypt hashed password
- `push_token`: For push notifications
- `notification_time`: Hour of day (0-23) for notifications
- `created_at`: Account creation timestamp

### ShoppingTrip Table
Represents a shopping trip created by a cashier, containing a unique token.

```sql
CREATE TABLE shopping_trip (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  token VARCHAR(64) UNIQUE NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  imported BOOLEAN DEFAULT FALSE,
  store_name VARCHAR(100),
  FOREIGN KEY(user_id) REFERENCES user(id)
);
```

**Fields:**
- `id`: Primary key
- `user_id`: Customer who imported (NULL until imported)
- `token`: Unique 22-character token for QR code
- `timestamp`: When trip was created
- `imported`: Whether a customer has claimed it
- `store_name`: Store/cashier name that created it

### Product Table
Products included in a shopping trip.

```sql
CREATE TABLE product (
  id INTEGER PRIMARY KEY,
  trip_id INTEGER,
  user_id INTEGER,
  name VARCHAR(200) NOT NULL,
  category VARCHAR(100),
  expiration_date DATE NOT NULL,
  added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  removed_at DATETIME,
  removed_by VARCHAR(20),
  FOREIGN KEY(trip_id) REFERENCES shopping_trip(id),
  FOREIGN KEY(user_id) REFERENCES user(id)
);
```

**Fields:**
- `id`: Primary key
- `trip_id`: Links to the shopping trip
- `user_id`: Customer who owns this product
- `name`: Product name
- `category`: Product category (Dairy, Bakery, etc.)
- `expiration_date`: When product expires
- `added_at`: When added to trip
- `removed_at`: When marked as consumed
- `removed_by`: Who removed it ('app', 'store', 'admin')

## 📡 API Endpoints

### Health Check

#### GET /health
Check if backend is running.

**Authentication:** None

**Request:**
```bash
curl http://localhost:5000/health
```

**Response:** `200 OK`
```json
{
  "status": "ok"
}
```

---

### Shopping Trip Management

#### POST /api/import/generate
Create a new shopping trip with products (CASHIER ENDPOINT).

**Authentication:** None (public endpoint)

**Request:**
```bash
curl -X POST http://localhost:5000/api/import/generate \
  -H "Content-Type: application/json" \
  -d '{
    "products": [
      {
        "name": "Milk",
        "category": "Dairy",
        "expiration_date": "2025-12-15"
      },
      {
        "name": "Bread",
        "category": "Bakery",
        "expiration_date": "2025-12-07"
      }
    ],
    "store_name": "Supermarkt ABC"
  }'
```

**Request Body:**
```json
{
  "products": [
    {
      "name": "string (required)",
      "category": "string (optional, default: 'Sonstiges')",
      "expiration_date": "YYYY-MM-DD (required)"
    }
  ],
  "store_name": "string (optional, default: 'Unknown')"
}
```

**Response:** `200 OK`
```json
{
  "token": "p2CRdexRqeY64JyXYTz_vA",
  "qr_url": "https://api.freshreminder.de/import/p2CRdexRqeY64JyXYTz_vA",
  "expires_at": "2025-12-07T14:55:54.290944"
}
```

**Response Fields:**
- `token`: 22-character unique token for QR encoding
- `qr_url`: Complete URL for QR code (customer scans this)
- `expires_at`: ISO timestamp when token expires (24 hours from creation)

**Errors:**
- `400 Bad Request`: Invalid product data or missing required fields
- `500 Internal Server Error`: Database error

---

#### GET /api/import/{token}
Import a shopping trip (CUSTOMER ENDPOINT).

**Authentication:** Required (JWT Bearer token)

**Request:**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:5000/api/import/p2CRdexRqeY64JyXYTz_vA
```

**Response:** `200 OK`
```json
{
  "trip_id": 1,
  "store": "Supermarkt ABC",
  "timestamp": "2025-12-06T14:55:54.290944",
  "products": [
    {
      "id": 1,
      "name": "Milk",
      "category": "Dairy",
      "expiration_date": "2025-12-15"
    },
    {
      "id": 2,
      "name": "Bread",
      "category": "Bakery",
      "expiration_date": "2025-12-07"
    }
  ]
}
```

**Errors:**
- `401 Unauthorized`: Missing or invalid JWT token
- `404 Not Found`: Token doesn't exist
- `409 Conflict`: Token already imported
- `410 Gone`: Token expired (> 24 hours old)

---

### User Management

#### POST /api/users/register
Register a new customer account.

**Authentication:** None

**Request:**
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@example.com",
    "password": "secure_password_123"
  }'
```

**Request Body:**
```json
{
  "email": "string (required, must be valid email)",
  "password": "string (required, min 8 characters)"
}
```

**Response:** `201 Created`
```json
{
  "user_id": 42,
  "email": "customer@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Errors:**
- `400 Bad Request`: Invalid email or weak password
- `409 Conflict`: Email already registered

---

#### POST /api/users/login
Authenticate user and get JWT token.

**Authentication:** None

**Request:**
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@example.com",
    "password": "secure_password_123"
  }'
```

**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Response:** `200 OK`
```json
{
  "user_id": 42,
  "email": "customer@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Token Usage:**
```bash
curl -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..." \
  http://localhost:5000/api/products
```

**Errors:**
- `401 Unauthorized`: Invalid credentials
- `404 Not Found`: User not found

---

### Product Management

#### GET /api/products
Get all products for authenticated user.

**Authentication:** Required (JWT Bearer token)

**Request:**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:5000/api/products
```

**Response:** `200 OK`
```json
{
  "products": [
    {
      "id": 1,
      "trip_id": 1,
      "name": "Milk",
      "category": "Dairy",
      "expiration_date": "2025-12-15",
      "added_at": "2025-12-06T14:55:54",
      "removed_at": null,
      "removed_by": null
    }
  ]
}
```

**Errors:**
- `401 Unauthorized`: Missing or invalid JWT token

---

## 🔐 Authentication

### JWT (JSON Web Token)

The backend uses Flask-JWT-Extended for authentication.

#### How it Works

1. **User registers/logs in**
   - Client sends email + password
   - Backend validates and creates JWT token
   - Token returned to client

2. **Client makes authenticated request**
   - Client includes token in Authorization header
   - `Authorization: Bearer <token>`
   - Backend validates token

3. **Token structure**
   ```
   header.payload.signature
   ```
   - **header**: Token type and algorithm
   - **payload**: User ID and issued time
   - **signature**: Cryptographic signature

#### Token Configuration

In `config.py`:
```python
JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=30)
```

**For production:** Set `JWT_SECRET_KEY` to a secure random string:
```bash
export JWT_SECRET_KEY=$(openssl rand -hex 32)
```

---

## 🔄 Complete User Flow

### Phase 1: Cashier Creates Shopping Trip

```
FRKassa App                    Backend Server                    Database
    │                               │                               │
    ├─→ POST /api/import/generate   │                               │
    │   {products, store}           │                               │
    │                               │                               │
    │                        Generate token                          │
    │                        "p2CRdexRqeY64JyXYTz_vA"                │
    │                               │                               │
    │                        INSERT ShoppingTrip ──────────────→ ✓
    │                               │                               │
    │                        INSERT Products ───────────────────→ ✓
    │                               │                               │
    │    ← {token, qr_url} ◄────────│                               │
    │                               │                               │
    ├─→ Display QR code                                            
    │   "p2CRdexRqeY64JyXYTz_vA"
```

**Database State After:**
```
ShoppingTrip {
  id: 1,
  token: "p2CRdexRqeY64JyXYTz_vA",
  store_name: "Supermarkt ABC",
  imported: False,        ← Not yet claimed
  user_id: null,          ← No owner yet
  timestamp: "2025-12-06T14:55:54"
}

Products {
  id: 1, trip_id: 1, name: "Milk", category: "Dairy", 
    expiration_date: "2025-12-15", user_id: null
  id: 2, trip_id: 1, name: "Bread", category: "Bakery", 
    expiration_date: "2025-12-07", user_id: null
}
```

---

### Phase 2: Customer Imports Shopping Trip

```
FreshReminder App              Backend Server                    Database
    │                               │                               │
    ├─→ GET /api/import/{token}     │                               │
    │   with JWT auth               │                               │
    │                               │                               │
    │                        Validate token                         
    │                        Check: Not expired?
    │                        Check: Not imported?
    │                               │                               │
    │                        UPDATE ShoppingTrip ──────────────→ ✓
    │                        (imported=True, user_id=42)             │
    │                               │                               │
    │                        UPDATE Products ───────────────────→ ✓
    │                        (user_id=42 for all)
    │                               │                               │
    │    ← {trip_id, products} ◄────│                               │
    │                               │                               │
    ├─→ Display products                                            
    │   "Milk expires 2025-12-15"
```

**Database State After:**
```
ShoppingTrip {
  id: 1,
  token: "p2CRdexRqeY64JyXYTz_vA",
  store_name: "Supermarkt ABC",
  imported: True,         ← Claimed by customer
  user_id: 42,            ← Customer ID
  timestamp: "2025-12-06T14:55:54"
}

Products {
  id: 1, trip_id: 1, name: "Milk", category: "Dairy", 
    expiration_date: "2025-12-15", user_id: 42
  id: 2, trip_id: 1, name: "Bread", category: "Bakery", 
    expiration_date: "2025-12-07", user_id: 42
}
```

---

## 🛠 Configuration

### Environment Variables

Create a `.env` file in the `backend/` directory:

```bash
# Flask configuration
FLASK_ENV=development
DEBUG=True

# Database
DATABASE_URL=sqlite:///freshreminder.db

# JWT
JWT_SECRET_KEY=your-secret-key-change-in-production

# API
API_URL=http://localhost:5000
```

### Config Classes

In `config.py`:

```python
class Config:
    """Base configuration"""
    SQLALCHEMY_DATABASE_URI = f'sqlite:///{DB_PATH}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'default-key')
    DEBUG = False

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://user:password@localhost/freshreminder'
    )

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
```

---

## 🚢 Deployment

### Production Setup

#### 1. Use PostgreSQL Instead of SQLite

```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres createdb freshreminder
sudo -u postgres createuser freshreminder_user
```

#### 2. Set Environment Variables

```bash
export FLASK_ENV=production
export JWT_SECRET_KEY=$(openssl rand -hex 32)
export DATABASE_URL=postgresql://freshreminder_user:password@localhost/freshreminder
export API_URL=https://api.yourdomain.com
```

#### 3. Use Production WSGI Server

Instead of Flask development server, use Gunicorn:

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

#### 4. Set Up Reverse Proxy

With Nginx:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 5. SSL/HTTPS Setup

```bash
# Using Let's Encrypt with Certbot
sudo apt-get install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d api.yourdomain.com
```

#### 6. Database Backups

```bash
# Automated daily backup
0 2 * * * pg_dump freshreminder > /backups/freshreminder_$(date +\%Y-\%m-\%d).sql
```

---

## 🧪 Testing

### Test with curl

#### 1. Create Shopping Trip

```bash
curl -X POST http://localhost:5000/api/import/generate \
  -H "Content-Type: application/json" \
  -d '{
    "products": [
      {
        "name": "Milk",
        "category": "Dairy",
        "expiration_date": "2025-12-15"
      }
    ],
    "store_name": "Test Store"
  }'
```

**Response:**
```json
{
  "token": "AbCdEfGhIjKlMnOpQrStUv",
  "qr_url": "https://api.freshreminder.de/import/AbCdEfGhIjKlMnOpQrStUv",
  "expires_at": "2025-12-07T14:55:54.290944"
}
```

#### 2. Register User

```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test_password_123"
  }'
```

**Response:**
```json
{
  "user_id": 1,
  "email": "test@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

#### 3. Login

```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test_password_123"
  }'
```

#### 4. Import Shopping Trip

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:5000/api/import/AbCdEfGhIjKlMnOpQrStUv
```

---

## 🔍 Database Inspection

### View Data

```python
cd backend
python3 << 'EOF'
from app import app, db
from models import ShoppingTrip, Product, User

with app.app_context():
    # Count records
    print(f"Users: {db.session.query(User).count()}")
    print(f"ShoppingTrips: {db.session.query(ShoppingTrip).count()}")
    print(f"Products: {db.session.query(Product).count()}")
    
    # View trips
    for trip in db.session.query(ShoppingTrip).all():
        products = db.session.query(Product).filter_by(trip_id=trip.id).all()
        print(f"\nTrip {trip.token}:")
        print(f"  Store: {trip.store_name}")
        print(f"  Products: {len(products)}")
        for p in products:
            print(f"    - {p.name} expires {p.expiration_date}")
EOF
```

---

## 📊 Monitoring

### Enable Logging

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Log important events
logger.info(f"ShoppingTrip created: {token}")
logger.warning(f"Token expired: {token}")
logger.error(f"Database error: {error}")
```

### Performance Tips

- Index frequently queried fields (token, email)
- Use connection pooling for database
- Cache frequently accessed data
- Monitor response times
- Set up database query logging

---

## 🆘 Troubleshooting

### Backend won't start

**Error:** `ModuleNotFoundError: No module named 'flask'`
- **Solution:** Activate virtual environment and install dependencies
  ```bash
  source venv/bin/activate
  pip install -r requirements.txt
  ```

**Error:** `Address already in use`
- **Solution:** Port 5000 is taken, kill the process or use different port
  ```bash
  lsof -i :5000
  kill -9 <PID>
  # Or run on different port
  python3 app.py --port 5001
  ```

### Database errors

**Error:** `sqlite3.OperationalError: unable to open database file`
- **Solution:** Ensure directory is writable
  ```bash
  chmod 755 backend/
  touch backend/freshreminder.db
  chmod 666 backend/freshreminder.db
  ```

### JWT errors

**Error:** `422 Unprocessable Entity: Invalid token`
- **Solution:** Check token format and expiration
- Token must be: `Authorization: Bearer <token>`
- Token expires after 30 days

---

## 📝 API Summary Table

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/api/import/generate` | No | Create shopping trip |
| GET | `/api/import/{token}` | JWT | Import trip as customer |
| POST | `/api/users/register` | No | Create account |
| POST | `/api/users/login` | No | Get JWT token |
| GET | `/api/products` | JWT | Get user's products |
| GET | `/health` | No | Check server status |

---

## 🔗 Related Documentation

- [Main README](../README.md) - System overview
- [FRKassa Documentation](../FRKassa/FRKassa.md) - Employee app
- [FreshReminder Documentation](../freshreminder/FreshReminder.md) - Customer app
