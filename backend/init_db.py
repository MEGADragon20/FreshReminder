from app import app, db

with app.app_context():
    print("Creating database tables...")
    db.create_all()
    print("✓ Database tables created successfully!")
    print(f"Database file: freshreminder.db")

