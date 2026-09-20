/// إعدادات مصادقة Google و Firebase
class AuthConfig {
  /// معرّف العميل للويب (Web Client ID) من Firebase Console:
  /// تجده في Firebase Console -> Authentication -> Sign-in method -> Google -> Web SDK configuration -> Web client ID
  /// (مثال: '224837304509-xxxxxxxxxxxxxx.apps.googleusercontent.com')
  ///
  /// إذا تم تحميل ملف google-services.json المحدث الذي يحتوي على oauth_client (client_type: 3)،
  /// يمكن ترك هذا الحقل فارغاً، وسيتم قراءته تلقائياً.
  static const String serverClientId = '224837304509-po8tr8bhbcnsvctcrhsanht0490uprf2.apps.googleusercontent.com';
}
