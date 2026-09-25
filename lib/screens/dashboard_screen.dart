import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../cubits/trades/trades_cubit.dart';
import '../cubits/trades/trades_state.dart';
import '../models/trade.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/period_selector.dart';
import '../widgets/charts/monthly_profit_chart.dart';
import '../widgets/charts/daily_profit_chart.dart';
import '../widgets/charts/device_distribution_chart.dart';
import '../widgets/charts/profit_by_device_chart.dart';
import '../widgets/charts/popular_games_row_widget.dart';
import 'add_edit_trade_screen.dart';
import 'more_screen.dart';
import 'trades_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _DashboardBody(),
      const TradesListScreen(),
      const MoreScreen(),
    ];

    final titles = [
      AppStrings.appTitle.tr(context),
      AppStrings.devices.tr(context),
      AppStrings.more.tr(context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
      ),
      body: screens[_tab],
      floatingActionButton: _tab == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditTradeScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.addDevice.tr(context)),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: AppColors.surface,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: AppStrings.statistics.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: AppStrings.devices.tr(context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: AppStrings.more.tr(context),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradesCubit, TradesState>(
      builder: (context, state) {
        if (state is TradesLoading || state is TradesInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TradesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TradesCubit>().refresh(),
                    child: Text(AppStrings.retry.tr(context)),
                  ),
                ],
              ),
            ),
          );
        }

        final trades =
            (state is TradesLoaded) ? state.trades : const <Trade>[];
        final isAllTime = _selectedMonth == null;
        final stats = isAllTime
            ? StatsService(trades)
            : StatsService.forMonth(trades, _selectedMonth!);
        final currency = intl.NumberFormat('#,##0');
        final egp = AppStrings.egp.tr(context);

        final String profitChartTitle;
        if (isAllTime) {
          profitChartTitle = AppStrings.monthlyProfit.tr(context);
        } else {
          final locale = Localizations.localeOf(context).languageCode;
          final monthFormatted =
              intl.DateFormat('MMMM yyyy', locale).format(_selectedMonth!);
          profitChartTitle =
              '${AppStrings.dailyProfit.tr(context)} ($monthFormatted)';
        }

        return RefreshIndicator(
          onRefresh: () => context.read<TradesCubit>().refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PeriodSelectorWidget(
                selectedMonth: _selectedMonth,
                onPeriodChanged: (m) => setState(() => _selectedMonth = m),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                    title: AppStrings.totalProfit.tr(context),
                    value: '${currency.format(stats.totalProfit)} $egp',
                    icon: Icons.trending_up,
                    color: AppColors.accent,
                  ),
                  StatCard(
                    title: AppStrings.averageProfit.tr(context),
                    value: '${currency.format(stats.averageProfit)} $egp',
                    icon: Icons.equalizer,
                    color: AppColors.gold,
                  ),
                  StatCard(
                    title: AppStrings.soldCount.tr(context),
                    value: '${stats.soldCount}',
                    icon: Icons.sell_outlined,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    title: AppStrings.inStockCount.tr(context),
                    value: '${stats.inStockCount}',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: profitChartTitle,
                child: isAllTime
                    ? MonthlyProfitChart(data: stats.monthlyProfit())
                    : DailyProfitChart(
                        data: stats.dailyProfitsForMonth(_selectedMonth!)),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: AppStrings.deviceDistribution.tr(context),
                child: DeviceDistributionChart(data: stats.byDeviceType()),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: AppStrings.profitByDevice.tr(context),
                child: ProfitByDeviceChart(data: stats.byDeviceType()),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: AppStrings.mostPopularGames.tr(context),
                child: PopularGamesRowWidget(
                  popularGames: stats.popularGames(limit: 15),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
