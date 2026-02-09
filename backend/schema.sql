-- PostgreSQL schema for FreshReminder (initial scaffold)

-- Users
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    two_factor_enabled BOOLEAN DEFAULT true,
    two_factor_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stores
CREATE TABLE IF NOT EXISTS stores (
    store_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    ip_whitelist TEXT[],
    location_address TEXT,
    subscription_tier VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE IF NOT EXISTS products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode VARCHAR(50) UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    category VARCHAR(100),
    default_shelf_life_days INTEGER,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ProductLots
CREATE TABLE IF NOT EXISTS product_lots (
    lot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(product_id),
    store_id UUID REFERENCES stores(store_id),
    lot_number VARCHAR(100) NOT NULL,
    best_before_date DATE NOT NULL,
    quantity_available INTEGER DEFAULT 0,
    qr_beta_data TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, lot_number, store_id)
);

-- Carts
CREATE TABLE IF NOT EXISTS carts (
    cart_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    store_id UUID REFERENCES stores(store_id),
    session_token VARCHAR(255) UNIQUE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- CartItems
CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES carts(cart_id) ON DELETE CASCADE,
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FridgeItems
CREATE TABLE IF NOT EXISTS fridge_items (
    fridge_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    product_id UUID REFERENCES products(product_id),
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER DEFAULT 1,
    best_before_date DATE NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    consumed_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE INDEX IF NOT EXISTS idx_fridge_user_status ON fridge_items(user_id, status);
CREATE INDEX IF NOT EXISTS idx_fridge_expiry ON fridge_items(best_before_date) WHERE status = 'active';

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    store_id UUID REFERENCES stores(store_id),
    qr_alpha_token VARCHAR(255),
    total_amount DECIMAL(10,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    receipt_sent BOOLEAN DEFAULT false
);

-- TransactionItems
CREATE TABLE IF NOT EXISTS transaction_items (
    transaction_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    lot_id UUID REFERENCES product_lots(lot_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2)
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    notification_type VARCHAR(50),
    fridge_item_id UUID REFERENCES fridge_items(fridge_item_id),
    message TEXT,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
