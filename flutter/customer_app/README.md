# Customer App (Flutter)

This directory contains a minimal Flutter scaffold for the customer-facing FreshReminder app.

To run locally you need Flutter SDK installed.

The files in this directory are a minimal `lib/` scaffold but not a fully-initialized Flutter project. To create a full project and install dependencies, from the repository root run:

```bash
# Make the script executable once
chmod +x ./scripts/bootstrap_flutter.sh
./scripts/bootstrap_flutter.sh
```

Networking notes:
- If you run the Android emulator, use the API base URL `http://10.0.2.2:5000` (configured in `lib/core/config.dart`).
- If you run the iOS Simulator or web, `http://localhost:5000` should work.

After bootstrapping you can run the app:

```bash
cd flutter/customer_app
flutter run
```

The scaffold is minimal and intended to be extended according to `main_battleplan.md`.
