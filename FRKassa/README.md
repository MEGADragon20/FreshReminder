# FRKassa - Employee App

FRKassa is a Flutter-based mobile application designed for supermarket employees to scan QR codes of products and manage shopping carts for submission to the FreshReminder backend.

## Features

- **QR Code Scanner**: Scan product QR codes (format: `ProductName|YYYY-MM-DD|AdditionalInfo`)
- **Cart Management**: View, add, and remove products from the current shopping cart
- **Expiration Tracking**: Visual indicators for expired and expiring products
- **CloudCart Submission**: Submit scanned products to the backend via CloudCart API
- **Real-time Feedback**: Instant visual feedback for scan operations and cart updates

## QR Code Format

QR codes are expected in the following format:

```
ProductName|YYYY-MM-DD|OptionalAdditionalInfo
```

**Examples:**
- `Milk|2025-12-15|Full Fat 1L`
- `Bread|2025-12-10|Whole Wheat`
- `Yogurt|2025-12-08|Plain`

## Architecture

### Models
- **ScannedProduct**: Represents a product scanned from a QR code
  - `name`: Product name
  - `bestBeforeDate`: Best-before date
  - `additionalInfo`: Optional additional information

### Providers
- **CloudCartProvider**: Manages the current shopping cart state
  - Add/remove products
  - Check for expired products
  - Clear cart
  
- **ScannerProvider**: Manages scanner state (currently minimal implementation)

### Screens
- **MainNavigationScreen**: Bottom navigation between Scanner and Cart
- **ScannerScreen**: QR code scanning interface
- **CartOverviewScreen**: View cart contents and submit to backend

### Widgets
- **ProductListItem**: Display individual product in cart
- **ScanErrorDialog**: Show scan errors to user

## Configuration

### API Configuration

The backend URL is configured in `lib/config/api_config.dart`:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:5000',
);
```

For production, pass the URL at build time:

```bash
flutter run --dart-define=API_URL=https://your-domain.com
```

## Getting Started

### Prerequisites
- Flutter 3.10.1 or higher
- Dart 3.10.1 or higher

### Installation

1. Navigate to the project directory:
```bash
cd FRKassa
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Build for Release

#### Android APK
```bash
flutter build apk --dart-define=API_URL=https://your-production-url.com
```

#### Android App Bundle
```bash
flutter build appbundle --dart-define=API_URL=https://your-production-url.com
```

#### iOS
```bash
flutter build ios --dart-define=API_URL=https://your-production-url.com
```

## Backend Integration

### CloudCart API Endpoint

The app submits carts to: `{BASE_URL}/api/CloudCart/{cloudCartId}`

**Request Structure:**
```json
{
  "products": [
    {
      "name": "Product Name",
      "bestBeforeDate": "2025-12-15",
      "additionalInfo": "Extra info"
    }
  ]
}
```

**Expected Response:**
- 200 OK: Cart successfully submitted
- 400 Bad Request: Invalid cart ID or data
- 404 Not Found: CloudCart ID not found or expired

### Data Cleanup

Products are automatically deleted from the local app state after submission. CloudCarts are automatically removed from the backend after 24 hours.

## Dependencies

- **mobile_scanner**: QR code scanning functionality
- **provider**: State management
- **http**: HTTP requests to backend
- **intl**: Date formatting
- **flutter**: Flutter framework

## UI/UX Features

### Scanner Screen
- Real-time QR code detection
- Torch toggle for low-light scanning
- Clear cart button
- Product count display
- Error dialogs for invalid QR codes

### Cart Overview Screen
- Product list with best-before dates
- Visual indicators:
  - Red: Expired products
  - Orange: Products expiring today
  - Gray: Normal products
- Product statistics (Total, Expired, Expiring Today)
- CloudCart ID input field
- Submit button with loading state
- Remove individual products

## Material Design

The app follows Material Design 3 principles with:
- Dynamic color scheme based on seed color (Blue)
- Responsive layout
- Proper spacing and typography
- Accessible components

## Error Handling

- **Invalid QR Code Format**: Shows dialog with error message
- **Camera Access**: Displays camera error if permissions are denied
- **API Errors**: Shows user-friendly error messages
- **Empty Cart**: Prevents submission with empty cart

## Future Enhancements

- Persistent local storage of cart before submission
- Camera permission handling and requests
- Batch QR code scanning for rapid input
- Product information from database
- Offline mode with sync capability
- Analytics and scanning statistics
- Multi-language support
- Dark mode theme

## Development Notes

- The app currently simulates backend submission (TODO: Implement actual API call)
- All products are cleared from memory after submission
- No local persistence of cart data
- QR code format validation is strict and case-sensitive

## License

This is part of the FreshReminder application suite.
