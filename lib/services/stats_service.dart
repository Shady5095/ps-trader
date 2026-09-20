import '../models/trade.dart';

class MonthlyProfit {
  final DateTime month;
  final double profit;
  MonthlyProfit(this.month, this.profit);
}

class DeviceTypeCount {
  final String deviceType;
  final int count;
  final double totalProfit;
  DeviceTypeCount(this.deviceType, this.count, this.totalProfit);
}

class StatsService {
  final List<Trade> trades;
  StatsService(this.trades);

  double get totalProfit => trades
      .where((t) => t.status == TradeStatus.sold)
      .fold(0.0, (sum, t) => sum + (t.profit ?? 0));

  int get soldCount =>
      trades.where((t) => t.status == TradeStatus.sold).length;

  int get inStockCount =>
      trades.where((t) => t.status == TradeStatus.inStock).length;

  double get averageProfit => soldCount == 0 ? 0 : totalProfit / soldCount;

  double get totalInvested =>
      trades.fold(0.0, (sum, t) => sum + t.purchasePrice);

  /// Last [monthsBack] months of net profit, oldest first.
  List<MonthlyProfit> monthlyProfit({int monthsBack = 6}) {
    final now = DateTime.now();
    final buckets = <DateTime, double>{};
    for (int i = monthsBack - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      buckets[DateTime(m.year, m.month)] = 0;
    }
    for (final t in trades) {
      if (t.status != TradeStatus.sold || t.sellDate == null) continue;
      final key = DateTime(t.sellDate!.year, t.sellDate!.month);
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + (t.profit ?? 0);
      }
    }
    return buckets.entries.map((e) => MonthlyProfit(e.key, e.value)).toList();
  }

  List<DeviceTypeCount> byDeviceType() {
    final Map<String, List<Trade>> grouped = {};
    for (final t in trades) {
      grouped.putIfAbsent(t.deviceType, () => []).add(t);
    }
    return grouped.entries.map((e) {
      final profit = e.value
          .where((t) => t.status == TradeStatus.sold)
          .fold(0.0, (s, t) => s + (t.profit ?? 0));
      return DeviceTypeCount(e.key, e.value.length, profit);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }
}
