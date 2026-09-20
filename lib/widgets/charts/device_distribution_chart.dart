import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';

class DeviceDistributionChart extends StatefulWidget {
  final List<DeviceTypeCount> data;
  const DeviceDistributionChart({super.key, required this.data});

  @override
  State<DeviceDistributionChart> createState() =>
      _DeviceDistributionChartState();
}

class _DeviceDistributionChartState extends State<DeviceDistributionChart> {
  int touchedIndex = -1;

  static const _palette = [
    AppColors.primary,
    AppColors.accent,
    AppColors.gold,
    AppColors.danger,
    AppColors.primaryLight,
    Color(0xFF9B6BFF),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('لا توجد بيانات كافية بعد')),
      );
    }
    final total = widget.data.fold<int>(0, (s, d) => s + d.count);

    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 46,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          response!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: [
                  for (int i = 0; i < widget.data.length; i++)
                    PieChartSectionData(
                      value: widget.data[i].count.toDouble(),
                      color: _palette[i % _palette.length],
                      radius: touchedIndex == i ? 54 : 46,
                      title:
                          '${(widget.data[i].count / total * 100).round()}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < widget.data.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _palette[i % _palette.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${widget.data[i].deviceType} (${widget.data[i].count})',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
