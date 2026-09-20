import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class ProfitByDeviceChart extends StatelessWidget {
  final List<DeviceTypeCount> data;
  const ProfitByDeviceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('لا توجد بيانات كافية بعد')),
      );
    }
    final maxY =
        data.map((e) => e.totalProfit).fold<double>(0, (p, v) => v > p ? v : p) *
            1.25 +
            1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = (data.length * 64.0).clamp(constraints.maxWidth, double.infinity);
        return SizedBox(
          height: 240,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        const FlLine(color: AppColors.border, strokeWidth: 1),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final label = data[idx].deviceType;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label.length > 10
                                  ? '${label.substring(0, 9)}…'
                                  : label,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 9.5),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: AppColors.surfaceAlt,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        '${intl.NumberFormat('#,##0').format(rod.toY)} ج.م',
                        const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].totalProfit,
                            width: 22,
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
