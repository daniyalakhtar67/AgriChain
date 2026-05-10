class UserSession {
  static Map<String, dynamic>? _userData;

  static void setUser(Map<String, dynamic> data) => _userData = data;

  static void updateUser(Map<String, dynamic> updates) {
    if (_userData != null) _userData = {..._userData!, ...updates};
  }

  static Map<String, dynamic>? get user      => _userData;
  static bool                   get isLoggedIn => _userData != null;

  // ── new schema field names ──
  static String get id         => _userData?['user_id']      ?? '';
  static String get name       => _userData?['name']         ?? '';
  static String get phone      => _userData?['contact_number'] ?? '';
  static String get location   => _userData?['location']     ?? '';
  static String get userType   => _userData?['user_type']    ?? '';
  static String get cnic       => _userData?['cnic']         ?? '';
  static bool   get isVerified => _userData?['is_verified']  ?? false;

  static void clear() => _userData = null;
}