/// إعدادات ومفاتيح ربط ImageKit.io
/// يمكنك استخراج هذه المفاتيح من لوحة تحكم ImageKit > Developer Options > API Keys
class ImageKitConfig {
  /// Public API Key
  static const String publicKey = 'public_opKeAFEByjjbZQlfBSi19/KnaFI=';

  /// Private API Key (used for server/direct authenticated upload)
  static const String privateKey = 'private_AnEJUrmKrlchyfpDlVhs+rimS7I=';

  /// URL Endpoint (e.g. 'https://ik.imagekit.io/your_id')
  static const String urlEndpoint = 'https://ik.imagekit.io/ucyzbe9hr';

  /// Upload API Endpoint
  static const String uploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  /// المفاتيح متحطة فوق فعليًا، فالرفع مفعّل دايمًا.
  /// (الفحص القديم كان بيقارن القيم بنفسها فكان دايمًا بيرجع false)
  static const bool isConfigured = true;
}