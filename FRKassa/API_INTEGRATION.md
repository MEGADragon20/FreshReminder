# FRKassa - API Service Implementation

This document describes the API integration for the FRKassa mobile app.

## CloudCart Submission

### Endpoint
```
POST {BASE_URL}/api/CloudCart/{cloudCartId}
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
  "products": [
    {
      "name": "Product Name",
      "bestBeforeDate": "2025-12-15",
      "additionalInfo": "Optional additional info"
    }
  ]
}
```

### Response Codes

| Code | Description |
|------|-------------|
| 200 | Cart successfully submitted and stored |
| 400 | Invalid CloudCart ID or malformed data |
| 404 | CloudCart ID not found or expired |
| 500 | Server error |

### Success Response (200)
```json
{
  "status": "success",
  "message": "Products stored successfully",
  "cloudCartId": "unique-cart-id",
  "productCount": 5
}
```

## Implementation Status

- [ ] API endpoint created in backend
- [ ] HTTP client integration in FRKassa
- [ ] Error handling and retry logic
- [ ] Request/response logging
- [ ] Production environment configuration

## Backend Integration Steps

1. Create CloudCart model/endpoint in backend
2. Implement POST `/api/CloudCart/{id}` endpoint
3. Handle product data validation
4. Store products with 24-hour expiration
5. Return success response to app
6. Update FRKassa to make actual API calls (currently simulated)

## Testing

Test the CloudCart endpoint using curl:
```bash
curl -X POST http://localhost:5000/api/CloudCart/test-id \
  -H "Content-Type: application/json" \
  -d '{
    "products": [
      {
        "name": "Milk",
        "bestBeforeDate": "2025-12-15",
        "additionalInfo": "Full Fat 1L"
      }
    ]
  }'
```
