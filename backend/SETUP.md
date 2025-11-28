# FreshReminder Backend Setup Guide

## Overview
The FreshReminder backend is a Flask application with SQLAlchemy ORM that handles user authentication, product management, and QR code imports.

## Database Setup

### 1. SQLite (Development - Default)
SQLite is the default database for development and requires no additional setup.

```bash
# The database will be automatically created at:
# freshreminder.db
```

### 2. PostgreSQL (Production Recommended)
For production, use PostgreSQL for better scalability:

```bash
# Install PostgreSQL
# macOS:
brew install postgresql@15

# Ubuntu/Debian:
sudo apt-get install postgresql postgresql-contrib

# Start PostgreSQL service
# macOS:
brew services start postgresql@15

# Ubuntu/Debian:
sudo systemctl start postgresql
```

## Installation & Configuration

### Step 1: Install Dependencies

```bash
# Navigate to backend directory
cd /home/md20/Dokumente/FreshReminder/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate

# Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Environment Variables (.env file)

Create a `.env` file in the backend directory:

```bash
# .env
FLASK_ENV=development
JWT_SECRET_KEY=your-super-secret-key-change-this-in-production
DATABASE_URL=sqlite:///freshreminder.db

# For PostgreSQL:
# DATABASE_URL=postgresql://username:password@localhost/freshreminder
```

### Step 3: Database Migration (if needed)

```bash
# Flask will automatically create tables on first run
# Models are defined in models.py
```

### Step 4: Run the Server

```bash
# From backend directory with venv activated
python app.py

# Server will run on:
# http://localhost:5000
# API base: http://localhost:5000/api
```

## Database Models

### User Model
```
Fields:
- id (Integer, Primary Key)
- email (String, Unique)
- password_hash (String)
- push_token (String, Optional)
- notification_time (Integer, Default: 18)
- created_at (DateTime)
```

### Product Model
```
Fields:
- id (Integer, Primary Key)
- user_id (Foreign Key -> User)
- trip_id (Foreign Key -> ShoppingTrip, Optional)
- name (String)
- category (String)
- expiration_date (Date)
- added_at (DateTime)
- removed_at (DateTime, Optional)
- removed_by (String, Optional)
```

### ShoppingTrip Model
```
Fields:
- id (Integer, Primary Key)
- user_id (Foreign Key -> User, Optional)
- token (String, Unique)
- timestamp (DateTime)
- imported (Boolean)
- store_name (String)
```

## API Endpoints

### Authentication
- `POST /api/users/register` - Register new user
- `POST /api/users/login` - Login user
- `GET /api/users/profile` - Get user profile (JWT required)
- `POST /api/users/push-token` - Update push token (JWT required)

### Products
- `GET /api/products/` - List user's products (JWT required)
- `POST /api/products/` - Add new product (JWT required)
- `DELETE /api/products/{id}` - Delete product (JWT required)

### QR Import
- `GET /api/import/{token}` - Import products from QR code (JWT required)
- `POST /api/import/generate` - Generate QR code (for supermarkets)

## Example API Requests

### Register
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

### Login
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

### Add Product (with token)
```bash
curl -X POST http://localhost:5000/api/products/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Milk",
    "category": "Dairy",
    "expiration_date": "2025-12-31"
  }'
```

## Troubleshooting

### Port 5000 Already in Use
```bash
# Find and kill process on port 5000
lsof -ti:5000 | xargs kill -9

# Or use a different port:
# In app.py, change: app.run(port=5001)
```

### Database Locked (SQLite)
```bash
# Remove the database and let Flask recreate it
rm freshreminder.db

# Run the server again - fresh database will be created
```

### JWT Token Expired
- Tokens expire after 30 days by default
- User needs to login again to get a new token
- Configure expiration in config.py: `JWT_ACCESS_TOKEN_EXPIRES`

## Production Deployment

### Recommended Setup
1. Use PostgreSQL database
2. Use environment variables for secrets
3. Deploy with Gunicorn:
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```
4. Use Nginx as reverse proxy
5. Enable HTTPS/SSL certificate

### Environment Variables for Production
```bash
FLASK_ENV=production
JWT_SECRET_KEY=very-secure-random-key-here
DATABASE_URL=postgresql://user:pass@db-server/freshreminder
```

## Development Notes

- API responses are JSON formatted
- All protected endpoints require `Authorization: Bearer {token}` header
- Passwords are hashed using Werkzeug security functions
- CORS is enabled for development (restrict in production)
- Hot reload is enabled for development
