/// User Profile Model
/// Represents a user's profile information including username and role
class UserProfile {
  final String userId; // UUID from auth.users
  final String username; // Username (not email)
  final String role; // 'admin' or 'user'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Map (Database response)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return UserProfile(
      userId: (map['user_id'] ?? map['id'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at'] ?? map['created_at']),
    );
  }

  /// Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'username': username,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? username,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, role: $role)';
  }
}

/// Username to Email Converter
/// Converts username to email format for Supabase Auth
class UsernameEmailConverter {
  static const String _emailDomain = '@app.local';

  /// Convert username to email
  static String usernameToEmail(String username) {
    return '$username$_emailDomain';
  }

  /// Extract username from email (if it's in our format)
  static String? emailToUsername(String email) {
    if (email.endsWith(_emailDomain)) {
      return email.substring(0, email.length - _emailDomain.length);
    }
    return null;
  }
}
