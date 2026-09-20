import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../cubits/trades/trades_cubit.dart';
import '../cubits/trades/trades_state.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';
import '../widgets/trade_card.dart';
import 'trade_detail_screen.dart';

class TradesListScreen extends StatefulWidget {
  const TradesListScreen({super.key});

  @override
  State<TradesListScreen> createState() => _TradesListScreenState();
}

class _TradesListScreenState extends State<TradesListScreen> {
  String _query = '';
  TradeStatus? _statusFilter;

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
                ],
              ),
            ),
          );
        }

        var trades = (state is TradesLoaded) ? state.trades : <Trade>[];
        if (_statusFilter != null) {
          trades = trades.where((t) => t.status == _statusFilter).toList();
        }
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          trades = trades
              .where((t) =>
                  t.deviceType.toLowerCase().contains(q) ||
                  t.sellerLocation.toLowerCase().contains(q) ||
                  t.gamesIncluded.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint.tr(context),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: AppStrings.all.tr(context),
                    selected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.inStock.tr(context),
                    selected: _statusFilter == TradeStatus.inStock,
                    onTap: () =>
                        setState(() => _statusFilter = TradeStatus.inStock),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.sold.tr(context),
                    selected: _statusFilter == TradeStatus.sold,
                    onTap: () =>
                        setState(() => _statusFilter = TradeStatus.sold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: trades.isEmpty
                  ? Center(
                      child: Text(AppStrings.noMatchingDevices.tr(context),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: trades.length,
                      itemBuilder: (context, i) {
                        final trade = trades[i];
                        return TradeCard(
                          trade: trade,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TradeDetailScreen(trade: trade),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
