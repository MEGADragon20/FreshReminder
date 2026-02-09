/// App configuration values. Automatically chooses a sensible default
/// for Android emulators vs desktop/mobile.
import 'dart:io' show Platform;

class Config {
  /// Returns the API base URL depending on platform.
  /// - Android emulator: use `10.0.2.2` to reach host `localhost`.
  /// - Desktop / iOS simulator / web: use `127.0.0.1` or `localhost`.
  static String get apiBaseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {
      // Platform may not be available on web; fallthrough to localhost
    }
    return 'http://127.0.0.1:5000';
  }
}
