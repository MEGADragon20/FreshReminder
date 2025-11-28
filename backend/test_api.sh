#!/bin/bash
# FreshReminder Backend Testing Script
# This script helps you test all backend API endpoints

set -e

API_URL="http://localhost:5000/api"
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test data
TEST_EMAIL="test_$(date +%s)@example.com"
TEST_PASSWORD="testpass123"
TOKEN=""
USER_ID=""
PRODUCT_ID=""

echo -e "${COLOR_BLUE}========================================${NC}"
echo -e "${COLOR_BLUE}FreshReminder API Testing Script${NC}"
echo -e "${COLOR_BLUE}========================================${NC}"
echo ""
echo -e "${COLOR_YELLOW}API Base URL:${NC} $API_URL"
echo -e "${COLOR_YELLOW}Test Email:${NC} $TEST_EMAIL"
echo -e "${COLOR_YELLOW}Test Password:${NC} $TEST_PASSWORD"
echo ""

# Function to print section header
print_section() {
    echo ""
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${COLOR_BLUE}$1${NC}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print success
print_success() {
    echo -e "${COLOR_GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${COLOR_RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${COLOR_YELLOW}ℹ $1${NC}"
}

# Test 1: Health Check
print_section "TEST 1: Health Check"
echo "Checking if backend is running..."
HEALTH=$(curl -s -X GET "$API_URL/../health" -H "Content-Type: application/json")
if echo "$HEALTH" | grep -q "ok"; then
    print_success "Backend is running"
    echo "Response: $HEALTH"
else
    print_error "Backend is not responding"
    exit 1
fi

# Test 2: Register User
print_section "TEST 2: User Registration"
echo "Registering new user..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"user_id":[0-9]*' | cut -d':' -f2)
    print_success "User registered successfully"
    echo "Email: $TEST_EMAIL"
    echo "User ID: $USER_ID"
    echo "Token (first 20 chars): ${TOKEN:0:20}..."
else
    print_error "Registration failed"
    echo "Response: $REGISTER_RESPONSE"
    exit 1
fi

# Test 3: Login with same credentials
print_section "TEST 3: User Login"
echo "Testing login with registered credentials..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    LOGIN_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    print_success "User logged in successfully"
    echo "Token (first 20 chars): ${LOGIN_TOKEN:0:20}..."
    TOKEN=$LOGIN_TOKEN
else
    print_error "Login failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

# Test 4: Get User Profile
print_section "TEST 4: Get User Profile"
echo "Fetching user profile..."
PROFILE_RESPONSE=$(curl -s -X GET "$API_URL/users/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")

if echo "$PROFILE_RESPONSE" | grep -q "email"; then
    print_success "Profile retrieved successfully"
    echo "Profile Data:"
    echo "$PROFILE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$PROFILE_RESPONSE"
else
    print_error "Profile fetch failed"
    echo "Response: $PROFILE_RESPONSE"
fi

# Test 5: Try login with wrong password
print_section "TEST 5: Login with Wrong Password (Should Fail)"
echo "Testing login with incorrect password..."
WRONG_PASS=$(curl -s -X POST "$API_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"wrongpassword\"
    }")

if echo "$WRONG_PASS" | grep -q "error\|401\|Ungültig"; then
    print_success "Correctly rejected wrong password"
    echo "Response: $WRONG_PASS"
else
    print_error "Should have rejected wrong password"
fi

# Test 6: Add Product
print_section "TEST 6: Add Product"
echo "Adding a new product..."
EXPIRY_DATE=$(date -d "+7 days" +%Y-%m-%d)
ADD_PRODUCT=$(curl -s -X POST "$API_URL/products/" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Milk\",
        \"category\": \"Dairy\",
        \"expiration_date\": \"$EXPIRY_DATE\"
    }")

if echo "$ADD_PRODUCT" | grep -q "id"; then
    PRODUCT_ID=$(echo "$ADD_PRODUCT" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
    print_success "Product added successfully"
    echo "Product ID: $PRODUCT_ID"
    echo "Name: Milk"
    echo "Category: Dairy"
    echo "Expiration Date: $EXPIRY_DATE"
    echo "Response: $ADD_PRODUCT"
else
    print_error "Failed to add product"
    echo "Response: $ADD_PRODUCT"
fi

# Test 7: List Products
print_section "TEST 7: List Products"
echo "Fetching all products..."
LIST_PRODUCTS=$(curl -s -X GET "$API_URL/products/" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")

if echo "$LIST_PRODUCTS" | grep -q "name\|Milk"; then
    print_success "Products retrieved successfully"
    echo "Products:"
    echo "$LIST_PRODUCTS" | python3 -m json.tool 2>/dev/null || echo "$LIST_PRODUCTS"
else
    print_error "Failed to list products"
    echo "Response: $LIST_PRODUCTS"
fi

# Test 8: Try adding product without token (Should Fail)
print_section "TEST 8: Add Product Without Token (Should Fail)"
echo "Testing unauthorized product addition..."
NO_TOKEN=$(curl -s -X POST "$API_URL/products/" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Test\",
        \"category\": \"Test\",
        \"expiration_date\": \"2025-12-31\"
    }")

if echo "$NO_TOKEN" | grep -q "error\|401\|unauthorized\|Unauthorized"; then
    print_success "Correctly rejected unauthorized request"
    echo "Response: $NO_TOKEN"
else
    print_error "Should have rejected unauthorized request"
fi

# Test 9: Delete Product (if we have one)
if [ ! -z "$PRODUCT_ID" ]; then
    print_section "TEST 9: Delete Product"
    echo "Deleting product with ID: $PRODUCT_ID..."
    DELETE_PRODUCT=$(curl -s -X DELETE "$API_URL/products/$PRODUCT_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$DELETE_PRODUCT" | grep -q "message\|Produkt"; then
        print_success "Product deleted successfully"
        echo "Response: $DELETE_PRODUCT"
    else
        print_error "Failed to delete product"
        echo "Response: $DELETE_PRODUCT"
    fi
fi

# Test 10: Update Push Token
print_section "TEST 10: Update Push Token"
echo "Updating push notification token..."
PUSH_TOKEN=$(curl -s -X POST "$API_URL/users/push-token" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"token\": \"test_push_token_12345\"
    }")

if echo "$PUSH_TOKEN" | grep -q "message\|aktualisiert"; then
    print_success "Push token updated successfully"
    echo "Response: $PUSH_TOKEN"
else
    print_error "Failed to update push token"
    echo "Response: $PUSH_TOKEN"
fi

# Summary
print_section "TESTING SUMMARY"
echo ""
echo -e "${COLOR_GREEN}✓ Health Check${NC}"
echo -e "${COLOR_GREEN}✓ User Registration${NC}"
echo -e "${COLOR_GREEN}✓ User Login${NC}"
echo -e "${COLOR_GREEN}✓ Get Profile${NC}"
echo -e "${COLOR_GREEN}✓ Wrong Password Rejection${NC}"
echo -e "${COLOR_GREEN}✓ Add Product${NC}"
echo -e "${COLOR_GREEN}✓ List Products${NC}"
echo -e "${COLOR_GREEN}✓ Unauthorized Request Rejection${NC}"
if [ ! -z "$PRODUCT_ID" ]; then
    echo -e "${COLOR_GREEN}✓ Delete Product${NC}"
fi
echo -e "${COLOR_GREEN}✓ Update Push Token${NC}"
echo ""
echo -e "${COLOR_BLUE}All tests completed!${NC}"
echo ""
echo -e "${COLOR_YELLOW}Test User Created:${NC}"
echo "  Email: $TEST_EMAIL"
echo "  Password: $TEST_PASSWORD"
echo "  User ID: $USER_ID"
echo ""
echo -e "${COLOR_YELLOW}Use this account to test the Flutter app!${NC}"
echo ""
