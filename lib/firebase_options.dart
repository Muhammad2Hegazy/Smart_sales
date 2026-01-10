// Firebase options - Not used (local database only)
// This file is kept to avoid compilation errors but Firebase is disabled

// Stub class to prevent import errors
class DefaultFirebaseOptions {
  // Firebase is not used - app uses local SQLite database only
  static dynamic get currentPlatform {
    throw UnsupportedError('Firebase is not configured. App uses local database only.');
  }
}
