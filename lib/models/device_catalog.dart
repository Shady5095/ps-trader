/// قائمة ثابتة بكل موديلات أجهزة PS5 المتاحة في السوق.
/// تُستخدم كقائمة منسدلة عند إضافة صفقة جديدة، بدل كتابة اسم الجهاز يدويًا.
class DeviceModel {
  final String name; // English technical name (matches original sheet style)
  final String storage;
  final String category; // Fat / Slim / Pro
  final String icon; // emoji/icon key used in UI when no photo is attached

  const DeviceModel({
    required this.name,
    required this.storage,
    required this.category,
    this.icon = '🎮',
  });

  String get fullLabel => '$name ($storage)';
}

class DeviceCatalog {
  static const List<DeviceModel> models = [
    DeviceModel(
        name: 'PS5 Fat CD', storage: '825GB', category: 'Fat', icon: '💿'),
    DeviceModel(
        name: 'PS5 Fat Digital', storage: '825GB', category: 'Fat', icon: '📀'),
    DeviceModel(
        name: 'PS5 Slim CD', storage: '1TB', category: 'Slim', icon: '💿'),
    DeviceModel(
        name: 'PS5 Slim Digital', storage: '1TB', category: 'Slim', icon: '📀'),
    DeviceModel(
        name: 'PS5 Slim Digital',
        storage: '825GB',
        category: 'Slim',
        icon: '📀'),
    DeviceModel(
        name: 'PS5 Pro Digital', storage: '2TB', category: 'Pro', icon: '🚀'),
  ];

  static List<String> get allLabels =>
      models.map((m) => m.fullLabel).toList();

  static List<String> get allCategories =>
      models.map((m) => m.category).toSet().toList();

  static String iconFor(String deviceType) {
    final match = models.firstWhere(
      (m) => deviceType.startsWith(m.name) || deviceType == m.fullLabel,
      orElse: () => models.first,
    );
    return match.icon;
  }

  static String assetImageFor(String deviceType) {
    final lower = deviceType.toLowerCase();
    if (lower.contains('pro')) {
      return 'assets/images/pro.png';
    } else if (lower.contains('slim') && lower.contains('digital')) {
      return 'assets/images/slim_digital.png';
    } else if (lower.contains('slim')) {
      return 'assets/images/slim_cd.png';
    } else if (lower.contains('digital')) {
      return 'assets/images/fat_digital.png';
    } else {
      return 'assets/images/fat_cd.png';
    }
  }

  static const List<String> modelCodes = [
    'CFI-1000',
    'CFI-1015',
    'CFI-1016',
    'CFI-1018',
    'CFI-1100',
    'CFI-1115',
    'CFI-1116',
    'CFI-1118',
    'CFI-1200',
    'CFI-1215',
    'CFI-1216',
    'CFI-1218',
    'CFI-2000',
    'CFI-2015',
    'CFI-2016',
    'CFI-2018',
    'CFI-2100',
    'CFI-2115',
    'CFI-2116',
    'CFI-2118',
  ];

  static const List<String> platforms = [
    'Marketplace',
    'Facebook Group',
    'Dubizzle',
  ];
}
