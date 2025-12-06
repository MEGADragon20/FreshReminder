# FRKassa - Architecture & Design

## Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FRKassa Flutter App                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Main Navigation Screen                  │   │
│  │  (Bottom Navigation - Scanner / Cart tabs)           │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓                                    ↓                │
│  ┌──────────────────┐              ┌──────────────────────┐  │
│  │ Scanner Screen   │              │ Cart Overview Screen │  │
│  │                  │              │                      │  │
│  │ • QR Detection   │              │ • Product List       │  │
│  │ • Torch Toggle   │              │ • Status Indicators  │  │
│  │ • Error Dialog   │              │ • CloudCart ID Input │  │
│  │ • Product Count  │              │ • Submit Button      │  │
│  └──────────────────┘              └──────────────────────┘  │
│         ↓                                    ↑                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         CloudCartProvider (State Management)         │   │
│  │                                                       │   │
│  │  • products: List<ScannedProduct>                   │   │
│  │  • addProduct()                                      │   │
│  │  • removeProductAt()                                │   │
│  │  • clearCart()                                       │   │
│  │  • getExpiredProducts()                             │   │
│  │  • getExpiringToday()                               │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓                                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Widgets (UI Components)                 │   │
│  │                                                       │   │
│  │  • ProductListItem (Product card)                    │   │
│  │  • ScanErrorDialog (Error display)                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Models & Services                 │   │
│  │                                                       │   │
│  │  • ScannedProduct (Data model)                       │   │
│  │  • ApiConfig (Configuration)                         │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓                                                     │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Backend API (Flask)                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  POST /api/CloudCart/{cloudCartId}                          │
│  • Receive products                                          │
│  • Store in database                                         │
│  • Set 24-hour expiration                                    │
│  • Return success/error                                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Scanning Flow
```
[Mobile Scanner] 
    ↓ (detects QR code)
[onDetect callback]
    ↓ (raw QR data: "Product|Date|Info")
[ScannedProduct.fromQRCode()]
    ↓ (parses string, validates date)
[CloudCartProvider.addProduct()]
    ↓ (adds to products list, notifyListeners)
[UI updates] (product count, success snackbar)
```

### Submission Flow
```
[User enters CloudCart ID]
    ↓
[User taps Submit]
    ↓
[_submitCart() in CartOverviewScreen]
    ↓
[Validation: ID not empty, Cart not empty]
    ↓
[API Call: POST /api/CloudCart/{id}]
    ↓
[Backend: Store products, set expiration]
    ↓
[Response: 200 OK]
    ↓
[CloudCartProvider.clearCart()]
    ↓
[UI: Show success, clear input fields]
```

## State Management Flow

```
┌─────────────────────────┐
│ ScannedProduct          │
│ - name: String          │
│ - bestBeforeDate: Date  │
│ - additionalInfo: String│
└────────────┬────────────┘
             ↑
             │ (creates)
             │
┌────────────┴─────────────────────┐
│ CloudCartProvider                │
│ - products: List<ScannedProduct> │
│                                   │
│ Methods:                          │
│ • addProduct()                    │
│ • removeProductAt()               │
│ • clearCart()                     │
│ • hasExpiredProducts()            │
│ • getExpiredProducts()            │
│ • getExpiringToday()              │
│                                   │
│ Notifies listeners on change      │
└────────────┬─────────────────────┘
             ↑
             │ (watches)
             │
  ┌──────────┴─────────────┐
  ↓                        ↓
ScannerScreen      CartOverviewScreen
 (displays)          (displays & submits)
```

## Component Hierarchy

```
MaterialApp
├── MultiProvider (Provides state)
│   ├── CloudCartProvider
│   └── ScannerProvider
│
└── MainNavigationScreen
    ├── IndexedStack
    │   ├── ScannerScreen
    │   │   ├── AppBar
    │   │   ├── MobileScanner (camera)
    │   │   │   └── onDetect → ScannedProduct.fromQRCode()
    │   │   └── Bottom Controls
    │   │       ├── Product Count
    │   │       ├── Torch Button
    │   │       └── Clear Cart Button
    │   │
    │   └── CartOverviewScreen
    │       ├── AppBar
    │       ├── CloudCart ID TextField
    │       ├── ProductList (ListView)
    │       │   └── ProductListItem (x N)
    │       │       ├── Product Icon
    │       │       ├── Product Name
    │       │       ├── Best Before Date
    │       │       ├── Additional Info
    │       │       ├── Status Label
    │       │       └── Delete Button
    │       └── BottomContainer
    │           ├── Statistics Row
    │           │   ├── Total Count
    │           │   ├── Expired Count
    │           │   └── Expiring Today Count
    │           └── Submit Button
    │
    └── BottomNavigationBar
        ├── Scanner Tab
        └── Cart Tab (with count badge)
```

## QR Code Processing

```
QR Code Content: "Milk|2025-12-15|Full Fat 1L"
        ↓
    String.split('|')
        ↓
    ["Milk", "2025-12-15", "Full Fat 1L"]
        ↓
    Validation (2+ parts)
        ↓
    Parse date: DateTime.parse("2025-12-15")
        ↓
    Create ScannedProduct
    {
      name: "Milk",
      bestBeforeDate: DateTime(2025, 12, 15),
      additionalInfo: "Full Fat 1L"
    }
        ↓
    Add to CloudCartProvider.products
        ↓
    Show success feedback
```

## Expiration Logic

```
┌─────────────────────────────────────┐
│ Product Best Before Date Checking   │
└─────────────────────────────────────┘
              ↓
    ┌────────┴────────┐
    ↓                 ↓
Is date < now?    Is date == today?
    ↓                 ↓
   RED              ORANGE
  EXPIRED         EXPIRES TODAY
    ↓                 ↓
hasExpiredProducts()  getExpiringToday()
    ↓                 ↓
Display in stats  Display in stats
and cart UI       and cart UI
```

## API Communication

```
FRKassa App                          Backend Flask
    ↓                                   ↓
POST Request with JSON
├─ URL: /api/CloudCart/{id}
├─ Header: Content-Type: application/json
└─ Body: {
    "products": [
      {
        "name": "Milk",
        "bestBeforeDate": "2025-12-15",
        "additionalInfo": "Full Fat 1L"
      }
    ]
  }
    ├──────────────────────────→ Parse JSON
                                    ↓
                                Validate data
                                    ↓
                                Create CloudCart
                                    ↓
                                Store in DB
                                    ↓
                                Set 24h expiry
    ←──────────────────────────  Return 200 OK
    ↓
Process response
    ↓
Clear local cart
    ↓
Show success message
```

## File Dependencies

```
main.dart
  ├── providers/cloud_cart_provider.dart
  ├── providers/scanner_provider.dart
  └── screens/main_navigation_screen.dart
      ├── screens/scanner_screen.dart
      │   ├── models/scanned_product.dart
      │   ├── providers/cloud_cart_provider.dart
      │   └── widgets/scan_error_dialog.dart
      │
      └── screens/cart_overview_screen.dart
          ├── models/scanned_product.dart
          ├── providers/cloud_cart_provider.dart
          ├── config/api_config.dart
          └── widgets/product_list_item.dart

config/api_config.dart
  └── (provides BASE_URL and API endpoints)

models/scanned_product.dart
  └── (data model with QR parsing)

providers/cloud_cart_provider.dart
  └── (state management)
```

## Error Handling Flow

```
┌──────────────────────────┐
│ QR Code Detected         │
└────────────┬─────────────┘
             ↓
    ┌────────────────┐
    │ Try Parse QR   │
    └────────┬───────┘
             ↓
    ┌────────────────────────────┐
    │ Catch FormatException       │
    │ (invalid format/date)       │
    └────────┬───────────────────┘
             ↓
    ┌────────────────────────────┐
    │ Show ScanErrorDialog        │
    │ Display error message       │
    └────────┬───────────────────┘
             ↓
    ┌────────────────────────────┐
    │ Resume scanning after close │
    └────────────────────────────┘
```

## Performance Considerations

1. **QR Code Processing**: Immediate (synchronous)
2. **Cart Operations**: O(n) where n = number of products
3. **UI Updates**: Provider notifyListeners() only on actual changes
4. **Memory**: All cart data in memory (cleared after submission)
5. **Network**: 30-second timeout for API calls

## Security Considerations

1. **QR Data**: No sensitive data in format
2. **API URL**: Configurable, can use HTTPS
3. **No Authentication**: Currently open (can add JWT/Auth)
4. **No Encryption**: Local data in memory only
5. **CloudCart ID**: User-provided, unique identifier

## Future Architecture Improvements

1. **Local Database**: Use Sqflite for persistent storage
2. **Authentication**: Add user login/JWT
3. **Offline Support**: Queue submissions when offline
4. **Encryption**: Encrypt local data and API calls
5. **Analytics**: Track scan success rates
6. **Real-time Sync**: WebSocket for live updates
7. **Biometric Auth**: Fingerprint/Face ID login
8. **Product Details**: Fetch product info from backend
