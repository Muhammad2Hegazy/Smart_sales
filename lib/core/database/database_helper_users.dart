part of 'database_helper.dart';

extension DatabaseHelperUsers on DatabaseHelper {
  // User Profiles CRUD (Local Auth)
  Future<void> insertUserProfile(UserProfile profile, String passwordHash) async {
    debugPrint('DB: Inserting user profile for ${profile.username}');
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    // Insert user profile
    final profileMap = profile.toMap();
    debugPrint('DB: Profile map: $profileMap');
    batch.insert(
      'user_profiles',
      profileMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insert password hash
    final passwordMap = {
      'user_id': profile.userId,
      'password_hash': passwordHash,
      'created_at': now,
      'updated_at': now,
    };
    debugPrint('DB: Password map (without hash): user_id=${profile.userId}');
    batch.insert(
      'user_passwords',
      passwordMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    await batch.commit(noResult: true);
    debugPrint('DB: User profile and password inserted successfully');
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<UserProfile?> getUserProfileByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<String?> getUserPasswordHash(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['password_hash'] as String?;
  }

  Future<void> updateUserPassword(String userId, String newPasswordHash) async {
    final db = await database;
    // Check if password entry exists
    final existing = await db.query(
      'user_passwords',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (existing.isEmpty) {
      // Insert new password entry
      await db.insert(
        'user_passwords',
        {
          'user_id': userId,
          'password_hash': newPasswordHash,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      // Update existing password
      await db.update(
        'user_passwords',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<List<UserProfile>> getAllUserProfiles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => UserProfile.fromMap(map)).toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    final db = await database;
    await db.update(
      'user_profiles',
      {
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // User Permissions CRUD
  Future<void> insertUserPermission(UserPermission permission) async {
    final db = await database;
    await db.insert(
      'user_permissions',
      {
        'id': permission.id,
        'user_id': permission.userId,
        'permission_key': permission.permissionKey,
        'allowed': permission.allowed ? 1 : 0,
        'created_at': permission.createdAt.toIso8601String(),
        'updated_at': permission.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserPermission>> getUserPermissions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'permission_key',
    );
    return maps.map((map) => UserPermission(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      permissionKey: map['permission_key'] as String,
      allowed: (map['allowed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<List<UserPermission>> getAllUserPermissions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_permissions',
      orderBy: 'user_id, permission_key',
    );
    return maps.map((map) => UserPermission(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      permissionKey: map['permission_key'] as String,
      allowed: (map['allowed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<void> updateUserPermission(String userId, String permissionKey, bool allowed) async {
    final db = await database;
    final uuid = const Uuid();
    final now = DateTime.now();
    
    // Check if permission exists
    final existing = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ?',
      whereArgs: [userId, permissionKey],
      limit: 1,
    );
    
    if (existing.isEmpty) {
      // Insert new permission
      await db.insert(
        'user_permissions',
        {
          'id': uuid.v4(),
          'user_id': userId,
          'permission_key': permissionKey,
          'allowed': allowed ? 1 : 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      );
    } else {
      // Update existing permission
      await db.update(
        'user_permissions',
        {
          'allowed': allowed ? 1 : 0,
          'updated_at': now.toIso8601String(),
        },
        where: 'user_id = ? AND permission_key = ?',
        whereArgs: [userId, permissionKey],
      );
    }
  }

  Future<bool> hasPermission(String userId, String permissionKey) async {
    final db = await database;
    
    // First check if user is admin - admins have all permissions by default
    final profile = await getUserProfile(userId);
    if (profile?.isAdmin == true) {
      return true;
    }
    
    // Check permission in database
    final maps = await db.query(
      'user_permissions',
      where: 'user_id = ? AND permission_key = ? AND allowed = ?',
      whereArgs: [userId, permissionKey, 1],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> adminExists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
