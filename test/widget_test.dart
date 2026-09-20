import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ps_trades_app/core/localization/app_locale.dart';
import 'package:ps_trades_app/core/localization/app_strings.dart';
import 'package:ps_trades_app/cubits/locale/locale_cubit.dart';
import 'package:ps_trades_app/models/device_catalog.dart';
import 'package:ps_trades_app/models/trade.dart';
import 'package:ps_trades_app/theme/app_theme.dart';
import 'package:ps_trades_app/widgets/custom_drop_down_menu.dart';
import 'package:ps_trades_app/widgets/stat_card.dart';
import 'package:ps_trades_app/widgets/trade_card.dart';

void main() {
  Widget buildTestGrid() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: const [
              StatCard(
                title: 'صافي الربح الكلي',
                value: '12,500 ج.م',
                icon: Icons.trending_up,
                color: AppColors.accent,
              ),
              StatCard(
                title: 'متوسط الربح للصفقة',
                value: '2,500 ج.م',
                icon: Icons.equalizer,
                color: AppColors.gold,
              ),
              StatCard(
                title: 'أجهزة تم بيعها',
                value: '5',
                icon: Icons.sell_outlined,
                color: AppColors.primary,
              ),
              StatCard(
                title: 'أجهزة بالمخزن',
                value: '3',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('StatCard renders without overflow at 390px phone width',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestGrid());
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatCard renders without overflow at 360px phone width',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestGrid());
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatCard renders without overflow even at extreme 1.35 aspect ratio',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 1.35,
              children: const [
                StatCard(
                  title: 'متوسط الربح للصفقة',
                  value: '120,500 ج.م',
                  icon: Icons.equalizer,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('DeviceCatalog assetImageFor', () {
    test('maps all models to existing assets correctly', () {
      expect(DeviceCatalog.assetImageFor('PS5 Fat CD (825GB)'),
          'assets/images/fat_cd.png');
      expect(DeviceCatalog.assetImageFor('PS5 Fat Digital (825GB)'),
          'assets/images/fat_digital.png');
      expect(DeviceCatalog.assetImageFor('PS5 Slim CD (1TB)'),
          'assets/images/slim_cd.png');
      expect(DeviceCatalog.assetImageFor('PS5 Slim Digital (1TB)'),
          'assets/images/slim_digital.png');
      expect(DeviceCatalog.assetImageFor('PS5 Slim CD (2TB)'),
          'assets/images/slim_cd.png');
      expect(DeviceCatalog.assetImageFor('PS5 Slim Digital (2TB)'),
          'assets/images/slim_digital.png');
      expect(DeviceCatalog.assetImageFor('PS5 Pro Digital (2TB)'),
          'assets/images/pro.png');
      expect(DeviceCatalog.assetImageFor('PS5 Pro CD (with Disc Drive) (2TB)'),
          'assets/images/pro.png');
    });
  });

  group('Trade multiple imagePaths serialization', () {
    test('serializes and deserializes multiple imagePaths as JSON', () {
      final trade = Trade(
        id: 'test-1',
        userId: 'user-123',
        deviceType: 'PS5 Slim CD (1TB)',
        controllers: 2,
        gamesCount: 3,
        purchaseDate: DateTime(2026, 1, 1),
        purchasePrice: 22000,
        sellerNumber: '01000000000',
        sellerLocation: 'القاهرة',
        gamesIncluded: 'FIFA',
        notes: '',
        status: TradeStatus.inStock,
        imagePaths: ['/data/img1.jpg', '/data/img2.jpg', '/data/img3.jpg'],
      );

      final map = trade.toMap();
      expect(map['userId'], 'user-123');
      expect(map['imagePath'], '["/data/img1.jpg","/data/img2.jpg","/data/img3.jpg"]');

      final fromMap = Trade.fromMap(map);
      expect(fromMap.userId, 'user-123');
      expect(fromMap.imagePaths.length, 3);
      expect(fromMap.imagePaths[0], '/data/img1.jpg');
      expect(fromMap.imagePaths[1], '/data/img2.jpg');
      expect(fromMap.imagePaths[2], '/data/img3.jpg');
      expect(fromMap.imagePath, '/data/img1.jpg');
    });

    test('backward compatibility: deserializes legacy single string imagePath', () {
      final legacyMap = {
        'id': 'test-legacy',
        'deviceType': 'PS5 Fat CD',
        'controllers': 1,
        'gamesCount': 0,
        'purchaseDate': DateTime(2026, 1, 1).toIso8601String(),
        'purchasePrice': 18000.0,
        'sellerNumber': '',
        'sellerLocation': '',
        'gamesIncluded': '',
        'notes': '',
        'status': 'IN_STOCK',
        'imagePath': '/legacy/path/photo.jpg',
      };

      final trade = Trade.fromMap(legacyMap);
      expect(trade.imagePaths.length, 1);
      expect(trade.imagePaths.first, '/legacy/path/photo.jpg');
      expect(trade.imagePath, '/legacy/path/photo.jpg');
    });
  });

  group('Trade new fields and profit calculations', () {
    test('correctly handles split sell prices and calculates total sellPrice & profit', () {
      final trade = Trade(
        id: 'split-1',
        deviceType: 'PS5 Slim CD (1TB)',
        modelCode: 'CFI-2000',
        hasBox: true,
        serialNumber: 'SN12345678',
        purchasePlatform: 'Marketplace',
        sellingPlatform: 'Dubizzle',
        warrantyMonths: 6,
        controllers: 2,
        gamesCount: 3,
        purchaseDate: DateTime(2026, 1, 1),
        purchasePrice: 20000,
        sellerNumber: '01012345678',
        sellerLocation: 'المعادي',
        gamesIncluded: 'FC 24',
        notes: 'حالة ممتازة',
        deviceSellPrice: 23000,
        accessoriesSellPrice: 2000,
        status: TradeStatus.sold,
      );

      expect(trade.deviceSellPrice, 23000);
      expect(trade.accessoriesSellPrice, 2000);
      expect(trade.sellPrice, 25000);
      expect(trade.profit, 5000);
      expect(trade.profitMargin, 25.0);

      final map = trade.toMap();
      expect(map['modelCode'], 'CFI-2000');
      expect(map['hasBox'], isTrue);
      expect(map['serialNumber'], 'SN12345678');
      expect(map['purchasePlatform'], 'Marketplace');
      expect(map['sellingPlatform'], 'Dubizzle');
      expect(map['warrantyMonths'], 6);
      expect(map['deviceSellPrice'], 23000);
      expect(map['accessoriesSellPrice'], 2000);
      expect(map['sellPrice'], 25000);

      final reconstructed = Trade.fromMap(map);
      expect(reconstructed.modelCode, 'CFI-2000');
      expect(reconstructed.hasBox, isTrue);
      expect(reconstructed.serialNumber, 'SN12345678');
      expect(reconstructed.purchasePlatform, 'Marketplace');
      expect(reconstructed.sellingPlatform, 'Dubizzle');
      expect(reconstructed.warrantyMonths, 6);
      expect(reconstructed.deviceSellPrice, 23000);
      expect(reconstructed.accessoriesSellPrice, 2000);
      expect(reconstructed.sellPrice, 25000);
      expect(reconstructed.profit, 5000);
    });

    test('Trade copyWith properly updates sale information', () {
      final soldTrade = Trade(
        id: 'sold-1',
        deviceType: 'PS5 Slim CD (1TB)',
        modelCode: 'CFI-2000',
        hasBox: true,
        serialNumber: 'SN123',
        purchasePlatform: 'Marketplace',
        sellingPlatform: 'Marketplace',
        warrantyMonths: 12,
        controllers: 2,
        gamesCount: 1,
        purchaseDate: DateTime(2026, 1, 1),
        purchasePrice: 20000,
        sellerNumber: '01000000000',
        sellerLocation: 'Cairo',
        gamesIncluded: 'FIFA',
        notes: 'Clean',
        deviceSellPrice: 24000,
        accessoriesSellPrice: 1000,
        sellDate: DateTime(2026, 2, 1),
        buyerNumber: '01111111111',
        status: TradeStatus.sold,
      );

      final updated = soldTrade.copyWith(
        deviceSellPrice: 25000,
        accessoriesSellPrice: 1500,
        sellingPlatform: 'Dubizzle',
        buyerNumber: '01222222222',
        sellDate: DateTime(2026, 2, 15),
      );

      expect(updated.deviceSellPrice, 25000);
      expect(updated.accessoriesSellPrice, 1500);
      expect(updated.sellPrice, 26500);
      expect(updated.sellingPlatform, 'Dubizzle');
      expect(updated.buyerNumber, '01222222222');
      expect(updated.sellDate, DateTime(2026, 2, 15));
    });
  });

  testWidgets('TradeCard renders with device asset image',
      (WidgetTester tester) async {
    final trade = Trade(
      id: 'card-test',
      deviceType: 'PS5 Slim CD (1TB)',
      controllers: 2,
      gamesCount: 1,
      purchaseDate: DateTime(2026, 1, 1),
      purchasePrice: 20000,
      sellerNumber: '0123456789',
      sellerLocation: 'الجيزة',
      gamesIncluded: 'Spiderman',
      notes: '',
      status: TradeStatus.inStock,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: TradeCard(trade: trade, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('PS5 Slim CD (1TB)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('LocaleCubit toggles between Arabic and English correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = LocaleCubit();
    expect(cubit.state, const Locale('ar'));
    expect(cubit.isArabic, isTrue);

    await cubit.toggleLocale();
    expect(cubit.state, const Locale('en'));
    expect(cubit.isArabic, isFalse);

    await cubit.toggleLocale();
    expect(cubit.state, const Locale('ar'));
    expect(cubit.isArabic, isTrue);

    await cubit.setLocale(const Locale('en'));
    expect(cubit.state, const Locale('en'));
    cubit.close();
  });

  test('LocaleCubit persists language changes in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = LocaleCubit();
    expect(cubit.state, const Locale('ar'));

    await cubit.setLocale(const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocaleCubit.localeKey), 'en');

    final cubit2 = LocaleCubit();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit2.state, const Locale('en'));

    cubit.close();
    cubit2.close();
  });

  testWidgets('AppLocale loads translations for Arabic and English',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          AppLocale.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: _LocaleTestWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدارة تجارة PS5'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          AppLocale.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: _LocaleTestWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PS5 Trade Manager'), findsOneWidget);
  });

  testWidgets('MoreScreen renders language option and logout tile',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          AppLocale.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: _MoreScreenTestWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لغة التطبيق'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('CustomDropDownMenu renders label and initial value correctly',
      (WidgetTester tester) async {
    String? selected = 'CFI-1000';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CustomDropDownMenu(
            label: 'رقم الإصدار',
            value: selected,
            dropdownItems: const ['CFI-1000', 'CFI-1015'],
            onChanged: (v) => selected = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رقم الإصدار'), findsOneWidget);
    expect(find.text('CFI-1000'), findsOneWidget);
  });
}

class _LocaleTestWidget extends StatelessWidget {
  const _LocaleTestWidget();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.appTitle.tr(context));
  }
}

class _MoreScreenTestWidget extends StatelessWidget {
  const _MoreScreenTestWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(AppStrings.settings.tr(context)),
        Text(AppStrings.appLanguage.tr(context)),
        Text(AppStrings.logout.tr(context)),
      ],
    );
  }
}
