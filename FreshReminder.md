# FreshReminder Customer App Documentation

The customer-facing Flutter application for tracking product expiration dates and managing purchases.

## 🎯 Overview

FreshReminder is a mobile/web/desktop application that allows customers to:
- Scan QR codes from store cashiers to import their shopping receipt
- View all products they've purchased with expiration dates
- Track which products are expiring soon
- Mark products as consumed
- Manage their account and notification preferences

The app is the **customer side** of the FreshReminder ecosystem. Cashiers use FRKassa to create shopping trips, and customers use FreshReminder to import and manage them.

## 🚀 Quick Start

### Installation

#### Option 1: Build from Source

```bash
cd freshreminder
flutter pub get
flutter run
```

#### Option 2: Pre-built APK (Android)

```bash
flutter build apk --release
# APK saved to: build/app/outputs/flutter-app.apk
```

#### Option 3: Run on Specific Platform

```bash
# iOS
flutter run -d iphone

# Web
flutter run -d web

# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

### Configuration

Before running, set the backend API URL via dart-define:

```bash
flutter run -d linux \
  --dart-define=API_URL=http://localhost:5000
```

Or for production:

```bash
flutter run -d iphone \
  --dart-define=API_URL=https://api.freshreminder.de
```

## 📱 Features

### 1. **Authentication**

#### Register New Account
- Email-based account creation
- Password validation (minimum 8 characters)
- Automatic JWT token generation
- One-time setup

**Flow:**
```
User → Email/Password input → Backend registration 
→ JWT token received → Auto-login → Home screen
```

#### Login
- Email + password authentication
- JWT token stored locally
- Persistent login across sessions
- Option to logout and switch accounts

### 2. **QR Code Scanning**

#### Scan Store Receipt
- Camera-based QR code scanning
- Automatic URL parsing
- Extracts token: `{token}`
- Works on all supported platforms (Android, iOS with native scanner; Web/Linux/macOS with manual input fallback)

**Supported Platforms:**
- ✅ Android: Native camera integration
- ✅ iOS: Native camera integration
- ✅ Web: Browser camera API
- ✅ Linux: Manual token input (camera not available)
- ✅ macOS: Native camera integration
- ✅ Windows: Native camera integration

#### Token Format
QR codes encode a URL with a token:
```
https://api.freshreminder.de/import/p2CRdexRqeY64JyXYTz_vA
```

The app extracts: `p2CRdexRqeY64JyXYTz_vA`

### 3. **Shopping Trip Import**

#### Import Process
1. Customer scans QR code from receipt
2. App sends token to backend with JWT auth
3. Backend validates token and marks as imported
4. Products automatically added to customer's list
5. User sees confirmation with product count

**API Call:**
```
GET /api/import/{token}
Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "trip_id": 1,
  "store": "Supermarkt ABC",
  "timestamp": "2025-12-06T14:55:54",
  "products": [...]
}
```

### 4. **Product Management**

#### View Products

**Home Screen Shows:**
- All products with expiration dates
- Color-coded urgency (red = expires today, yellow = this week, green = later)
- Store name and purchase date
- Category badges (Dairy, Bakery, etc.)

**Product Information:**
- Product name
- Category
- Expiration date
- Days until expiration
- Purchase date
- Store name

#### Filter & Sort

**Available Filters:**
- All products
- Expiring today
- Expiring this week
- Expiring soon (< 7 days)
- By category (Dairy, Bakery, Fruits, etc.)

**Sort Options:**
- By expiration date (ascending)
- By category
- By store
- Recently added

#### Mark as Consumed

When a product is consumed:

```
Product: "Milk" 
Status: Expiring 2025-12-15 (9 days)
        ↓ [Mark as Consumed]
Status: ✅ Consumed on 2025-12-06
        (Hidden from main view)
```

**Backend Updates:**
```sql
UPDATE product 
SET removed_at = NOW(), removed_by = 'app' 
WHERE id = {product_id}
```

### 5. **Notifications**

#### Push Notifications

The app can send notifications:
- Tomorrow's expiry date
- Day of expiration
- Custom notification time (configurable)

**Configuration:**
```
Settings → Notifications
  └─ Enable/disable
  └─ Set notification time (e.g., 18:00)
  └─ Notification types
```

#### Expiration Alerts
- Products expiring today: Daily reminder
- Products expiring tomorrow: Evening reminder
- Products expiring this week: Optional notification
- Customizable notification time per user

---

## 🎨 User Interface

### Screen Structure

```
Authentication Stack
├── Login Screen
│   ├── Email input
│   ├── Password input
│   ├── Login button
│   └── Register link
└── Register Screen
    ├── Email input
    ├── Password input
    ├── Confirm password
    └── Register button

Main App Stack
├── Home Screen
│   ├── Product list
│   ├── Filter/sort buttons
│   ├── QR scan button (FAB)
│   ├── Statistics (product count, expiring soon)
│   └── Product actions (mark consumed, view details)
│
├── Scanner Screen
│   ├── Camera preview
│   ├── QR detection overlay
│   ├── Token display
│   ├── Import confirmation
│   └── Manual token input fallback
│
├── Product Details Screen
│   ├── Full product info
│   ├── Store information
│   ├── Nutritional info (if available)
│   ├── Mark as consumed button
│   └── Share/save options
│
└── Settings Screen
    ├── Account management
    ├── Notification preferences
    ├── Theme/language settings
    └── Logout button
```

### Home Screen Mockup

```
╔════════════════════════════════╗
║  FreshReminder               ⚙️  │
╠════════════════════════════════╣
║                                  │
║  📊 Your Products                │
║  Total: 12 | Expiring: 3         │
║                                  │
║ ┌──────────────────────────┐     │
║ │🥛 Milk          TODAY ⚠️  │     │
║ │ Supermarkt ABC           │     │
║ │ Expires: 2025-12-06      │     │
║ └──────────────────────────┘     │
║ ┌──────────────────────────┐     │
║ │🍞 Bread         2d left ⚠️ │    │
║ │ Supermarkt ABC           │     │
║ │ Expires: 2025-12-08      │     │
║ └──────────────────────────┘     │
║ ┌──────────────────────────┐     │
║ │🍎 Apple         5d left ✓ │    │
║ │ Supermarkt ABC           │     │
║ │ Expires: 2025-12-11      │     │
║ └──────────────────────────┘     │
║                                  │
║                          ┌─────┐ │
║                          │ 📷  │ │
║                          │ QR  │ │
║                          └─────┘ │
╚════════════════════════════════╝
```

### Scanner Screen Mockup

```
╔════════════════════════════════╗
║  Scan Receipt QR Code            │
╠════════════════════════════════╣
║                                  │
║                                  │
║              📷                   │
║        [Camera Preview]           │
║                                  │
║        ╔─────────────╗            │
║        │ QR Detected │            │
║        ╚─────────────╝            │
║                                  │
║  Token: p2CRdexRqeY64JyXYTz_vA   │
║                                  │
║      [✓ Import Products]          │
║      [Manual Entry]               │
║                                  │
╚════════════════════════════════╝
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart
│   └── App entry point, theme configuration
│
├── models/
│   ├── product.dart              ← Product data model
│   ├── shopping_trip.dart         ← Trip data model
│   └── user.dart                  ← User account model
│
├── providers/
│   ├── auth_provider.dart         ← Authentication state
│   ├── product_provider.dart      ← Product list state
│   └── notification_provider.dart ← Notification preferences
│
├── screens/
│   ├── auth_wrapper.dart          ← Login/Register selector
│   ├── login_screen.dart          ← User login UI
│   ├── register_screen.dart       ← User registration UI
│   ├── home_screen.dart           ← Main product list
│   ├── scanner_screen.dart        ← QR code scanner
│   ├── product_details_screen.dart← Product info detail
│   ├── settings_screen.dart       ← User preferences
│   └── splash_screen.dart         ← App startup screen
│
├── services/
│   ├── api_service.dart           ← HTTP requests to backend
│   ├── auth_service.dart          ← Login/register logic
│   ├── storage_service.dart       ← Local persistent storage
│   └── notification_service.dart  ← Push notification setup
│
├── widgets/
│   ├── product_card.dart          ← Reusable product display
│   ├── filter_bar.dart            ← Product filtering UI
│   ├── empty_state.dart           ← No products screen
│   └── loading_spinner.dart       ← Loading animation
│
└── config/
    ├── api_config.dart            ← Backend URL configuration
    ├── theme.dart                 ← Theme/color constants
    └── constants.dart             ← App-wide constants
```

---

## 🔐 Authentication Flow

### Registration Flow

```
User Input
  ↓
[Email] [Password] [Confirm]
  ↓
validate_email()
validate_password()
  ↓
POST /api/users/register
  └─→ {email, password}
  ↓
Backend Response
  └─→ {token: JWT}
  ↓
save_token(JWT)
  ├─→ SharedPreferences (mobile)
  ├─→ LocalStorage (web)
  └─→ File system (desktop)
  ↓
Navigate to Home
```

### Login Flow

```
User Input
  ↓
[Email] [Password]
  ↓
POST /api/users/login
  └─→ {email, password}
  ↓
Backend Response
  └─→ {token: JWT}
  ↓
save_token(JWT)
  ↓
Load products
  └─→ GET /api/products
  ↓
Navigate to Home
```

### Token Management

**Storage:**
```dart
// Mobile (Android/iOS)
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', token);

// Web
window.localStorage['jwt_token'] = token;

// Desktop (Windows/macOS/Linux)
File tokenFile = File('.config/freshreminder/token');
await tokenFile.writeAsString(token);
```

**Usage in Requests:**
```dart
Map<String, String> headers = {
  'Authorization': 'Bearer $jwtToken',
  'Content-Type': 'application/json',
};
```

**Auto-Logout on Expiration:**
- Check token expiration before each request
- If expired (> 30 days old), prompt re-login
- Clear local storage
- Navigate to login screen

---

## 📡 API Integration

### Endpoints Used

#### GET /api/products
Get all products for logged-in user.

```dart
Future<List<Product>> getProducts() async {
  final response = await http.get(
    Uri.parse('$API_URL/api/products'),
    headers: {
      'Authorization': 'Bearer $jwtToken',
    },
  );
  
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((p) => Product.fromJson(p)).toList();
  }
  throw Exception('Failed to load products');
}
```

#### GET /api/import/{token}
Import a shopping trip from a QR code.

```dart
Future<ShoppingTrip> importTrip(String token) async {
  final response = await http.get(
    Uri.parse('$API_URL/api/import/$token'),
    headers: {
      'Authorization': 'Bearer $jwtToken',
    },
  );
  
  if (response.statusCode == 200) {
    return ShoppingTrip.fromJson(jsonDecode(response.body));
  } else if (response.statusCode == 409) {
    throw Exception('Trip already imported');
  } else if (response.statusCode == 410) {
    throw Exception('Token expired');
  }
  throw Exception('Failed to import trip');
}
```

#### POST /api/users/register
Create a new account.

```dart
Future<String> register(String email, String password) async {
  final response = await http.post(
    Uri.parse('$API_URL/api/users/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );
  
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return data['token'];
  }
  throw Exception('Registration failed');
}
```

#### POST /api/users/login
Authenticate and get JWT token.

```dart
Future<String> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$API_URL/api/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['token'];
  }
  throw Exception('Login failed');
}
```

---

## 🔧 Build Instructions

### Prerequisites

```bash
# Install Flutter (if not already installed)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify installation
flutter doctor
```

### Building for Different Platforms

#### Android

```bash
# Generate APK
flutter build apk --release

# Generate App Bundle (for Google Play)
flutter build appbundle --release

# Output locations
# APK: build/app/outputs/flutter-app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
# Build for physical device
flutter build ios --release

# Build for App Store
flutter build ios --release --no-codesign

# Archive and upload
open ios/Runner.xcworkspace
# Archive in Xcode, then upload to App Store Connect
```

#### Web

```bash
# Build web version
flutter build web --release

# Output: build/web/
# Deploy to any web server (Firebase, Netlify, etc.)
```

#### Linux

```bash
# Build Linux app
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

#### macOS

```bash
# Build macOS app
flutter build macos --release

# Output: build/macos/Build/Products/Release/
```

#### Windows

```bash
# Build Windows app
flutter build windows --release

# Output: build/windows/runner/Release/
```

---

## 📦 Dependencies

Key Flutter packages in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5              # State management
  http: ^1.1.0                  # HTTP requests
  shared_preferences: ^2.2.0    # Local storage (mobile)
  mobile_scanner: ^7.1.3        # QR code scanning
  jwt_decoder: ^2.0.1          # JWT token parsing
  intl: ^0.19.0                 # Date/time formatting
  uuid: ^4.0.0                  # UUID generation
  cached_network_image: ^3.3.0  # Image caching
```

---

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widgets/product_card_test.dart

# Run tests with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d iphone
```

### Manual Testing Checklist

- [ ] Register new account
- [ ] Login with credentials
- [ ] Scan QR code successfully
- [ ] Import shopping trip
- [ ] View products with correct info
- [ ] Filter products by category
- [ ] Sort by expiration date
- [ ] Mark product as consumed
- [ ] Change notification settings
- [ ] Logout and login again
- [ ] Test on different platforms (Android, iOS, Web, Linux)

---

## 🚢 Deployment

### Mobile App Stores

#### Google Play (Android)

1. Create Google Play Developer account
2. Generate signing key:
   ```bash
   keytool -genkey -v -keystore ~/key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias key
   ```
3. Create `android/key.properties`:
   ```properties
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=key
   storeFile=PATH_TO_KEY.JKS
   ```
4. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```
5. Upload to Google Play Console

#### Apple App Store (iOS)

1. Create Apple Developer account
2. Create App ID in Apple Developer Portal
3. Generate provisioning profiles
4. Configure signing in Xcode
5. Build and archive:
   ```bash
   flutter build ios --release
   ```
6. Upload via Xcode or Transporter

### Web Deployment

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy

# Or deploy to Netlify
netlify deploy --prod --dir build/web
```

### Desktop Deployment

Package for distribution:

```bash
# Linux
tar -czf freshreminder-linux.tar.gz build/linux/x64/release/bundle/

# macOS
ditto -c -k --sequesterRsrc build/macos/Build/Products/Release/FreshReminder.app freshreminder-macos.zip

# Windows
# Compress build/windows/runner/Release/ folder
```

---

## 🔍 Troubleshooting

### App won't start

**Error:** `PlatformException: PERMISSION_DENIED`
- **Solution (Android):** Grant camera permission in Settings > Apps > FreshReminder
- **Solution (iOS):** Check Info.plist for camera permission request

**Error:** `MissingPluginException: mobile_scanner`
- **Solution:** Run `flutter pub get` and rebuild
- **Solution (Linux):** Use manual token input (camera not supported)

### Network errors

**Error:** `SocketException: Failed host lookup`
- **Solution:** Check internet connection
- **Solution:** Verify API_URL is correct
  ```bash
  flutter run -d android \
    --dart-define=API_URL=http://10.0.2.2:5000
  ```
  (Use 10.0.2.2 for Android emulator localhost)

### Token/authentication errors

**Error:** `401 Unauthorized`
- **Solution:** Token expired, re-login required
- **Solution:** Clear app cache: Settings > Apps > FreshReminder > Clear Cache

**Error:** `Invalid token format`
- **Solution:** Check that token is stored correctly
  ```dart
  final prefs = await SharedPreferences.getInstance();
  print(prefs.getString('jwt_token'));
  ```

### Database/sync errors

**Error:** `Products not loading`
- **Solution:** Check network connectivity
- **Solution:** Verify backend is running: `curl http://localhost:5000/health`
- **Solution:** Re-login to refresh token

---

## 📚 Data Models

### Product Model

```dart
class Product {
  final int id;
  final int tripId;
  final String name;
  final String category;
  final DateTime expirationDate;
  final DateTime addedAt;
  final DateTime? removedAt;
  final String? removedBy;
  
  bool get isExpired => expirationDate.isBefore(DateTime.now());
  int get daysUntilExpiration => 
    expirationDate.difference(DateTime.now()).inDays;
  
  bool get isConsumed => removedAt != null;
}
```

### ShoppingTrip Model

```dart
class ShoppingTrip {
  final int id;
  final String token;
  final DateTime timestamp;
  final String storeName;
  final List<Product> products;
  
  bool get isExpired => 
    DateTime.now().difference(timestamp).inHours > 24;
}
```

### User Model

```dart
class User {
  final int id;
  final String email;
  final int notificationTime;
  final DateTime createdAt;
}
```

---

## 🔗 Related Documentation

- [Main README](../README.md) - System overview
- [Backend Documentation](../backend/Backend.md) - API details
- [FRKassa Documentation](../FRKassa/FRKassa.md) - Employee app
