# FreshReminder Development Plan
**Technical Implementation Roadmap**

---

## System Architecture Overview

### Technology Stack
- **Frontend**: Flutter (iOS, Android, Web)
- **Backend**: Flask REST API + Microservices
- **Database**: PostgreSQL (primary), Redis (caching/sessions)
- **Infrastructure**: Kubernetes, AWS/GCP
- **Authentication**: JWT with mandatory 2FA
- **Notifications**: Firebase Cloud Messaging
- **Email**: SendGrid/AWS SES

---

## Database Models

### Core Schema (PostgreSQL)

#### Users
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    two_factor_enabled BOOLEAN DEFAULT true,
    two_factor_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Stores
```sql
CREATE TABLE stores (
    store_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    ip_whitelist TEXT[],
    location_address TEXT,
    subscription_tier VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Products
```sql
CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode VARCHAR(50) UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    category VARCHAR(100),
    default_shelf_life_days INTEGER,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### ProductLots
```sql
CREATE TABLE product_lots (
    lot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id),
    store_id UUID REFERENCES stores(store_id),
    lot_number VARCHAR(100) NOT NULL,
    best_before_date DATE NOT NULL,
    quantity_available INTEGER DEFAULT 0,
    qr_beta_data TEXT NOT NULL, -- Encoded QR data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, lot_number, store_id)
);
```

#### Carts (Active Sessions)
```sql
CREATE TABLE carts (
    cart_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    store_id UUID REFERENCES stores(store_id),
    session_token VARCHAR(255) UNIQUE,
    status VARCHAR(20) DEFAULT 'active', -- active, checked_out, abandoned
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);
```

#### CartItems
```sql
CREATE TABLE cart_items (
    cart_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(cart_id) ON DELETE CASCADE,
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### FridgeItems (CloudFridge Inventory)
```sql
CREATE TABLE fridge_items (
    fridge_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    product_id UUID REFERENCES products(product_id),
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER DEFAULT 1,
    best_before_date DATE NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    consumed_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active' -- active, consumed, expired, discarded
);

CREATE INDEX idx_fridge_user_status ON fridge_items(user_id, status);
CREATE INDEX idx_fridge_expiry ON fridge_items(best_before_date) WHERE status = 'active';
```

#### Transactions (Purchase Records)
```sql
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    store_id UUID REFERENCES stores(store_id),
    qr_alpha_token VARCHAR(255),
    total_amount DECIMAL(10,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    receipt_sent BOOLEAN DEFAULT false
);
```

#### TransactionItems
```sql
CREATE TABLE transaction_items (
    transaction_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2)
);
```

#### Notifications
```sql
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    notification_type VARCHAR(50), -- expiry_warning, expiry_critical, weekly_summary
    fridge_item_id UUID REFERENCES fridge_items(fridge_item_id),
    message TEXT,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Redis Data Structures

#### Active Cart Sessions
```
Key: cart:session:{session_token}
Type: Hash
Fields:
  - user_id
  - store_id
  - cart_id
  - created_at
TTL: 4 hours
```

#### QR Alpha Tokens
```
Key: qr_alpha:{token}
Type: Hash
Fields:
  - cart_id
  - user_id
  - store_id
  - created_at
TTL: 2-5 minutes (configurable)
```

#### User Session Cache
```
Key: user:session:{user_id}
Type: Hash
Fields:
  - access_token
  - refresh_token
  - expires_at
TTL: 30 days
```

---

## Backend Microservices Architecture

### Service Structure

#### 1. Auth Service
**Responsibilities**: User authentication, 2FA, JWT management

**Endpoints**:
- `POST /auth/register` - Create new user account
- `POST /auth/login` - Email/password login
- `POST /auth/verify-2fa` - Verify 2FA code
- `POST /auth/refresh-token` - Refresh JWT access token
- `POST /auth/logout` - Invalidate tokens
- `GET /auth/me` - Get current user info

**Dependencies**: PostgreSQL (users table), Redis (session cache), TOTP library

---

#### 2. Product Service
**Responsibilities**: Product catalog, lot management

**Endpoints**:
- `GET /products` - List products (with search/filter)
- `GET /products/{product_id}` - Get product details
- `POST /products` - Create new product (store auth)
- `PUT /products/{product_id}` - Update product
- `GET /products/barcode/{barcode}` - Lookup by barcode
- `POST /lots` - Create product lot with BBD
- `GET /lots/{lot_id}` - Get lot details
- `PUT /lots/{lot_id}` - Update lot quantity

**Dependencies**: PostgreSQL (products, product_lots)

---

#### 3. Cart Service
**Responsibilities**: Shopping cart management, real-time sync

**Endpoints**:
- `POST /cart/create` - Create new cart session
- `GET /cart/{cart_id}` - Get cart details
- `POST /cart/{cart_id}/items` - Add item to cart (via QR beta scan)
- `PUT /cart/{cart_id}/items/{item_id}` - Update quantity
- `DELETE /cart/{cart_id}/items/{item_id}` - Remove item
- `POST /cart/{cart_id}/generate-qr-alpha` - Generate checkout QR token

**Dependencies**: PostgreSQL (carts, cart_items), Redis (session management)

---

#### 4. Checkout Service
**Responsibilities**: QR alpha validation, POS integration

**Endpoints**:
- `POST /checkout/validate-qr-alpha` - Validate checkout QR (store auth)
- `POST /checkout/complete` - Finalize transaction and move to fridge
- `GET /checkout/transaction/{transaction_id}` - Get transaction details

**Dependencies**: PostgreSQL (transactions, transaction_items), Redis (QR alpha tokens)

---

#### 5. CloudFridge Service
**Responsibilities**: Home inventory management, expiry tracking

**Endpoints**:
- `GET /fridge` - List user's fridge items
- `POST /fridge/add` - Manually add item
- `PUT /fridge/{fridge_item_id}` - Update item (quantity/status)
- `DELETE /fridge/{fridge_item_id}` - Mark as consumed/discarded
- `GET /fridge/expiring-soon` - Items expiring in X days
- `GET /fridge/stats` - Waste reduction analytics

**Dependencies**: PostgreSQL (fridge_items), Background scheduler for notifications

---

#### 6. Notification Service
**Responsibilities**: Expiry alerts, email receipts

**Endpoints**:
- `POST /notifications/send` - Send notification (internal)
- `GET /notifications/user/{user_id}` - Get user notifications
- `PUT /notifications/{notification_id}/read` - Mark as read

**Background Jobs**:
- Daily expiry scanner (9 AM): Check items expiring in 1-3 days
- Weekly summary (Sunday 6 PM): Waste reduction report
- Receipt emailer: Triggered post-checkout

**Dependencies**: PostgreSQL (notifications), Firebase FCM, SendGrid

---

#### 7. Analytics Service (Phase 2)
**Responsibilities**: Consumption patterns, waste tracking, insights

**Endpoints**:
- `GET /analytics/waste-reduction` - User waste stats
- `GET /analytics/spending` - Monthly spending trends
- `GET /analytics/consumption` - Consumption patterns by category
- `POST /analytics/aggregate` - Store-level anonymized insights (retailer dashboard)

**Dependencies**: PostgreSQL (read replicas), BI tools (Metabase/Superset)

---

## Flutter Module Structure

### Customer Mobile App

#### Module Organization
```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── api_config.dart (API base URLs)
│   │   ├── app_theme.dart
│   ├── utils/
│   │   ├── qr_generator.dart
│   │   ├── qr_scanner.dart
│   │   ├── date_formatter.dart
│   ├── services/
│   │   ├── auth_service.dart (JWT handling, 2FA)
│   │   ├── api_client.dart (HTTP wrapper with auth)
│   │   ├── notification_service.dart (FCM integration)
│   │   ├── secure_storage.dart (Keychain/Keystore for tokens)
├── models/
│   ├── user.dart
│   ├── product.dart
│   ├── cart.dart
│   ├── fridge_item.dart
│   ├── transaction.dart
├── providers/ (State Management - Riverpod/Provider)
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── fridge_provider.dart
│   ├── product_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── two_factor_screen.dart
│   ├── shopping/
│   │   ├── qr_scan_screen.dart (QR beta scanner)
│   │   ├── cart_screen.dart (real-time cart view)
│   │   ├── checkout_qr_screen.dart (generate QR alpha)
│   ├── fridge/
│   │   ├── fridge_list_screen.dart (inventory overview)
│   │   ├── expiring_soon_screen.dart
│   │   ├── item_detail_screen.dart
│   │   ├── manual_add_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── subscription_screen.dart
├── widgets/
│   ├── product_card.dart
│   ├── fridge_item_tile.dart
│   ├── expiry_badge.dart
│   ├── qr_scanner_overlay.dart
└── routes/
    └── app_router.dart (Navigation)
```

#### Key Flutter Packages
- `flutter_riverpod` - State management
- `qr_code_scanner` - QR scanning
- `qr_flutter` - QR generation
- `http` / `dio` - API requests
- `flutter_secure_storage` - Token storage
- `firebase_messaging` - Push notifications
- `local_notifications` - Local expiry alerts
- `intl` - Date formatting
- `shared_preferences` - App settings

---

### Employee Labeling App

#### Module Organization
```
lib/
├── main.dart
├── core/
│   ├── services/
│   │   ├── auth_service.dart (Store API key auth)
│   │   ├── printer_service.dart (Zebra SDK wrapper)
│   │   ├── barcode_service.dart
│   │   ├── api_client.dart
├── models/
│   ├── product.dart
│   ├── product_lot.dart
├── providers/
│   ├── auth_provider.dart
│   ├── labeling_provider.dart
├── screens/
│   ├── auth/
│   │   ├── store_login_screen.dart (API key input)
│   ├── labeling/
│   │   ├── barcode_scan_screen.dart
│   │   ├── product_lookup_screen.dart
│   │   ├── lot_creation_screen.dart (BBD input)
│   │   ├── qr_preview_screen.dart
│   │   ├── print_screen.dart (Zebra printer)
│   ├── inventory/
│   │   ├── lot_list_screen.dart
│   │   ├── stock_count_screen.dart
└── widgets/
    ├── barcode_scanner_view.dart
    ├── date_picker_widget.dart
    ├── printer_status_indicator.dart
```

#### Key Flutter Packages (Employee App)
- `flutter_barcode_scanner` - Barcode scanning
- `qr_flutter` - QR generation
- `zsdk` (Zebra SDK) - Label printing
- `dio` - API requests
- `intl` - Date formatting

---

## Security Implementation

### Authentication Flow

#### Customer App
1. User registers with email/password
2. Backend creates user, sends 2FA setup email
3. User enables 2FA (TOTP or email)
4. Login: Email/password → 2FA verification → JWT access + refresh tokens
5. Access token expires in 15 min, refresh via `/auth/refresh-token`

#### Store Authentication
1. Store receives API key during onboarding
2. Employee app stores API key in secure storage
3. All requests include `X-API-Key` header
4. Backend validates against `stores` table + IP whitelist

#### QR Alpha Security
```python
# Token generation (customer app checkout)
payload = {
    'cart_id': cart_id,
    'user_id': user_id,
    'store_id': store_id,
    'exp': time.time() + 300  # 5 min expiry
}
token = jwt.encode(payload, secret_key, algorithm='HS256')

# Redis storage for single-use validation
redis.setex(f'qr_alpha:{token}', 300, json.dumps(payload))
```

```python
# Token validation (checkout POS)
def validate_qr_alpha(token, store_api_key):
    # Verify store authentication
    store = authenticate_store(store_api_key)
    
    # Check Redis (single-use)
    payload = redis.get(f'qr_alpha:{token}')
    if not payload:
        raise InvalidTokenError("Token expired or already used")
    
    # Verify JWT signature
    decoded = jwt.decode(token, secret_key, algorithms=['HS256'])
    
    # Verify store match
    if decoded['store_id'] != store.store_id:
        raise UnauthorizedError("Token not valid for this store")
    
    # Delete token (single-use)
    redis.delete(f'qr_alpha:{token}')
    
    return decoded
```

### Data Encryption
- **At Rest**: PostgreSQL transparent data encryption (TDE) via AWS RDS encryption
- **In Transit**: TLS 1.3 for all API communication
- **Sensitive Fields**: Password hashing via bcrypt (cost factor 12)
- **PII Protection**: Row-level security policies in PostgreSQL

---

## API Integration Patterns

### Checkout POS Integration

#### Store Endpoint Implementation
```python
# Store's existing POS system implements this endpoint
POST /api/cloudfridge/checkout
Headers:
  X-CloudFridge-API-Key: <store_api_key>
  Content-Type: application/json

Request Body:
{
  "qr_alpha_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "register_id": "REG-001",
  "cashier_id": "CSH-123"
}

Response:
{
  "status": "success",
  "cart_id": "a3f2b1c0-...",
  "items": [
    {
      "product_name": "Organic Milk",
      "quantity": 2,
      "unit_price": 4.99,
      "best_before_date": "2026-02-20"
    }
  ],
  "total_amount": 9.98
}
```

#### CloudFridge Backend Adapter
- Supports common POS systems: NCR, Oracle Retail, Square
- Custom adapter layer for store-specific integrations
- Fallback: Manual cart confirmation if POS integration unavailable

---

## Deployment Architecture

### Infrastructure (Kubernetes)

```yaml
# Example deployment for Cart Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cart-service
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: cart-service
        image: freshreminder/cart-service:v1.0
        ports:
        - containerPort: 5000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: postgres-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: redis-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Service Mesh
- API Gateway: Kong / AWS API Gateway
- Load Balancing: Kubernetes Ingress + NGINX
- Service Discovery: Kubernetes DNS
- Monitoring: Prometheus + Grafana
- Logging: ELK Stack (Elasticsearch, Logstash, Kibana)

### Database Scaling
- **Primary**: PostgreSQL (AWS RDS Multi-AZ for high availability)
- **Read Replicas**: 2-3 replicas for analytics queries
- **Redis Cluster**: 3-node cluster with persistence

---

## Development Workflow

### Sprint Structure (2-week sprints)

#### Sprint 1-2: MVP Backend + Auth
- PostgreSQL schema setup
- Flask API scaffold
- JWT authentication + 2FA
- User registration/login endpoints
- Redis session management

#### Sprint 3-4: Product & Cart Services
- Product catalog CRUD
- Barcode lookup
- Cart session management
- QR beta generation logic
- Real-time cart sync (WebSocket or polling)

#### Sprint 5-6: Customer Mobile App (Phase 1)
- Flutter project setup
- Login/registration UI
- QR scanner integration
- Cart screen with real-time updates
- QR alpha generation UI

#### Sprint 7-8: Employee Labeling App
- Barcode scanner UI
- Product lookup/creation
- BBD input + lot number generation
- QR beta label preview
- Zebra printer integration

#### Sprint 9-10: Checkout & CloudFridge
- QR alpha validation endpoint
- POS adapter for pilot store
- Checkout completion flow (cart → fridge)
- Fridge inventory UI
- Manual item addition

#### Sprint 11-12: Notifications & Polish
- FCM push notification setup
- Daily expiry scanner cron job
- Email receipt service
- UI/UX refinements
- End-to-end testing

---

## Testing Strategy

### Unit Testing
- Backend: pytest (Flask services)
- Flutter: flutter_test package
- Target: 80%+ code coverage

### Integration Testing
- API endpoint tests with test database
- Redis session flow tests
- QR token validation tests

### End-to-End Testing
- User flow: Scan → Cart → Checkout → Fridge
- Employee flow: Barcode → Label → Print
- Automated with Selenium/Appium

### Load Testing
- Apache JMeter for API load testing
- Target: 1000 concurrent users, <200ms response time

---

## Monitoring & Observability

### Key Metrics
- **API Performance**: P50, P95, P99 latency per endpoint
- **Error Rates**: 4xx/5xx responses by service
- **Database**: Query performance, connection pool usage
- **Redis**: Cache hit rate, memory usage
- **App Analytics**: DAU/MAU, session length, feature usage

### Alerting
- PagerDuty for critical incidents
- Slack notifications for warnings
- Alerts: API downtime, database connection failures, high error rates

---

## Phase 2 Enhancements (Months 6-12)

### Machine Learning Features
- **Expiry Prediction Model**: Learn user consumption patterns to predict when items will be consumed
- **Personalized Alerts**: Adjust notification timing based on user behavior
- **Smart Recommendations**: Suggest recipes based on expiring items

### Advanced Analytics
- Waste reduction dashboard (money saved, environmental impact)
- Spending insights by category
- Comparison with similar households (anonymized)

### Integrations
- Recipe APIs (Spoonacular, Edamam)
- Voice assistants (Alexa, Google Home)
- Meal kit services (HelloFresh, Blue Apron)

---

## Success Metrics (Technical KPIs)

### Performance
- API response time: <200ms (P95)
- App launch time: <2 seconds
- QR scan speed: <1 second
- Checkout QR validation: <500ms

### Reliability
- Uptime: 99.9%+
- Successful QR alpha validations: >98%
- Failed transaction rate: <2%

### User Engagement
- Weekly active users: 70%+
- Daily fridge checks: 40%+
- Notification open rate: 50%+

---

## Risk Mitigation (Technical)

### POS Integration Complexity
- **Risk**: Many different POS systems
- **Mitigation**: Build generic adapter layer, start with 2-3 common systems, offer manual fallback

### QR Scan Reliability
- **Risk**: Camera quality, lighting conditions affect scan success
- **Mitigation**: Robust QR parsing library, UI guidance for proper scanning, fallback manual entry

### Scalability
- **Risk**: Sudden user growth overwhelms infrastructure
- **Mitigation**: Kubernetes auto-scaling, database read replicas, CDN for static assets, load testing before launch

### Data Privacy Compliance
- **Risk**: GDPR/CCPA violations
- **Mitigation**: Legal review, data export/deletion tools, privacy policy, SOC 2 certification process

---

## Next Steps (30 Days)

1. **Week 1**: Finalize tech stack, set up dev environments, initialize Git repos
2. **Week 2**: Database schema implementation, CI/CD pipeline (GitHub Actions)
3. **Week 3**: Auth service + basic Product service, Flutter project setup
4. **Week 4**: Cart service, QR beta generation, employee app scaffold

**Go time. Let's build FreshReminder.** 🚀
