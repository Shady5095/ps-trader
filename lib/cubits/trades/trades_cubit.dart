import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../models/trade.dart';
import '../../services/auth_service.dart';
import '../../services/imagekit_service.dart';
import 'trades_state.dart';

class TradesCubit extends Cubit<TradesState> {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final ImageKitService _imageKitService;
  final _uuid = const Uuid();

  StreamSubscription<QuerySnapshot>? _tradesSubscription;
  StreamSubscription? _authSubscription;

  TradesCubit({
    FirebaseFirestore? firestore,
    AuthService? authService,
    ImageKitService? imageKitService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService.instance,
        _imageKitService = imageKitService ?? ImageKitService.instance,
        super(const TradesInitial()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user == null) {
        _tradesSubscription?.cancel();
        emit(const TradesLoaded([]));
        return;
      }
      _subscribeToUserDevices(user.uid);
    });
  }

  void _subscribeToUserDevices(String uid) {
    _tradesSubscription?.cancel();
    emit(const TradesLoading());

    _tradesSubscription = _firestore
        .collection('devices')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        final List<Trade> items = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          items.add(Trade.fromMap(data));
        }
        items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        emit(TradesLoaded(items));
      },
      onError: (error) {
        debugPrint('Error listening to devices: $error');
        emit(TradesError('تعذر جلب الأجهزة: ${error.toString()}'));
      },
    );
  }

  Future<void> refresh() async {
    final user = _authService.currentUser;
    if (user != null) {
      _subscribeToUserDevices(user.uid);
    }
  }

  /// إضافة جهاز جديد: رفع الصور أولاً إلى ImageKit ثم حفظ المستند في Firestore
  Future<void> addTrade({
    required String deviceType,
    required int controllers,
    required int gamesCount,
    required DateTime purchaseDate,
    required double purchasePrice,
    required String sellerNumber,
    required String sellerLocation,
    required String gamesIncluded,
    required String notes,
    bool hasBox = true,
    String modelCode = '',
    String serialNumber = '',
    String purchasePlatform = 'Marketplace',
    String? sellingPlatform,
    int warrantyMonths = 0,
    List<String>? imagePaths,
    String? imagePath,
  }) async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      throw Exception('يجب تسجيل الدخول أولاً لإضافة جهاز');
    }

    final rawImages =
        imagePaths ?? (imagePath != null ? [imagePath] : const <String>[]);

    // 1. رفع الصور إلى ImageKit داخل مجلد برقم هاتف البائع
    final uploadedUrls = await _imageKitService.uploadMultipleImages(
      filePaths: rawImages,
      sellerNumber: sellerNumber,
    );

    final id = _uuid.v4();
    final trade = Trade(
      id: id,
      userId: currentUserId,
      deviceType: deviceType,
      controllers: controllers,
      gamesCount: gamesCount,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      sellerNumber: sellerNumber,
      sellerLocation: sellerLocation,
      gamesIncluded: gamesIncluded,
      notes: notes,
      hasBox: hasBox,
      modelCode: modelCode,
      serialNumber: serialNumber,
      purchasePlatform: purchasePlatform,
      sellingPlatform: sellingPlatform,
      warrantyMonths: warrantyMonths,
      status: TradeStatus.inStock,
      imagePaths: uploadedUrls,
    );

    // 2. الحفظ في Firestore
    await _firestore.collection('devices').doc(id).set(trade.toMap());
  }

  /// تعديل بيانات جهاز: رفع أي صور محلية جديدة ثم تحديث المستند في Firestore
  Future<void> updateTrade(Trade trade) async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return;

    final uploadedUrls = await _imageKitService.uploadMultipleImages(
      filePaths: trade.imagePaths,
      sellerNumber: trade.sellerNumber,
    );

    final updatedTrade = trade.copyWith(
      userId: currentUserId,
      imagePaths: uploadedUrls,
    );

    await _firestore
        .collection('devices')
        .doc(trade.id)
        .set(updatedTrade.toMap(), SetOptions(merge: true));
  }

  /// تسجيل عملية بيع
  Future<void> markAsSold(
    Trade trade, {
    required double sellPrice,
    double? deviceSellPrice,
    double? accessoriesSellPrice,
    required DateTime sellDate,
    required String buyerNumber,
    String? sellingPlatform,
  }) async {
    final devPrice = deviceSellPrice ?? sellPrice;
    final accPrice = accessoriesSellPrice ?? (sellPrice - devPrice);
    await _firestore.collection('devices').doc(trade.id).update({
      'deviceSellPrice': devPrice,
      'accessoriesSellPrice': accPrice,
      'sellPrice': sellPrice,
      'sellDate': sellDate.toIso8601String(),
      'buyerNumber': buyerNumber,
      if (sellingPlatform != null) 'sellingPlatform': sellingPlatform,
      'status': TradeStatus.sold.toDb,
    });
  }

  /// إرجاع الجهاز إلى المخزن
  Future<void> revertToStock(Trade trade) async {
    await _firestore.collection('devices').doc(trade.id).update({
      'status': TradeStatus.inStock.toDb,
      'deviceSellPrice': null,
      'accessoriesSellPrice': null,
      'sellPrice': null,
      'sellDate': null,
      'buyerNumber': null,
    });
  }

  /// حذف جهاز من Firestore
  Future<void> deleteTrade(String id) async {
    await _firestore.collection('devices').doc(id).delete();
  }

  @override
  Future<void> close() {
    _tradesSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
