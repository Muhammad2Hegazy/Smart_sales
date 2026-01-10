// FirebaseInitializer - Disabled for local-only mode
// All data is stored locally in SQLite database, no Firebase needed

class FirebaseInitializer {
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;
  
  // Firebase initialization disabled - using local database only
  static Future<bool> initialize() async {
    // Always return false - Firebase is not used in local-only mode
      _isInitialized = false;
      return false;
  }
}

