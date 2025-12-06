# FRKassa - Environment Configuration Guide

## Backend URL Configuration

The FRKassa app is designed to work with different backend environments. The backend URL is configured at build time.

### Configuration Methods

#### Method 1: Development (Default)

By default, the app connects to `http://localhost:5000`:

```bash
cd /home/md20/Documents/FreshReminder/FRKassa
flutter run
```

**API Base**: `http://localhost:5000`  
**Endpoints**: 
- `http://localhost:5000/api/CloudCart/{id}`

#### Method 2: Custom Backend URL (Build Time)

Pass the backend URL when building:

```bash
flutter run --dart-define=API_URL=http://192.168.1.100:5000
```

Or for release builds:

```bash
flutter build apk --release --dart-define=API_URL=https://api.yourdomain.com
```

#### Method 3: Multiple Environments

Create build configurations for different environments:

```bash
# Development (localhost)
flutter build apk --dart-define=API_URL=http://localhost:5000

# Staging
flutter build apk --dart-define=API_URL=https://staging-api.yourdomain.com

# Production
flutter build apk --release --dart-define=API_URL=https://api.yourdomain.com
```

---

## Environment Setup

### Local Development Setup

#### Prerequisites

```bash
# Check Flutter installation
flutter --version
# Expected: Flutter 3.10.1+

# Check Dart installation
dart --version
# Expected: Dart 3.10.1+

# Get dependencies
cd /home/md20/Documents/FreshReminder/FRKassa
flutter pub get
```

#### Start Local Backend

```bash
# Terminal 1: Start FreshReminder backend
cd /home/md20/Documents/FreshReminder/backend
python app.py

# Expected output:
# * Running on http://0.0.0.0:5000/
# * Debugger PIN: xxx-xxx-xxx
```

#### Run FRKassa App

```bash
# Terminal 2: Run Flutter app
cd /home/md20/Documents/FreshReminder/FRKassa
flutter run

# Expected: App opens on emulator/device
# and connects to http://localhost:5000
```

---

## Staging Environment

### Prerequisites

- Backend deployed to staging server
- SSL certificate (HTTPS)
- CORS configured properly

### Build for Staging

```bash
flutter build apk \
  --dart-define=API_URL=https://staging-api.yourdomain.com \
  --dart-define=ENVIRONMENT=staging
```

### Configuration File

Create `lib/config/staging_config.dart`:

```dart
class StagingConfig {
  static const String apiUrl = 'https://staging-api.yourdomain.com';
  static const String apiKey = 'staging-key-123';
  static const bool enableLogging = true;
  static const Duration timeout = Duration(seconds: 30);
}
```

---

## Production Environment

### Prerequisites

- Backend deployed to production server
- SSL certificate with valid domain
- CORS properly configured
- Error tracking/monitoring setup
- Database backups enabled

### Build for Production

```bash
# Android App Bundle (for Google Play)
flutter build appbundle \
  --release \
  --dart-define=API_URL=https://api.yourdomain.com \
  --dart-define=ENVIRONMENT=production

# iOS (for App Store)
flutter build ios \
  --release \
  --dart-define=API_URL=https://api.yourdomain.com \
  --dart-define=ENVIRONMENT=production
```

### Configuration File

Create `lib/config/production_config.dart`:

```dart
class ProductionConfig {
  static const String apiUrl = 'https://api.yourdomain.com';
  static const String apiKey = 'prod-key-xyz';
  static const bool enableLogging = false;
  static const Duration timeout = Duration(seconds: 30);
}
```

---

## Flavor-Based Configuration (Advanced)

### Create Build Flavors

```bash
# Android: Build APK with flavor
flutter build apk \
  --flavor development \
  --dart-define=API_URL=http://localhost:5000

flutter build apk \
  --flavor staging \
  --dart-define=API_URL=https://staging-api.yourdomain.com

flutter build apk \
  --flavor production \
  --dart-define=API_URL=https://api.yourdomain.com
```

### iOS Schemes

In Xcode, create different schemes for different environments and configure accordingly.

---

## Docker Deployment

### Backend Docker Container

**Dockerfile for backend**:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install -r requirements.txt

COPY backend .

ENV FLASK_APP=app.py
ENV API_PORT=5000

EXPOSE 5000

CMD ["python", "app.py"]
```

### Docker Compose

**docker-compose.yml**:

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://user:password@db:5432/frkassa
    depends_on:
      - db
    networks:
      - frkassa-network

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: frkassa
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - frkassa-network

volumes:
  postgres_data:

networks:
  frkassa-network:
    driver: bridge
```

### Deployment

```bash
# Start containers
docker-compose up -d

# Check logs
docker-compose logs -f backend

# Build Flutter app pointing to container
flutter build apk --dart-define=API_URL=http://your-host:5000
```

---

## Environment Variables

### Development

```bash
# .env file (not in version control)
API_URL=http://localhost:5000
FLUTTER_ENV=development
LOG_LEVEL=debug
```

### Staging

```bash
API_URL=https://staging-api.yourdomain.com
FLUTTER_ENV=staging
LOG_LEVEL=info
```

### Production

```bash
API_URL=https://api.yourdomain.com
FLUTTER_ENV=production
LOG_LEVEL=error
```

---

## DNS Configuration

### Subdomain Setup

For production, set up DNS records:

```
api.yourdomain.com  A  your.server.ip.address
```

### HTTPS/SSL

Ensure backend has valid SSL certificate:

```bash
# Let's Encrypt (free)
certbot certonly --standalone -d api.yourdomain.com

# Use in Flask:
app.run(
    host='0.0.0.0',
    port=443,
    ssl_context=('/path/to/cert.pem', '/path/to/key.pem')
)
```

---

## Network Configuration

### CORS Setup (Flask Backend)

```python
from flask_cors import CORS

CORS(app, resources={
    r"/api/*": {
        "origins": [
            "http://localhost:*",
            "https://yourdomain.com",
            "https://api.yourdomain.com"
        ],
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True
    }
})
```

### Firewall Rules

```bash
# Allow port 5000 (development)
sudo ufw allow 5000/tcp

# Allow ports 80, 443 (production)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

---

## Monitoring & Logging

### Development Logging

```dart
// In main.dart
if (String.fromEnvironment('ENVIRONMENT') == 'development') {
  // Enable verbose logging
}
```

### Production Monitoring

```dart
// In main.dart
if (String.fromEnvironment('ENVIRONMENT') == 'production') {
  // Send errors to monitoring service
  // Configure error reporting
}
```

### Backend Logging

```python
import logging

logging.basicConfig(
    level=logging.DEBUG if os.getenv('FLASK_ENV') == 'development' else logging.ERROR,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

---

## Testing Configuration

### Unit Test Environment

```bash
cd /home/md20/Documents/FreshReminder/FRKassa
flutter test --dart-define=API_URL=http://localhost:5000
```

### Integration Test

```bash
flutter drive \
  --target=test_driver/app.dart \
  --dart-define=API_URL=http://localhost:5000
```

---

## Performance Configuration

### API Timeout

Current: 30 seconds (can be adjusted in `lib/config/api_config.dart`)

```dart
class ApiConfig {
  static const Duration apiTimeout = Duration(seconds: 30);
}
```

### Batch Size

For large number of products, consider pagination:

```dart
// Modify CloudCartProvider for batching
static const int BATCH_SIZE = 50;
```

---

## Security Best Practices

### API Keys (Future Enhancement)

```bash
# Pass API key at build time
flutter build apk \
  --dart-define=API_URL=https://api.yourdomain.com \
  --dart-define=API_KEY=your-secret-key
```

### SSL/TLS

Always use HTTPS in production:

```dart
// lib/config/api_config.dart
static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.yourdomain.com',  // Not http
);
```

### Secrets Management

For production secrets, use:
- Environment variables
- Secret management tools (HashiCorp Vault, etc.)
- Cloud provider secret managers (AWS Secrets Manager, etc.)

---

## Troubleshooting Configuration

### Connection Issues

```bash
# Test backend connectivity
curl http://localhost:5000/health

# For HTTPS
curl https://api.yourdomain.com/health \
  --cacert /path/to/ca-bundle.crt
```

### CORS Errors

Backend logs will show CORS errors:

```
Access to XMLHttpRequest blocked by CORS policy
```

**Solution**: Update CORS configuration in backend

### Certificate Errors (HTTPS)

```bash
# Verify certificate
openssl s_client -connect api.yourdomain.com:443

# Check expiration
openssl x509 -in cert.pem -noout -dates
```

---

## Rollback Strategy

### Version Management

```bash
# Tag versions in git
git tag -a v1.0.0 -m "Production release 1.0.0"
git push origin v1.0.0

# Build specific version
git checkout v1.0.0
flutter build apk --release
```

### Backend Rollback

```bash
# Keep previous version available
docker pull yourdomain/backend:1.0.0
docker run yourdomain/backend:1.0.0
```

---

## Reference

- **Default Dev URL**: `http://localhost:5000`
- **Config File**: `lib/config/api_config.dart`
- **Build Command**: `flutter build apk --dart-define=API_URL=YOUR_URL`
- **More Help**: See `SETUP.md` and `BACKEND_INTEGRATION.md`
