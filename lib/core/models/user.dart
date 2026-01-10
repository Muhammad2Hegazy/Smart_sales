class AppUser {
  final String id;
  final String email;
  final String? name;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
  });

  factory AppUser.fromFirebaseUser(dynamic firebaseUser) {
    return AppUser(
      id: firebaseUser.uid as String,
      email: firebaseUser.email as String,
      name: firebaseUser.displayName as String?,
    );
  }

  @Deprecated('Use fromFirebaseUser instead')
  factory AppUser.fromSupabaseUser(dynamic supabaseUser) {
    return AppUser(
      id: supabaseUser.id as String,
      email: supabaseUser.email as String,
      name: supabaseUser.userMetadata?['name'] as String?,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      if (name != null) 'name': name,
    };
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, name: $name)';
  }
}

