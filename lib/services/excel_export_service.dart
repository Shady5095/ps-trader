import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/trade.dart';
import 'stats_service.dart';

class ExcelExportService {
  const ExcelExportService();

  /// Generates the Excel bytes with [Trades] and [Summary] sheets
  List<int> generateExcelBytes(List<Trade> trades) {
    final workbook = xlsio.Workbook(2);

    final tradesSheet = workbook.worksheets[0];
    tradesSheet.name = 'Trades';

    final summarySheet = workbook.worksheets[1];
    summarySheet.name = 'Summary';

    _setupTradesSheet(workbook, tradesSheet, trades);
    _setupSummarySheet(workbook, summarySheet, trades);

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  /// Builds the 'Trades' worksheet styled identically to the user's template
  void _setupTradesSheet(
    xlsio.Workbook workbook,
    xlsio.Worksheet sheet,
    List<Trade> trades,
  ) {
    final headers = [
      'Device Type',
      'Version Number',
      'Box Availabilty',
      'Device Condition',
      'Controllers',
      'Games Count',
      'Remaining Warranty',
      'Purchase Date',
      'Purchase Price',
      'Seller Number',
      'Seller Location',
      'Games Included',
      'Notes',
      'Sell Price',
      'Sell Date',
      'Buyer Number',
      'Serial No',
      'Purchase Platform',
      'Selling Platform',
      'Profit',
      'Status',
    ];

    const fontName = 'Arial';

    // 1. Header Style: Deep Dark Navy Blue with White Bold Text
    final headerStyle = workbook.styles.add('TradesHeaderStyle');
    headerStyle.fontName = fontName;
    headerStyle.fontSize = 10.5;
    headerStyle.bold = true;
    headerStyle.backColor = '#1F2D3D';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    headerStyle.borders.all.color = '#1F2D3D';

    // 2. Sold Row Styles (Light Soft Mint Green: #E6F4EA)
    const soldBgColor = '#E6F4EA';
    const borderColor = '#D9D9D9';

    final soldLeft = workbook.styles.add('SoldLeft');
    soldLeft.fontName = fontName;
    soldLeft.fontSize = 10;
    soldLeft.backColor = soldBgColor;
    soldLeft.vAlign = xlsio.VAlignType.center;
    soldLeft.hAlign = xlsio.HAlignType.left;
    soldLeft.borders.all.lineStyle = xlsio.LineStyle.thin;
    soldLeft.borders.all.color = borderColor;

    final soldCenter = workbook.styles.add('SoldCenter');
    soldCenter.fontName = fontName;
    soldCenter.fontSize = 10;
    soldCenter.backColor = soldBgColor;
    soldCenter.vAlign = xlsio.VAlignType.center;
    soldCenter.hAlign = xlsio.HAlignType.center;
    soldCenter.borders.all.lineStyle = xlsio.LineStyle.thin;
    soldCenter.borders.all.color = borderColor;

    final soldRight = workbook.styles.add('SoldRight');
    soldRight.fontName = fontName;
    soldRight.fontSize = 10;
    soldRight.backColor = soldBgColor;
    soldRight.vAlign = xlsio.VAlignType.center;
    soldRight.hAlign = xlsio.HAlignType.right;
    soldRight.borders.all.lineStyle = xlsio.LineStyle.thin;
    soldRight.borders.all.color = borderColor;

    final soldStatus = workbook.styles.add('SoldStatus');
    soldStatus.fontName = fontName;
    soldStatus.fontSize = 10;
    soldStatus.bold = true;
    soldStatus.backColor = soldBgColor;
    soldStatus.vAlign = xlsio.VAlignType.center;
    soldStatus.hAlign = xlsio.HAlignType.center;
    soldStatus.borders.all.lineStyle = xlsio.LineStyle.thin;
    soldStatus.borders.all.color = borderColor;

    // 3. In-Stock Row Styles (Light Soft Yellow: #FFF2CC)
    const inStockBgColor = '#FFF2CC';

    final inStockLeft = workbook.styles.add('InStockLeft');
    inStockLeft.fontName = fontName;
    inStockLeft.fontSize = 10;
    inStockLeft.backColor = inStockBgColor;
    inStockLeft.vAlign = xlsio.VAlignType.center;
    inStockLeft.hAlign = xlsio.HAlignType.left;
    inStockLeft.borders.all.lineStyle = xlsio.LineStyle.thin;
    inStockLeft.borders.all.color = borderColor;

    final inStockCenter = workbook.styles.add('InStockCenter');
    inStockCenter.fontName = fontName;
    inStockCenter.fontSize = 10;
    inStockCenter.backColor = inStockBgColor;
    inStockCenter.vAlign = xlsio.VAlignType.center;
    inStockCenter.hAlign = xlsio.HAlignType.center;
    inStockCenter.borders.all.lineStyle = xlsio.LineStyle.thin;
    inStockCenter.borders.all.color = borderColor;

    final inStockRight = workbook.styles.add('InStockRight');
    inStockRight.fontName = fontName;
    inStockRight.fontSize = 10;
    inStockRight.backColor = inStockBgColor;
    inStockRight.vAlign = xlsio.VAlignType.center;
    inStockRight.hAlign = xlsio.HAlignType.right;
    inStockRight.borders.all.lineStyle = xlsio.LineStyle.thin;
    inStockRight.borders.all.color = borderColor;

    final inStockStatus = workbook.styles.add('InStockStatus');
    inStockStatus.fontName = fontName;
    inStockStatus.fontSize = 10;
    inStockStatus.bold = true;
    inStockStatus.backColor = inStockBgColor;
    inStockStatus.vAlign = xlsio.VAlignType.center;
    inStockStatus.hAlign = xlsio.HAlignType.center;
    inStockStatus.borders.all.lineStyle = xlsio.LineStyle.thin;
    inStockStatus.borders.all.color = borderColor;

    // Write headers
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(1, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeightInPixels(1, 28);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat('#,##0');

    String formatMoney(double? val) {
      if (val == null) return '—';
      return '${currencyFormat.format(val)} EGP';
    }

    // Write trade rows
    for (int i = 0; i < trades.length; i++) {
      final t = trades[i];
      final r = i + 2;
      final isSold = (t.status == TradeStatus.sold);

      final styleLeft = isSold ? soldLeft : inStockLeft;
      final styleCenter = isSold ? soldCenter : inStockCenter;
      final styleRight = isSold ? soldRight : inStockRight;
      final styleStatus = isSold ? soldStatus : inStockStatus;

      // 1. Device Type
      _setText(sheet, r, 1, t.deviceType, styleLeft);

      // 2. Version Number
      _setText(sheet, r, 2, t.modelCode.isNotEmpty ? t.modelCode : '—', styleCenter);

      // 3. Box Availabilty
      _setText(sheet, r, 3, t.hasBox ? 'يوجد' : 'لا يوجد', styleCenter);

      // 4. Device Condition (1 to 3)
      _setText(
        sheet,
        r,
        4,
        t.conditionRating > 0 ? '${t.conditionRating}' : '—',
        styleCenter,
      );

      // 5. Controllers
      _setText(sheet, r, 5, '${t.controllers}', styleCenter);

      // 6. Games Count
      final count = t.games.isNotEmpty ? t.games.length : t.gamesCount;
      _setText(sheet, r, 6, '$count', styleCenter);

      // 7. Remaining Warranty
      _setText(
        sheet,
        r,
        7,
        t.warrantyMonths > 0 ? '${t.warrantyMonths} شهر' : 'لا يوجد',
        styleCenter,
      );

      // 8. Purchase Date
      _setText(sheet, r, 8, dateFormat.format(t.purchaseDate), styleCenter);

      // 9. Purchase Price (e.g. 30,000 EGP)
      _setText(sheet, r, 9, formatMoney(t.purchasePrice), styleRight);

      // 10. Seller Number
      _setText(sheet, r, 10, t.sellerNumber.isNotEmpty ? t.sellerNumber : '—', styleCenter);

      // 11. Seller Location
      _setText(sheet, r, 11, t.sellerLocation.isNotEmpty ? t.sellerLocation : '—', styleLeft);

      // 12. Games Included
      final gamesText = t.games.isNotEmpty
          ? t.games.map((g) => g.name).join(', ')
          : (t.gamesIncluded.isNotEmpty ? t.gamesIncluded : '—');
      _setText(sheet, r, 12, gamesText, styleLeft);

      // 13. Notes
      _setText(sheet, r, 13, t.notes.isNotEmpty ? t.notes : '—', styleLeft);

      // 14. Sell Price (e.g. 32,500 EGP)
      _setText(sheet, r, 14, isSold ? formatMoney(t.sellPrice) : '—', styleRight);

      // 15. Sell Date
      _setText(sheet, r, 15, t.sellDate != null ? dateFormat.format(t.sellDate!) : '—', styleCenter);

      // 16. Buyer Number
      _setText(sheet, r, 16, t.buyerNumber != null && t.buyerNumber!.isNotEmpty ? t.buyerNumber! : '—', styleCenter);

      // 17. Serial No
      _setText(sheet, r, 17, t.serialNumber.isNotEmpty ? t.serialNumber : '—', styleCenter);

      // 18. Purchase Platform
      _setText(sheet, r, 18, t.purchasePlatform.isNotEmpty ? t.purchasePlatform : '—', styleCenter);

      // 19. Selling Platform
      _setText(sheet, r, 19, t.sellingPlatform != null && t.sellingPlatform!.isNotEmpty ? t.sellingPlatform! : '—', styleCenter);

      // 20. Profit (e.g. 5,000 EGP)
      _setText(sheet, r, 20, isSold ? formatMoney(t.profit) : '—', styleRight);

      // 21. Status (SOLD / IN STOCK)
      _setText(sheet, r, 21, isSold ? 'SOLD' : 'IN STOCK', styleStatus);

      sheet.setRowHeightInPixels(r, 22);
    }

    // Auto-fit all 20 columns
    for (int col = 1; col <= headers.length; col++) {
      sheet.autoFitColumn(col);
    }
  }

  /// Builds the 'Summary' worksheet with metrics, monthly profit, and device distribution
  void _setupSummarySheet(
    xlsio.Workbook workbook,
    xlsio.Worksheet sheet,
    List<Trade> trades,
  ) {
    final stats = StatsService(trades);
    const fontName = 'Arial';
    final currencyFormat = NumberFormat('#,##0');

    final titleStyle = workbook.styles.add('SummaryTitleStyle');
    titleStyle.fontName = fontName;
    titleStyle.bold = true;
    titleStyle.fontSize = 13;
    titleStyle.backColor = '#1F2D3D';
    titleStyle.fontColor = '#FFFFFF';
    titleStyle.hAlign = xlsio.HAlignType.center;
    titleStyle.vAlign = xlsio.VAlignType.center;

    final sectionHeaderStyle = workbook.styles.add('SummarySectionHeader');
    sectionHeaderStyle.fontName = fontName;
    sectionHeaderStyle.bold = true;
    sectionHeaderStyle.fontSize = 10.5;
    sectionHeaderStyle.backColor = '#1F2D3D';
    sectionHeaderStyle.fontColor = '#FFFFFF';
    sectionHeaderStyle.hAlign = xlsio.HAlignType.center;
    sectionHeaderStyle.vAlign = xlsio.VAlignType.center;
    sectionHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    sectionHeaderStyle.borders.all.color = '#1F2D3D';

    final labelStyle = workbook.styles.add('SummaryLabel');
    labelStyle.fontName = fontName;
    labelStyle.fontSize = 10;
    labelStyle.bold = true;
    labelStyle.backColor = '#F4F6F8';
    labelStyle.vAlign = xlsio.VAlignType.center;
    labelStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    labelStyle.borders.all.color = '#D9D9D9';

    final valueStyle = workbook.styles.add('SummaryValue');
    valueStyle.fontName = fontName;
    valueStyle.fontSize = 10;
    valueStyle.bold = true;
    valueStyle.hAlign = xlsio.HAlignType.right;
    valueStyle.vAlign = xlsio.VAlignType.center;
    valueStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    valueStyle.borders.all.color = '#D9D9D9';

    final centerStyle = workbook.styles.add('SummaryCenter');
    centerStyle.fontName = fontName;
    centerStyle.fontSize = 10;
    centerStyle.hAlign = xlsio.HAlignType.center;
    centerStyle.vAlign = xlsio.VAlignType.center;
    centerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    centerStyle.borders.all.color = '#D9D9D9';

    final lightRowStyle = workbook.styles.add('SummaryLightRow');
    lightRowStyle.fontName = fontName;
    lightRowStyle.fontSize = 10;
    lightRowStyle.hAlign = xlsio.HAlignType.right;
    lightRowStyle.vAlign = xlsio.VAlignType.center;
    lightRowStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    lightRowStyle.borders.all.color = '#D9D9D9';

    int currentRow = 1;

    // --- Section 1: Title ---
    final titleRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
    titleRange.merge();
    titleRange.setText('ملخص الأداء العام والمؤشرات المالية (PS Trader Summary)');
    titleRange.cellStyle = titleStyle;
    sheet.setRowHeightInPixels(currentRow, 32);
    currentRow += 2;

    // --- Section 2: Key Business Metrics ---
    final totalSalesRevenue = trades
        .where((t) => t.status == TradeStatus.sold && t.sellPrice != null)
        .fold(0.0, (sum, t) => sum + (t.sellPrice ?? 0));

    final metrics = [
      ['إجمالي الأرباح الصافية (Total Net Profit)', '${currencyFormat.format(stats.totalProfit)} EGP'],
      ['عدد الأجهزة المباعة (Sold Devices)', '${stats.soldCount}'],
      ['الأجهزة المتوفرة بالمخزن (In-Stock Devices)', '${stats.inStockCount}'],
      ['متوسط الربح لكل صفقة (Average Profit Per Deal)', '${currencyFormat.format(stats.averageProfit)} EGP'],
      ['إجمالي رأس المال المستثمر (Total Capital Invested)', '${currencyFormat.format(stats.totalInvested)} EGP'],
      ['إجمالي عوائد المبيعات (Total Sales Revenue)', '${currencyFormat.format(totalSalesRevenue)} EGP'],
    ];

    final metricsHeader = sheet.getRangeByIndex(currentRow, 1, currentRow, 2);
    metricsHeader.merge();
    metricsHeader.setText('المؤشرات العامة (Key Metrics)');
    metricsHeader.cellStyle = sectionHeaderStyle;
    sheet.setRowHeightInPixels(currentRow, 24);
    currentRow++;

    for (final m in metrics) {
      final lblCell = sheet.getRangeByIndex(currentRow, 1);
      lblCell.setText(m[0]);
      lblCell.cellStyle = labelStyle;

      final valCell = sheet.getRangeByIndex(currentRow, 2);
      valCell.setText(m[1]);
      valCell.cellStyle = valueStyle;

      sheet.setRowHeightInPixels(currentRow, 22);
      currentRow++;
    }

    currentRow += 2;

    // --- Section 3: Monthly Profit Breakdown (أرباح كل شهر) ---
    final monthlyHeader = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
    monthlyHeader.merge();
    monthlyHeader.setText('أرباح كل شهر (Monthly Profit Breakdown)');
    monthlyHeader.cellStyle = sectionHeaderStyle;
    sheet.setRowHeightInPixels(currentRow, 24);
    currentRow++;

    final monthColHeaders = [
      'الشهر / السنة (Month)',
      'الأجهزة المباعة (Sold)',
      'إجمالي المبيعات (Sales)',
      'صافي الأرباح (Net Profit)',
    ];
    for (int c = 0; c < monthColHeaders.length; c++) {
      final cell = sheet.getRangeByIndex(currentRow, c + 1);
      cell.setText(monthColHeaders[c]);
      cell.cellStyle = sectionHeaderStyle;
    }
    sheet.setRowHeightInPixels(currentRow, 24);
    currentRow++;

    final Map<String, _MonthSummary> monthlyData = {};
    for (final t in trades) {
      if (t.status != TradeStatus.sold || t.sellDate == null) continue;
      final key = DateFormat('yyyy-MM').format(t.sellDate!);
      final item = monthlyData.putIfAbsent(key, () => _MonthSummary(key));
      item.soldCount += 1;
      item.totalSales += (t.sellPrice ?? 0);
      item.netProfit += (t.profit ?? 0);
    }

    final sortedMonths = monthlyData.values.toList()
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));

    if (sortedMonths.isEmpty) {
      final emptyCell = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
      emptyCell.merge();
      emptyCell.setText('لا توجد مبيعات مسجلة حتى الآن');
      emptyCell.cellStyle = centerStyle;
      sheet.setRowHeightInPixels(currentRow, 22);
      currentRow++;
    } else {
      for (final m in sortedMonths) {
        _setText(sheet, currentRow, 1, m.monthKey, centerStyle);
        _setText(sheet, currentRow, 2, '${m.soldCount}', lightRowStyle);
        _setText(sheet, currentRow, 3, '${currencyFormat.format(m.totalSales)} EGP', lightRowStyle);
        _setText(sheet, currentRow, 4, '${currencyFormat.format(m.netProfit)} EGP', valueStyle);
        sheet.setRowHeightInPixels(currentRow, 22);
        currentRow++;
      }
    }

    currentRow += 2;

    // --- Section 4: Breakdown by Device Type (توزيع الأجهزة) ---
    final deviceHeader = sheet.getRangeByIndex(currentRow, 1, currentRow, 4);
    deviceHeader.merge();
    deviceHeader.setText('توزيع الصفقات حسب نوع الجهاز (Device Distribution)');
    deviceHeader.cellStyle = sectionHeaderStyle;
    sheet.setRowHeightInPixels(currentRow, 24);
    currentRow++;

    final deviceColHeaders = [
      'نوع الجهاز (Device Type)',
      'إجمالي الصفقات (Total)',
      'المباع (Sold)',
      'إجمالي الأرباح (Profit)',
    ];
    for (int c = 0; c < deviceColHeaders.length; c++) {
      final cell = sheet.getRangeByIndex(currentRow, c + 1);
      cell.setText(deviceColHeaders[c]);
      cell.cellStyle = sectionHeaderStyle;
    }
    sheet.setRowHeightInPixels(currentRow, 24);
    currentRow++;

    final deviceGroups = <String, List<Trade>>{};
    for (final t in trades) {
      deviceGroups.putIfAbsent(t.deviceType, () => []).add(t);
    }

    final sortedDeviceKeys = deviceGroups.keys.toList()
      ..sort((a, b) => deviceGroups[b]!.length.compareTo(deviceGroups[a]!.length));

    for (final key in sortedDeviceKeys) {
      final list = deviceGroups[key]!;
      final sold = list.where((t) => t.status == TradeStatus.sold).length;
      final profit = list
          .where((t) => t.status == TradeStatus.sold)
          .fold(0.0, (sum, t) => sum + (t.profit ?? 0));

      _setText(sheet, currentRow, 1, key, labelStyle);
      _setText(sheet, currentRow, 2, '${list.length}', lightRowStyle);
      _setText(sheet, currentRow, 3, '$sold', lightRowStyle);
      _setText(sheet, currentRow, 4, '${currencyFormat.format(profit)} EGP', valueStyle);
      sheet.setRowHeightInPixels(currentRow, 22);
      currentRow++;
    }

    for (int c = 1; c <= 4; c++) {
      sheet.autoFitColumn(c);
    }
  }

  void _setText(
    xlsio.Worksheet sheet,
    int row,
    int col,
    String text,
    xlsio.Style style,
  ) {
    final cell = sheet.getRangeByIndex(row, col);
    cell.setText(text);
    cell.cellStyle = style;
  }

  /// Saves the Excel file directly to device storage (Downloads / Files).
  /// Returns the saved path or location info.
  Future<String> saveToDevice(List<Trade> trades) async {
    final bytes = generateExcelBytes(trades);
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'PS_Trader_Export_$timeStamp';

    // On Android, try saving directly into the public Downloads directory first
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download');
        if (publicDownloadDir.existsSync()) {
          final target = File('${publicDownloadDir.path}/$fileName.xlsx');
          await target.writeAsBytes(bytes, flush: true);
          return target.path;
        }
      } catch (e) {
        debugPrint('Direct write to /storage/emulated/0/Download failed: $e');
      }
    }

    // Standard scoped storage save via FileSaver across Android, iOS & desktop
    final savedPath = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    return savedPath;
  }

  /// Exports trades to an Excel file and summons the platform share dialog.
  Future<String?> shareFile(List<Trade> trades) async {
    final bytes = generateExcelBytes(trades);

    final tempDir = await getTemporaryDirectory();
    final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'PS_Trader_Export_$timeStamp.xlsx';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'PS Trader - تقرير وتصدير صفقات الأجهزة (.xlsx)',
        subject: 'PS Trader Export',
      ),
    );

    return filePath;
  }

  /// Backward compatible alias for shareFile
  Future<String?> exportAndShare(List<Trade> trades) => shareFile(trades);
}

class _MonthSummary {
  final String monthKey;
  int soldCount = 0;
  double totalSales = 0.0;
  double netProfit = 0.0;
  _MonthSummary(this.monthKey);
}
