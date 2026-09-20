import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class MonthlyProfitChart extends StatelessWidget {
  final List<MonthlyProfit> data;
  const MonthlyProfitChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('لا توجد بيانات كافية بعد')),
      );
    }

    final maxY = data.map((e) => e.profit).fold<double>(
            0, (p, v) => v > p ? v : p) *
        1.25 +
        1;
    final minYRaw =
        data.map((e) => e.profit).fold<double>(0, (p, v) => v < p ? v : p);
    final minY = minYRaw < 0 ? minYRaw * 1.25 : 0.0;

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY == 0 ? 10 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: (maxY - minY) / 4 == 0 ? 1 : (maxY - minY) / 4,
                getTitlesWidget: (value, meta) => Text(
                  intl.NumberFormat.compact().format(value),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final m = data[idx].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      intl.DateFormat('MMM', 'en').format(m),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.surfaceAlt,
              getTooltipItems: (spots) => spots.map((s) {
                final m = data[s.x.toInt()].month;
                return LineTooltipItem(
                  '${intl.DateFormat('MMM yyyy', 'en').format(m)}\n${intl.NumberFormat('#,##0').format(s.y)} ج.م',
                  const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].profit),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accent,
                  strokeWidth: 2,
                  strokeColor: AppColors.bg,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.35),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
