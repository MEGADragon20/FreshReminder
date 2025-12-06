# FRKassa Employee App Documentation

The cashier-facing Flutter application for creating shopping trips and generating QR codes.

## 🎯 Overview

FRKassa is a specialized application designed for store employees (cashiers, checkout staff) to:
- Scan products (via barcode or manual entry) and add them to a shopping cart
- Input product details: name, category, and expiration date
- Create a shopping trip and generate a unique QR code
- Provide the QR code to customers for easy product tracking

The app is the **cashier side** of the FreshReminder ecosystem. After customers scan the QR code, they use the FreshReminder app to import and manage their products.

## 🚀 Quick Start

### Installation

#### Option 1: Build from Source

```bash
cd FRKassa
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
# Android
flutter run -d android

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
flutter run -d android \
  --dart-define=API_URL=http://10.0.2.2:5000
```

For production:

```bash
flutter run -d iphone \
  --dart-define=API_URL=https://api.freshreminder.de
```

## 📱 Features

### 1. **Product Scanning**

#### Barcode/QR Scanning (Coming Soon)
- Scan product barcodes to auto-populate product details
- Look up product information from database
- Automatically suggest expiration date based on product type

**Currently:** Manual product entry

#### Manual Product Entry

**Form Fields:**
```
Product Name
├── Text input (required)
├── Example: "Milk", "Bread", "Yogurt"
└── Max 200 characters

Category
├── Dropdown selection (optional)
├── Options: Dairy, Bakery, Fruits, Vegetables, 
│            Meat, Frozen, Beverages, Other
└── Default: "Other"

Expiration Date
├── Date picker (required)
├── Format: YYYY-MM-DD
├── Must be today or later
└── Visual picker or manual entry

[Add to Cart Button]
```

### 2. **Shopping Cart Management**

#### View Cart

**Cart Display Shows:**
- Product count
- Total items
- List of all products with:
  - Name
  - Category
  - Expiration date
  - Delete button (remove from cart)

**Cart Mockup:**
```
Shopping Cart (4 items)

1️⃣  Milk (Dairy)
    Expires: 2025-12-15
    [X] Remove

2️⃣  Bread (Bakery)
    Expires: 2025-12-07
    [X] Remove

3️⃣  Yogurt (Dairy)
    Expires: 2025-12-10
    [X] Remove

4️⃣  Apple Juice (Beverages)
    Expires: 2025-12-20
    [X] Remove

[← Back to Add Products]  [Create QR →]
```

#### Modify Cart

**Actions:**
- Remove individual product: Tap [X] next to product
- Clear entire cart: "Clear All" button
- Back to add more: "Add More Products" button

#### Empty Cart Handling

When no products in cart:
```
Empty Cart View

No products added yet.

Add products to create a shopping trip.

[+ Add Product]
```

### 3. **QR Code Generation**

#### Create Shopping Trip

When user taps "Warenkorb erstellen" (Create Cart/Shopping Trip):

1. **Validation**
   - Check cart has at least 1 product
   - Validate all product dates are valid
   - Show error if validation fails

2. **API Call**
   ```
   POST /api/import/generate
   {
     "products": [
       {
         "name": "Milk",
         "category": "Dairy",
         "expiration_date": "2025-12-15"
       },
       ...
     ],
     "store_name": "Supermarkt ABC"
   }
   ```

3. **Response Processing**
   - Receive unique token: `p2CRdexRqeY64JyXYTz_vA`
   - Receive QR code URL
   - Receive expiration time (24 hours from now)

#### Display QR Code

**QR Screen Shows:**
```
╔════════════════════════════════╗
║  Shopping Trip Created         ✓ │
╠════════════════════════════════╣
║                                  │
║        ╔──────────────╗           │
║        │              │           │
║        │   [QR CODE]  │           │
║        │              │           │
║        └──────────────┘           │
║                                  │
║  Token: p2CRdexRqeY64JyXYTz_vA   │
║  Valid for: 24 hours             │
║  Products: 4 items               │
║                                  │
║       [Share QR Code]             │
║       [Print QR Code]             │
║       [Save as Image]             │
║       [New Shopping Trip]         │
║                                  │
╚════════════════════════════════╝
```

**QR Code Details:**
- Encodes: `https://api.freshreminder.de/import/{token}`
- Size: Suitable for printing or phone display
- Format: Standard QR code (ISO/IEC 18004)

#### QR Code Actions

**Share**
```
[Share QR Code]
├── AirDrop (iOS)
├── Bluetooth (Android)
├── Email
├── SMS
├── WhatsApp
└── Copy link
```

**Print**
```
[Print QR Code]
├── Select printer
├── Adjust size (standard: 10cm x 10cm)
├── Quantity
└── Print
```

**Save**
```
[Save as Image]
├── PNG format
├── Filename: {store_name}_{timestamp}.png
├── Save location: Photos/Gallery
└── Show in files
```

### 4. **Store Information**

#### Store Name Entry
- Optional field
- Default: "Unknown Store"
- Used for customer context
- Displayed when customer imports trip

**Example:**
```
Customer sees:
"Products from: Supermarkt ABC"
"Purchased on: 2025-12-06 14:55"
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart
│   └── App entry point, theme configuration
│
├── models/
│   ├── scanned_product.dart    ← Product data model
│   └── shopping_trip.dart      ← Trip/cart model
│
├── providers/
│   ├── product_provider.dart   ← Cart state management
│   └── api_provider.dart       ← Backend communication
│
├── screens/
│   ├── home_screen.dart        ← Main app entry
│   ├── product_input_screen.dart← Add product form
│   ├── cart_overview_screen.dart← Review cart
│   ├── qr_display_screen.dart   ← Show generated QR
│   └── settings_screen.dart     ← App settings
│
├── services/
│   ├── api_service.dart        ← HTTP to backend
│   ├── qr_service.dart         ← QR generation
│   ├── storage_service.dart    ← Local data persistence
│   └── sharing_service.dart    ← Share/print QR
│
├── widgets/
│   ├── product_form.dart       ← Reusable form UI
│   ├── product_card.dart       ← Product display
│   ├── qr_widget.dart          ← QR code display
│   └── custom_button.dart      ← Themed buttons
│
└── config/
    ├── api_config.dart         ← Backend URL
    ├── theme.dart              ← Colors/styles
    └── constants.dart          ← App constants
```

---

## 🔄 Complete Workflow

### Full Cashier Process

```
╔════════════════════════════════════════════════════╗
║  FRKassa Cashier Workflow                          ║
╚════════════════════════════════════════════════════╝

START
  ↓
[Home Screen]
  ├── Add Product button
  ├── View Cart button
  └── Settings button
  ↓
[+ Add Product Screen]
  ├── Enter Product Name: "Milk"
  ├── Select Category: "Dairy"
  ├── Pick Expiration Date: "2025-12-15"
  └── Tap [Add to Cart]
  ↓
Product added → Cart count: 1
  ↓
[Continue adding products]
  │ (repeat for each item)
  ├── "Bread" | "Bakery" | "2025-12-07"
  ├── "Yogurt" | "Dairy" | "2025-12-10"
  └── "Juice" | "Beverages" | "2025-12-20"
  ↓
[View Cart]
  ├── Shows 4 products
  ├── Review all items
  └── Option to remove items
  ↓
[Warenkorb erstellen / Create Shopping Trip]
  ├── Tap button
  ├── Validate products
  ├── Send to backend
  └── Wait for response
  ↓
[Backend Processing]
  ├── Generate unique token
  ├── Create database records
  └── Return QR code
  ↓
[QR Display Screen]
  ├── Show QR code
  ├── Show token
  ├── Show valid until time
  ├── Options:
  │  ├── Share with customer
  │  ├── Print
  │  └── Save image
  └── New Trip button
  ↓
[Customer scans QR]
  └── Opens FreshReminder app
  ↓
[Customer imports products]
  └── Products now in their app
  ↓
[New Shopping Trip]
  └── Back to [Home] to start again
  ↓
END
```

---

## 📡 API Integration

### Backend Endpoint

#### POST /api/import/generate

Create a shopping trip with products.

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

**Response:**
```json
{
  "token": "p2CRdexRqeY64JyXYTz_vA",
  "qr_url": "https://api.freshreminder.de/import/p2CRdexRqeY64JyXYTz_vA",
  "expires_at": "2025-12-07T14:55:54.290944"
}
```

**Implementation in Flutter:**
```dart
Future<Map<String, dynamic>> createShoppingTrip(
  List<ScannedProduct> products,
  String storeName,
) async {
  final response = await http.post(
    Uri.parse('$API_URL/api/import/generate'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'products': products.map((p) => {
        'name': p.name,
        'category': p.category,
        'expiration_date': p.expirationDate.toString().split(' ')[0],
      }).toList(),
      'store_name': storeName,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 400) {
    throw Exception('Invalid product data');
  }
  throw Exception('Failed to create shopping trip');
}
```

---

## 📱 Product Input Format

### Field Specifications

#### Product Name
- **Type:** String
- **Required:** Yes
- **Max Length:** 200 characters
- **Validation:**
  - Cannot be empty
  - Trimmed of whitespace
  - Examples: "Milk", "Whole Wheat Bread", "Greek Yogurt"

#### Category
- **Type:** String (dropdown)
- **Required:** No (defaults to "Other" / "Sonstiges")
- **Options:**
  - Dairy (Milchprodukte)
  - Bakery (Backwaren)
  - Fruits (Obst)
  - Vegetables (Gemüse)
  - Meat (Fleisch)
  - Frozen (Tiefkühlware)
  - Beverages (Getränke)
  - Other (Sonstiges)
- **Localization:** German app names in parentheses

#### Expiration Date
- **Type:** Date (YYYY-MM-DD)
- **Required:** Yes
- **Validation:**
  - Must be today or in future
  - Cannot be in past
  - Format enforced by date picker
- **Examples:**
  - "2025-12-15" (in 9 days)
  - "2025-12-07" (in 1 day)
  - "2026-06-30" (in 7 months)

---

## 🎨 User Interface

### Screen 1: Home Screen

```
╔════════════════════════════════╗
║  FRKassa                    ⚙️  │
╠════════════════════════════════╣
║                                  │
║  Welcome to FRKassa              │
║                                  │
║  📦 Shopping Cart                │
║     Items in cart: 0             │
║                                  │
║  ┌──────────────────────────┐   │
║  │  [+ Add Product]          │   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │  [📋 View Cart]          │   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │  [⚙️  Settings]           │   │
║  └──────────────────────────┘   │
║                                  │
╚════════════════════════════════╝
```

### Screen 2: Add Product Screen

```
╔════════════════════════════════╗
║  Add Product                    │
╠════════════════════════════════╣
║                                  │
║  Product Name *                  │
║  ┌──────────────────────────┐   │
║  │ ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁   │   │
║  └──────────────────────────┘   │
║                                  │
║  Category                        │
║  ┌──────────────────────────┐   │
║  │ Dairy              ▼      │   │
║  └──────────────────────────┘   │
║  Options: Dairy, Bakery,        │
║           Fruits, Vegetables... │
║                                  │
║  Expiration Date *               │
║  ┌──────────────────────────┐   │
║  │ 2025-12-15         📅      │   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │  [✓ Add to Cart]         │   │
║  └──────────────────────────┘   │
║                                  │
║  [← Back]                        │
║                                  │
╚════════════════════════════════╝
```

### Screen 3: Cart Overview Screen

```
╔════════════════════════════════╗
║  Shopping Cart (4 items)        │
╠════════════════════════════════╣
║                                  │
║  Store Name (optional):          │
║  ┌──────────────────────────┐   │
║  │ Supermarkt ABC         │   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │ 1. Milk (Dairy)          │   │
║  │    Exp: 2025-12-15    [X]│   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │ 2. Bread (Bakery)        │   │
║  │    Exp: 2025-12-07    [X]│   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │ 3. Yogurt (Dairy)        │   │
║  │    Exp: 2025-12-10    [X]│   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │ 4. Juice (Beverages)     │   │
║  │    Exp: 2025-12-20    [X]│   │
║  └──────────────────────────┘   │
║                                  │
║  ┌──────────────────────────┐   │
║  │[Warenkorb erstellen]     │   │
║  │[Carrito crear / Create]  │   │
║  └──────────────────────────┘   │
║                                  │
║  [← Add More] [🗑 Clear All]   │
║                                  │
╚════════════════════════════════╝
```

### Screen 4: QR Display Screen

```
╔════════════════════════════════╗
║  Shopping Trip Created         ✓ │
╠════════════════════════════════╣
║                                  │
║        ╔──────────────╗           │
║        │ ▓ ▓ ▓ ▓ ▓   │           │
║        │ ▓ ░ ░ ░ ▓   │           │
║        │ ▓ ░▓▓▓ ▓   │           │
║        │ ░ ░ ░ ░ ▓   │           │
║        │ ▓ ▓ ▓ ▓ ▓   │           │
║        └──────────────┘           │
║  (Standard QR Code)              │
║                                  │
║  ┌──────────────────────────┐   │
║  │ Token (copy to share):    │   │
║  │ p2CRdexRqeY64JyXYTz_vA   │   │
║  │ [Copy]                   │   │
║  └──────────────────────────┘   │
║                                  │
║  ⏱️  Valid for: 24 hours         │
║  📦 Products: 4 items            │
║  🏪 Store: Supermarkt ABC        │
║                                  │
║  ┌──────────────────────────┐   │
║  │  [Share QR Code]         │   │
║  │  [Print QR Code]         │   │
║  │  [Save as Image]         │   │
║  │  [New Shopping Trip]     │   │
║  └──────────────────────────┘   │
║                                  │
╚════════════════════════════════╝
```

---

## 🔧 Build Instructions

### Prerequisites

```bash
# Flutter SDK
flutter --version

# Platform-specific requirements
# Android: Android SDK, Gradle
# iOS: Xcode
# Web: Chrome/Firefox
# Linux: GTK development files
# macOS: Xcode
# Windows: Visual Studio or MinGW
```

### Building for Different Platforms

#### Android

```bash
# Debug build (for testing on emulator/device)
flutter run -d android

# Release APK (for distribution)
flutter build apk --release

# App Bundle (for Google Play Store)
flutter build appbundle --release

# Output locations
# APK: build/app/outputs/flutter-app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
# Development build
flutter run -d iphone

# Release build for App Store
flutter build ios --release

# Archive for App Store submission
flutter build ios --release --no-codesign
# Then use Xcode to archive and upload
```

#### Web

```bash
# Build web version
flutter build web --release

# Output: build/web/
# Can be deployed to any web server
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

# Output: build/macos/Build/Products/Release/FRKassa.app
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
  qr: ^2.0.0                    # QR code generation
  qr_flutter: ^4.0.0           # QR code widget
  share_plus: ^6.2.0           # Share functionality
  path_provider: ^2.1.0        # File paths
  intl: ^0.19.0                # Date formatting
  uuid: ^4.0.0                 # Unique IDs
```

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] Add single product to cart
- [ ] Add multiple products
- [ ] Verify product details display correctly
- [ ] Remove product from cart
- [ ] Clear entire cart
- [ ] Store name optional (works with/without)
- [ ] Create QR code with empty cart (should error)
- [ ] Create QR code with valid products
- [ ] QR code displays correctly
- [ ] Share QR code via various methods
- [ ] Token displays correctly
- [ ] Expiration time shown
- [ ] Test on Android device
- [ ] Test on iOS device
- [ ] Test on Web browser
- [ ] Test on Linux desktop
- [ ] Test on macOS
- [ ] Test on Windows

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/scanned_product_test.dart

# Run with coverage
flutter test --coverage
```

---

## 🚢 Deployment

### Google Play Store (Android)

1. Create Google Play Developer account ($25 one-time fee)
2. Generate signing key:
   ```bash
   keytool -genkey -v -keystore ~/frk_key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias fr_key
   ```
3. Configure signing in `android/key.properties`
4. Build App Bundle:
   ```bash
   flutter build appbundle --release \
     --dart-define=API_URL=https://api.freshreminder.de
   ```
5. Upload to Google Play Console
6. Complete store listing with screenshots and description
7. Submit for review (usually approved in 24-48 hours)

### Apple App Store (iOS)

1. Enroll in Apple Developer Program ($99/year)
2. Create App ID in Apple Developer Portal
3. Generate provisioning profiles and certificates
4. Configure in Xcode:
   - Team ID
   - Bundle ID: com.freshreminder.frkassa
   - Signing certificates
5. Build for App Store:
   ```bash
   flutter build ios --release
   ```
6. Archive in Xcode and upload to App Store Connect
7. Submit for review (typically 1-2 days)

### Web Deployment

```bash
# Build for web
flutter build web --release \
  --dart-define=API_URL=https://api.freshreminder.de

# Deploy options:
# Firebase Hosting
firebase deploy

# Netlify
netlify deploy --prod --dir build/web

# Self-hosted
scp -r build/web/* user@server:/var/www/frkassa/
```

### Windows/macOS Distribution

```bash
# Sign and package
# Windows: Use MSIX packaging for Windows Store
# macOS: Create .app bundle with notarization for App Store

# Self-hosted distribution
# Provide downloadable installers with auto-update capability
```

---

## 🔍 Troubleshooting

### App won't build

**Error:** `Target of URI doesn't exist: 'package:frkassa/main.dart'`
- **Solution:** Run `flutter pub get` first

**Error:** `Gradle build failed`
- **Solution:** Run `flutter clean` then `flutter pub get`

### API errors

**Error:** `SocketException: Failed to connect`
- **Solution:** Check backend is running on correct address
- **Solution:** For Android emulator, use `10.0.2.2` instead of `localhost`
  ```bash
  flutter run -d android \
    --dart-define=API_URL=http://10.0.2.2:5000
  ```

**Error:** `400 Bad Request`
- **Solution:** Verify product data format (expiration_date must be YYYY-MM-DD)
- **Solution:** Check that at least one product is in cart

### QR code issues

**Error:** `QR code not generating`
- **Solution:** Verify `qr_flutter` package is installed
- **Solution:** Ensure token is valid (non-empty string)

**Error:** `Can't share QR code`
- **Solution:** Check `share_plus` plugin is installed
- **Solution:** Verify file write permissions on device

---

## 📋 QR Code Specification

### QR Code Details

**Content:** URL
```
https://api.freshreminder.de/import/{token}
```

**Token Format:**
- Length: 22 characters
- Character set: URL-safe base64 (A-Z, a-z, 0-9, -, _)
- Example: `p2CRdexRqeY64JyXYTz_vA`
- Uniqueness: Guaranteed unique for 24 hours
- Generation: `secrets.token_urlsafe(16)` on backend

**QR Code Format:**
- Standard: ISO/IEC 18004
- Encoding: UTF-8
- Error Correction: Level M (default)
- Module Size: Configurable (printed: 10cm minimum)

**Usage:**
1. Customer sees QR code (printed or on screen)
2. Customer opens FreshReminder app
3. Customer scans QR code
4. App extracts token and calls backend
5. Products imported to customer's account

---

## 🔗 Related Documentation

- [Main README](../README.md) - System overview
- [Backend Documentation](../backend/Backend.md) - API details
- [FreshReminder Documentation](../freshreminder/FreshReminder.md) - Customer app
