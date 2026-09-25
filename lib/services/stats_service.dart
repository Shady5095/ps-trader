import '../models/trade.dart';
import '../models/trade_game.dart';

class MonthlyProfit {
  final DateTime month;
  final double profit;
  MonthlyProfit(this.month, this.profit);
}

class DailyProfit {
  final DateTime date;
  final double profit;
  DailyProfit(this.date, this.profit);
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

  factory StatsService.forMonth(List<Trade> allTrades, DateTime month) {
    final filtered = allTrades.where((t) {
      if (t.status == TradeStatus.sold && t.sellDate != null) {
        return t.sellDate!.year == month.year &&
            t.sellDate!.month == month.month;
      }
      return t.purchaseDate.year == month.year &&
          t.purchaseDate.month == month.month;
    }).toList();
    return StatsService(filtered);
  }

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

  /// Daily net profit for the given [month], from day 1 to end of month.
  List<DailyProfit> dailyProfitsForMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final buckets = <int, double>{};
    for (int day = 1; day <= lastDay; day++) {
      buckets[day] = 0.0;
    }
    for (final t in trades) {
      if (t.status != TradeStatus.sold || t.sellDate == null) continue;
      if (t.sellDate!.year == month.year && t.sellDate!.month == month.month) {
        final day = t.sellDate!.day;
        buckets[day] = (buckets[day] ?? 0.0) + (t.profit ?? 0.0);
      }
    }
    return buckets.entries
        .map((e) =>
            DailyProfit(DateTime(month.year, month.month, e.key), e.value))
        .toList();
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

  /// Calculates the most popular games among trades in this stats scope.
  /// [limit] defaults to 15 (Top 15).
  List<GamePopularity> popularGames({int limit = 15}) {
    if (trades.isEmpty) return const [];

    final Map<String, _GameStatCollector> collectors = {};

    for (final trade in trades) {
      // Use trade.games if populated
      if (trade.games.isNotEmpty) {
        // Avoid duplicate counting if the same game is added twice on the same trade
        final seenInThisTrade = <String>{};
        for (final game in trade.games) {
          final normalized = game.name.trim().toLowerCase();
          if (normalized.isEmpty || seenInThisTrade.contains(normalized)) continue;
          seenInThisTrade.add(normalized);

          final existing = collectors[normalized];
          if (existing == null) {
            collectors[normalized] = _GameStatCollector(sampleGame: game, count: 1);
          } else {
            existing.count++;
            // Update sample game if existing doesn't have a cover but this one does
            if (existing.sampleGame.coverUrl.isEmpty && game.coverUrl.isNotEmpty) {
              existing.sampleGame = game;
            }
          }
        }
      } else if (trade.gamesIncluded.trim().isNotEmpty) {
        // Fallback for trades that only have gamesIncluded text (e.g. "FC 24, Spider-Man")
        final splitNames = trade.gamesIncluded
            .split(RegExp(r'[,،\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);

        final seenInThisTrade = <String>{};
        for (final rawName in splitNames) {
          final normalized = rawName.toLowerCase();
          if (seenInThisTrade.contains(normalized)) continue;
          seenInThisTrade.add(normalized);

          final existing = collectors[normalized];
          if (existing == null) {
            collectors[normalized] = _GameStatCollector(
              sampleGame: TradeGame(
                id: 'txt_$normalized',
                name: rawName,
                coverUrl: '',
                source: 'text',
              ),
              count: 1,
            );
          } else {
            existing.count++;
          }
        }
      }
    }

    final totalTrades = trades.length;
    final results = collectors.values.map((col) {
      final percentage = totalTrades == 0 ? 0.0 : (col.count / totalTrades) * 100.0;
      return GamePopularity(
        game: col.sampleGame,
        count: col.count,
        percentage: percentage,
      );
    }).toList();

    results.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      return a.game.name.compareTo(b.game.name);
    });

    if (limit > 0 && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }
}

class GamePopularity {
  final TradeGame game;
  final int count;
  final double percentage;

  const GamePopularity({
    required this.game,
    required this.count,
    required this.percentage,
  });
}

class _GameStatCollector {
  TradeGame sampleGame;
  int count;

  _GameStatCollector({
    required this.sampleGame,
    required this.count,
  });
}
