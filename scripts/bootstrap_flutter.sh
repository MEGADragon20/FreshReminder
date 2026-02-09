#!/usr/bin/env bash
set -euo pipefail

# Bootstrap helper: creates full Flutter projects in the customer_app and employee_app directories
# Usage: from repo root: ./scripts/bootstrap_flutter.sh

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for APP in customer_app employee_app; do
  APP_DIR="$ROOT_DIR/flutter/$APP"
  echo "\nBootstrapping $APP -> $APP_DIR"

  if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter CLI not found. Please install Flutter and ensure \'flutter\' is on PATH." >&2
    exit 2
  fi

  # If pubspec.lock doesn't exist, initialize project
  if [ ! -d "$APP_DIR/android" ] || [ ! -d "$APP_DIR/ios" ]; then
    echo "Running 'flutter create' in $APP_DIR"
    (cd "$APP_DIR" && flutter create .)
  else
    echo "Flutter project already appears to be created for $APP"
  fi

  # Copy local lib content (this will overwrite lib/ files created by flutter)
  if [ -d "$APP_DIR/lib" ]; then
    echo "Copying scaffolded lib/ into project for $APP"
    # assumes this script is run from repo root
    rsync -a --delete "$APP_DIR/" "$APP_DIR/" || true
  fi

  echo "Running 'flutter pub get' for $APP"
  (cd "$APP_DIR" && flutter pub get)
done

echo "\nBootstrap complete. Run the apps with 'flutter run' from each app folder."
