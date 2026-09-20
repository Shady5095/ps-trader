import 'dart:convert';

enum TradeStatus { inStock, sold }

extension TradeStatusX on TradeStatus {
  String get label => this == TradeStatus.sold ? 'تم البيع' : 'متوفر بالمخزن';

  static TradeStatus fromDb(String value) =>
      value == 'SOLD' ? TradeStatus.sold : TradeStatus.inStock;

  String get toDb => this == TradeStatus.sold ? 'SOLD' : 'IN_STOCK';
}

class Trade {
  final String id;
  final String userId;
  final String deviceType;
  final int controllers;
  final int gamesCount;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String sellerNumber;
  final String sellerLocation;
  final String gamesIncluded;
  final String notes;
  final bool hasBox;
  final String modelCode;
  final String serialNumber;
  final String purchasePlatform;
  final String? sellingPlatform;
  final int warrantyMonths;
  final double? deviceSellPrice;
  final double? accessoriesSellPrice;
  final double? sellPrice;
  final DateTime? sellDate;
  final String? buyerNumber;
  final TradeStatus status;
  final List<String> imagePaths;

  String? get imagePath => imagePaths.isNotEmpty ? imagePaths.first : null;

  Trade({
    required this.id,
    this.userId = '',
    required this.deviceType,
    required this.controllers,
    required this.gamesCount,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.sellerNumber,
    required this.sellerLocation,
    required this.gamesIncluded,
    required this.notes,
    this.hasBox = true,
    this.modelCode = '',
    this.serialNumber = '',
    this.purchasePlatform = 'Marketplace',
    this.sellingPlatform,
    this.warrantyMonths = 0,
    double? deviceSellPrice,
    double? accessoriesSellPrice,
    double? sellPrice,
    this.sellDate,
    this.buyerNumber,
    required this.status,
    List<String>? imagePaths,
    String? imagePath,
  })  : deviceSellPrice = deviceSellPrice ?? sellPrice,
        accessoriesSellPrice = accessoriesSellPrice ??
            (deviceSellPrice != null ? 0.0 : null),
        sellPrice = (deviceSellPrice != null || accessoriesSellPrice != null)
            ? ((deviceSellPrice ?? 0) + (accessoriesSellPrice ?? 0))
            : sellPrice,
        imagePaths = imagePaths ??
            (imagePath != null && imagePath.isNotEmpty ? [imagePath] : const []);

  double? get profit {
    if (sellPrice == null) return null;
    return sellPrice! - purchasePrice;
  }

  double? get profitMargin {
    if (profit == null || purchasePrice <= 0) return null;
    return (profit! / purchasePrice) * 100;
  }

  Trade copyWith({
    String? userId,
    String? deviceType,
    int? controllers,
    int? gamesCount,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? sellerNumber,
    String? sellerLocation,
    String? gamesIncluded,
    String? notes,
    bool? hasBox,
    String? modelCode,
    String? serialNumber,
    String? purchasePlatform,
    String? sellingPlatform,
    int? warrantyMonths,
    double? deviceSellPrice,
    double? accessoriesSellPrice,
    double? sellPrice,
    DateTime? sellDate,
    String? buyerNumber,
    TradeStatus? status,
    List<String>? imagePaths,
    String? imagePath,
    bool clearSellPrice = false,
    bool clearSellDate = false,
    bool clearBuyerNumber = false,
    bool clearImage = false,
  }) {
    List<String> newImages;
    if (clearImage) {
      newImages = const [];
    } else if (imagePaths != null) {
      newImages = imagePaths;
    } else if (imagePath != null) {
      newImages = [imagePath];
    } else {
      newImages = this.imagePaths;
    }

    final newDeviceSellPrice = clearSellPrice
        ? null
        : (deviceSellPrice ?? this.deviceSellPrice);
    final newAccSellPrice = clearSellPrice
        ? null
        : (accessoriesSellPrice ?? this.accessoriesSellPrice);
    final newSellPrice = clearSellPrice
        ? null
        : (sellPrice ??
            ((newDeviceSellPrice != null || newAccSellPrice != null)
                ? ((newDeviceSellPrice ?? 0) + (newAccSellPrice ?? 0))
                : this.sellPrice));

    return Trade(
      id: id,
      userId: userId ?? this.userId,
      deviceType: deviceType ?? this.deviceType,
      controllers: controllers ?? this.controllers,
      gamesCount: gamesCount ?? this.gamesCount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellerNumber: sellerNumber ?? this.sellerNumber,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      gamesIncluded: gamesIncluded ?? this.gamesIncluded,
      notes: notes ?? this.notes,
      hasBox: hasBox ?? this.hasBox,
      modelCode: modelCode ?? this.modelCode,
      serialNumber: serialNumber ?? this.serialNumber,
      purchasePlatform: purchasePlatform ?? this.purchasePlatform,
      sellingPlatform: sellingPlatform ?? this.sellingPlatform,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      deviceSellPrice: newDeviceSellPrice,
      accessoriesSellPrice: newAccSellPrice,
      sellPrice: newSellPrice,
      sellDate: clearSellDate ? null : (sellDate ?? this.sellDate),
      buyerNumber: clearBuyerNumber ? null : (buyerNumber ?? this.buyerNumber),
      status: status ?? this.status,
      imagePaths: newImages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'deviceType': deviceType,
      'controllers': controllers,
      'gamesCount': gamesCount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'sellerNumber': sellerNumber,
      'sellerLocation': sellerLocation,
      'gamesIncluded': gamesIncluded,
      'notes': notes,
      'hasBox': hasBox,
      'modelCode': modelCode,
      'serialNumber': serialNumber,
      'purchasePlatform': purchasePlatform,
      'sellingPlatform': sellingPlatform,
      'warrantyMonths': warrantyMonths,
      'deviceSellPrice': deviceSellPrice,
      'accessoriesSellPrice': accessoriesSellPrice,
      'sellPrice': sellPrice,
      'sellDate': sellDate?.toIso8601String(),
      'buyerNumber': buyerNumber,
      'status': status.toDb,
      'imagePaths': imagePaths,
      'imagePath': imagePaths.isEmpty ? null : jsonEncode(imagePaths),
    };
  }

  factory Trade.fromMap(Map<String, dynamic> map) {
    List<String> images = [];
    if (map['imagePaths'] is List) {
      images = (map['imagePaths'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (map['imagePath'] != null) {
      final str = map['imagePath'].toString().trim();
      if (str.isNotEmpty) {
        if (str.startsWith('[') && str.endsWith(']')) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is List) {
              images = decoded
                  .map((e) => e.toString())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          } catch (_) {
            images = [str];
          }
        } else {
          images = [str];
        }
      }
    }

    final rawSellPrice = (map['sellPrice'] as num?)?.toDouble();
    final rawDeviceSellPrice = (map['deviceSellPrice'] as num?)?.toDouble() ?? rawSellPrice;
    final rawAccSellPrice = (map['accessoriesSellPrice'] as num?)?.toDouble() ??
        (rawDeviceSellPrice != null && rawSellPrice != null ? (rawSellPrice - rawDeviceSellPrice) : (rawDeviceSellPrice != null ? 0.0 : null));

    return Trade(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      deviceType: map['deviceType'] as String? ?? '',
      controllers: (map['controllers'] as num?)?.toInt() ?? 0,
      gamesCount: (map['gamesCount'] as num?)?.toInt() ?? 0,
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.parse(map['purchaseDate'] as String)
          : DateTime.now(),
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0,
      sellerNumber: map['sellerNumber'] as String? ?? '',
      sellerLocation: map['sellerLocation'] as String? ?? '',
      gamesIncluded: map['gamesIncluded'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      hasBox: map['hasBox'] as bool? ?? true,
      modelCode: map['modelCode'] as String? ?? '',
      serialNumber: map['serialNumber'] as String? ?? '',
      purchasePlatform: map['purchasePlatform'] as String? ?? 'Marketplace',
      sellingPlatform: map['sellingPlatform'] as String?,
      warrantyMonths: (map['warrantyMonths'] as num?)?.toInt() ?? 0,
      deviceSellPrice: rawDeviceSellPrice,
      accessoriesSellPrice: rawAccSellPrice,
      sellPrice: rawSellPrice,
      sellDate: map['sellDate'] != null
          ? DateTime.parse(map['sellDate'] as String)
          : null,
      buyerNumber: map['buyerNumber'] as String?,
      status: TradeStatusX.fromDb(map['status'] as String? ?? 'IN_STOCK'),
      imagePaths: images,
    );
  }
}
