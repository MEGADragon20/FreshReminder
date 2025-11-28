# FreshReminder - Complete Testing Guide

## 🎯 Testing Overview

This guide covers how to test all features of the FreshReminder application:
1. Backend API endpoints
2. Flutter app (UI & functionality)
3. End-to-end workflow

---

## 📋 Prerequisites

Before testing, ensure:
- ✅ Python 3.8+ installed
- ✅ Flutter 3.10+ installed
- ✅ Git installed
- ✅ Backend virtual environment created
- ✅ Dependencies installed (`pip install -r requirements.txt`)

---

## 🚀 Quick Setup (5 minutes)

### Terminal 1: Start Backend
```bash
cd /home/md20/Dokumente/FreshReminder/backend

# Activate virtual environment
source venv/bin/activate

# Start Flask server
python app.py
```

**Expected Output:**
```
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
```

### Terminal 2: Test Backend (see section below)

### Terminal 3: Start Flutter App
```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder

# Run on Linux desktop
flutter run -d linux

# Or on Android/iOS emulator
flutter run
```

---

## 🧪 Testing Backend API

### Option 1: Automated Testing Script (Recommended)

**Easiest way to test all endpoints:**

```bash
cd /home/md20/Dokumente/FreshReminder/backend
bash test_api.sh
```

This script will:
- ✅ Check if backend is running
- ✅ Register a new user
- ✅ Login with the registered user
- ✅ Get user profile
- ✅ Test login with wrong password (should fail)
- ✅ Add a product
- ✅ List products
- ✅ Test unauthorized access (should fail)
- ✅ Delete the product
- ✅ Update push token

**Sample Output:**
```
✓ Backend is running
✓ User registered successfully
✓ User logged in successfully
✓ Profile retrieved successfully
✓ Correctly rejected wrong password
✓ Product added successfully
✓ Products retrieved successfully
✓ Correctly rejected unauthorized request
✓ Product deleted successfully
✓ Push token updated successfully

All tests completed!
```

### Option 2: Manual Testing with curl

#### 1️⃣ Check if Backend is Running
```bash
curl http://localhost:5000/health
```

**Expected Response:**
```json
{"status": "ok"}
```

#### 2️⃣ Register a User
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "password123"
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": 1
}
```

**Save the token:**
```bash
export TOKEN="your_token_from_response"
```

#### 3️⃣ Login with Email & Password
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "password123"
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": 1
}
```

#### 4️⃣ Get User Profile (Requires Token)
```bash
curl -X GET http://localhost:5000/api/users/profile \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "email": "testuser@example.com",
  "notification_time": 18,
  "created_at": "2025-11-28T12:34:56.789Z"
}
```

#### 5️⃣ Add a Product (Requires Token)
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

**Expected Response:**
```json
{
  "id": 1,
  "message": "Produkt hinzugefügt"
}
```

#### 6️⃣ List All Products (Requires Token)
```bash
curl -X GET http://localhost:5000/api/products/ \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
[
  {
    "id": 1,
    "name": "Milk",
    "category": "Dairy",
    "expiration_date": "2025-12-05",
    "added_at": "2025-11-28T12:34:56.789Z"
  }
]
```

#### 7️⃣ Delete a Product (Requires Token)
```bash
curl -X DELETE http://localhost:5000/api/products/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "message": "Produkt entfernt"
}
```

#### 8️⃣ Test Error Cases

**Register with duplicate email (should fail):**
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "password123"
  }'
```

**Expected Response:**
```json
{
  "error": "Email bereits registriert"
}
```

**Login with wrong password (should fail):**
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "wrongpassword"
  }'
```

**Expected Response:**
```json
{
  "error": "Ungültige Anmeldedaten"
}
```

**Access protected endpoint without token (should fail):**
```bash
curl -X GET http://localhost:5000/api/products/
```

**Expected Response:**
```json
{
  "error": "Unauthorized"
}
```

---

## 📱 Testing Flutter App

### 1️⃣ Launch the App

```bash
cd /home/md20/Dokumente/FreshReminder/freshreminder
flutter run -d linux
```

The app will show the **Login Screen**.

### 2️⃣ Test Registration

1. Click **"Register"** link at the bottom
2. Fill in the form:
   - **Email:** `newuser@example.com`
   - **Password:** `MyPassword123`
   - **Confirm Password:** `MyPassword123`
3. Click **"Register"** button
4. ✅ Should be redirected to **Home Screen**

**What to check:**
- ✓ No errors appear
- ✓ Form validates password match
- ✓ Form requires 6+ character password
- ✓ Redirects to home on success
- ✓ User email shown in profile

### 3️⃣ Test Login

1. Go to **Profile** tab (bottom right)
2. Click **"Abmelden"** (Logout) button
3. Confirm logout
4. Should return to **Login Screen**
5. Fill in login form:
   - **Email:** `newuser@example.com`
   - **Password:** `MyPassword123`
6. Click **"Login"** button
7. ✅ Should see **Home Screen** with email displayed

**What to check:**
- ✓ Logout works and shows confirmation dialog
- ✓ Login with correct credentials works
- ✓ Returns to home screen
- ✓ Email is displayed in profile

### 4️⃣ Test Error Handling

**Test login with wrong password:**
1. Enter correct email but wrong password
2. Click Login
3. ✅ Should show error message
4. Error should say something like "Ungültige Anmeldedaten"

**Test registration with mismatched passwords:**
1. Click Register link
2. Enter passwords that don't match
3. Click Register
4. ✅ Should show "Passwords do not match" error

**Test registration with short password:**
1. Click Register link
2. Enter password less than 6 characters
3. Click Register
4. ✅ Should show "Password must be at least 6 characters" error

### 5️⃣ Test Navigation

1. **Home Tab (Produkte):**
   - Shows list of products
   - Shows color-coded expiration status
   - Has "Add Product" button (floating action)

2. **Scanner Tab:**
   - Shows QR code scanner UI (not functional yet)
   - Has buttons to start/stop scanner

3. **Profile Tab:**
   - Shows user email
   - Shows notification settings
   - Shows logout button

### 6️⃣ Test Multiple Accounts

1. Create **Account A:**
   - Email: `user_a@example.com`
   - Password: `password123`

2. Logout and create **Account B:**
   - Email: `user_b@example.com`
   - Password: `password456`

3. Logout and login back to **Account A**
   - ✅ Should show correct email in profile
   - ✅ Each account is independent

---

## 🔄 End-to-End Testing Flow

### Complete User Journey (15 minutes)

**Step 1: Backend Setup**
```bash
# Terminal 1
cd backend
source venv/bin/activate
python app.py
# Wait for "Running on http://localhost:5000"
```

**Step 2: Run Automated Tests**
```bash
# Terminal 2
cd backend
bash test_api.sh
# Should show all ✓ checks passed
```

**Step 3: Start Flutter App**
```bash
# Terminal 3
cd freshreminder
flutter run -d linux
```

**Step 4: Test Registration**
- Click "Register"
- Use email: `mytest@example.com`, password: `test1234`
- Click Register button
- ✅ Should see home screen

**Step 5: Test Profile**
- Click Profile tab
- Verify email is displayed
- Click "Abmelden" (Logout)
- Confirm logout

**Step 6: Test Login**
- Enter same email/password
- Click Login
- ✅ Should see home screen again

**Step 7: Test Error Handling**
- Try login with wrong password
- ✅ Should show error message
- Try registering with mismatched passwords
- ✅ Should show error message

---

## 📊 Database Verification

### Check Database Contents

```bash
# Open SQLite database
cd backend
sqlite3 freshreminder.db

# List tables
.tables

# Check users
SELECT id, email, created_at FROM user;

# Check products
SELECT id, user_id, name, category, expiration_date FROM product;

# Exit
.quit
```

**Sample Output:**
```
id | email                    | created_at
1  | testuser@example.com     | 2025-11-28 12:34:56
2  | newuser@example.com      | 2025-11-28 12:45:30

id | user_id | name  | category | expiration_date
1  | 1       | Milk  | Dairy    | 2025-12-05
```

---

## ✅ Testing Checklist

### Backend Tests
- [ ] Health endpoint returns `{"status": "ok"}`
- [ ] User registration succeeds with new email
- [ ] User registration fails with duplicate email
- [ ] Login succeeds with correct credentials
- [ ] Login fails with wrong password
- [ ] Profile endpoint requires authentication token
- [ ] Can add product with valid token
- [ ] Can list products with valid token
- [ ] Can delete product with valid token
- [ ] Cannot access endpoints without token
- [ ] Token format is valid JWT
- [ ] Database has correct user and product entries

### Frontend Tests
- [ ] App launches and shows login screen
- [ ] Can register new account
- [ ] Registration validates password match
- [ ] Registration validates password length (6+)
- [ ] Can login with registered account
- [ ] Can logout from profile screen
- [ ] Profile shows correct user email
- [ ] Error messages display for login failures
- [ ] Error messages display for registration failures
- [ ] Navigation between tabs works
- [ ] Home screen shows products (when API connected)
- [ ] Multiple accounts work independently

### Database Tests
- [ ] SQLite database is created
- [ ] User table has correct schema
- [ ] Product table has correct schema
- [ ] ShoppingTrip table exists
- [ ] Passwords are hashed (not plain text)
- [ ] User data persists across app restarts
- [ ] Product data persists across app restarts

---

## 🐛 Troubleshooting Test Issues

### Backend Won't Start
```bash
# Check Python version
python3 --version

# Check if port 5000 is free
lsof -i :5000

# Kill process if needed
kill -9 <PID>

# Reinstall dependencies
pip install -r requirements.txt

# Try again
python app.py
```

### Test Script Fails
```bash
# Make sure script is executable
chmod +x test_api.sh

# Make sure backend is running (check Terminal 1)
curl http://localhost:5000/health

# Run script with bash explicitly
bash test_api.sh
```

### Flutter App Won't Connect
- Check backend URL in `lib/services/api_service.dart` (should be `http://localhost:5000/api`)
- Make sure backend is running on port 5000
- Try `curl http://localhost:5000/health` from terminal

### Login/Register Not Working
- Check error message in app
- Verify backend is running
- Check that API URL is correct
- Review backend logs for errors

---

## 📝 Test Report Template

Use this template to document your testing:

```
Date: _______________
Tester: _______________

BACKEND TESTS
- Registration: PASS / FAIL
- Login: PASS / FAIL
- Profile: PASS / FAIL
- Add Product: PASS / FAIL
- List Products: PASS / FAIL
- Delete Product: PASS / FAIL
- Error Handling: PASS / FAIL

FRONTEND TESTS
- Launch App: PASS / FAIL
- Register: PASS / FAIL
- Login: PASS / FAIL
- Logout: PASS / FAIL
- Navigation: PASS / FAIL
- Error Messages: PASS / FAIL

DATABASE TESTS
- Database Created: PASS / FAIL
- User Data Stored: PASS / FAIL
- Product Data Stored: PASS / FAIL

NOTES:
_______________________________________________
_______________________________________________
```

---

## 🎓 Learning Resources

While testing, you can also explore:

1. **Backend Code:**
   - `backend/app.py` - Flask app structure
   - `backend/api/users.py` - Auth endpoints
   - `backend/api/products.py` - Product endpoints
   - `backend/models.py` - Database models

2. **Frontend Code:**
   - `freshreminder/lib/main.dart` - App structure
   - `freshreminder/lib/services/api_service.dart` - API client
   - `freshreminder/lib/providers/auth_provider.dart` - State management
   - `freshreminder/lib/screens/login_screen.dart` - UI example

3. **Database:**
   - `backend/freshreminder.db` - SQLite database file

---

## ✨ Advanced Testing

### Load Testing (Optional)
If you want to test how the app handles multiple requests:

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Run 100 requests
ab -n 100 -c 10 http://localhost:5000/health
```

### Database Backup Testing
```bash
# Backup database
cp backend/freshreminder.db backend/freshreminder.db.backup

# Delete original
rm backend/freshreminder.db

# Recreate
cd backend
python init_db.py

# Restore
cp backend/freshreminder.db.backup backend/freshreminder.db
```

---

## 🎉 Success Indicators

You know everything is working when:

✅ Automated test script completes with all checks passing
✅ Flutter app launches without errors
✅ Can register and login successfully
✅ Error messages appear for invalid inputs
✅ Database shows new users and products
✅ Can logout and login again
✅ Multiple accounts work independently

---

## 📞 Next Steps

After successful testing:

1. **Add More Features:**
   - Connect product list to API
   - Implement add/edit/delete products in UI
   - Add QR code scanning

2. **Improve UI:**
   - Add loading spinners
   - Improve error dialogs
   - Add success messages

3. **Deploy:**
   - Set up PostgreSQL for production
   - Deploy backend to cloud
   - Build mobile APK/IPA

---

**Happy Testing! 🚀**

Generated: 28 November 2025
