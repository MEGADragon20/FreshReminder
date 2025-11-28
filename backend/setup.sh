#!/bin/bash

# FreshReminder Backend Setup Script
# This script sets up and runs the Flask backend

set -e

echo "======================================="
echo "FreshReminder Backend Setup"
echo "======================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install requirements
echo "Installing dependencies..."
pip install -r requirements.txt --quiet
echo "✓ Dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# FreshReminder Backend Configuration
FLASK_ENV=development
JWT_SECRET_KEY=your-secret-key-change-in-production
DATABASE_URL=sqlite:///freshreminder.db
EOF
    echo "✓ .env file created"
    echo "⚠️  Remember to change JWT_SECRET_KEY for production!"
fi

echo ""
echo "======================================="
echo "✓ Setup complete!"
echo "======================================="
echo ""
echo "To start the server, run:"
echo "  source venv/bin/activate"
echo "  python app.py"
echo ""
echo "Server will be available at:"
echo "  http://localhost:5000"
echo "  API: http://localhost:5000/api"
echo ""
echo "For more information, see SETUP.md"
