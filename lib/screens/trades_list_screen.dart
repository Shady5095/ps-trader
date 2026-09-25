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

enum TradeSortOption {
  defaultLatest,
  buyPrice,
  sellPrice,
  profit,
  soldDays,
}

class _TradesListScreenState extends State<TradesListScreen> {
  String _query = '';
  TradeStatus? _statusFilter;
  TradeSortOption _sortOption = TradeSortOption.defaultLatest;
  bool _sortDescending = true;

  int _getSoldDays(Trade trade) {
    if (trade.status != TradeStatus.sold || trade.sellDate == null) {
      return _sortDescending ? -1 : 999999;
    }
    final pDate = DateTime(
      trade.purchaseDate.year,
      trade.purchaseDate.month,
      trade.purchaseDate.day,
    );
    final sDate = DateTime(
      trade.sellDate!.year,
      trade.sellDate!.month,
      trade.sellDate!.day,
    );
    final diff = sDate.difference(pDate).inDays;
    return diff <= 1 ? 1 : diff;
  }

  void _showArrangeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.arrangeBy.tr(ctx),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_sortOption != TradeSortOption.defaultLatest)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _sortOption = TradeSortOption.defaultLatest;
                                _sortDescending = true;
                              });
                              setModalState(() {});
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              AppStrings.sortDefault.tr(ctx),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_sortOption != TradeSortOption.defaultLatest) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _DirectionOption(
                              label: _sortOption == TradeSortOption.soldDays
                                  ? (isArabic(ctx) ? 'الأطول أولاً' : 'Longest First')
                                  : AppStrings.sortHighToLow.tr(ctx),
                              icon: Icons.arrow_downward_rounded,
                              selected: _sortDescending,
                              onTap: () {
                                setState(() => _sortDescending = true);
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DirectionOption(
                              label: _sortOption == TradeSortOption.soldDays
                                  ? (isArabic(ctx) ? 'الأسرع أولاً' : 'Fastest First')
                                  : AppStrings.sortLowToHigh.tr(ctx),
                              icon: Icons.arrow_upward_rounded,
                              selected: !_sortDescending,
                              onTap: () {
                                setState(() => _sortDescending = false);
                                setModalState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border),
                    ],
                    _SortTile(
                      label: AppStrings.sortByBuyPrice.tr(ctx),
                      icon: Icons.shopping_bag_outlined,
                      selected: _sortOption == TradeSortOption.buyPrice,
                      onTap: () {
                        setState(() => _sortOption = TradeSortOption.buyPrice);
                        setModalState(() {});
                      },
                    ),
                    _SortTile(
                      label: AppStrings.sortBySellPrice.tr(ctx),
                      icon: Icons.sell_outlined,
                      selected: _sortOption == TradeSortOption.sellPrice,
                      onTap: () {
                        setState(() => _sortOption = TradeSortOption.sellPrice);
                        setModalState(() {});
                      },
                    ),
                    _SortTile(
                      label: AppStrings.sortByProfit.tr(ctx),
                      icon: Icons.trending_up,
                      selected: _sortOption == TradeSortOption.profit,
                      onTap: () {
                        setState(() => _sortOption = TradeSortOption.profit);
                        setModalState(() {});
                      },
                    ),
                    _SortTile(
                      label: AppStrings.sortBySoldDays.tr(ctx),
                      icon: Icons.schedule_outlined,
                      selected: _sortOption == TradeSortOption.soldDays,
                      onTap: () {
                        setState(() => _sortOption = TradeSortOption.soldDays);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
          final cleanQ = q.replaceAll(' ', '').replaceAll('-', '');
          trades = trades.where((t) {
            final matchesDevice = t.deviceType.toLowerCase().contains(q) ||
                t.modelCode.toLowerCase().contains(q);
            final matchesLocation = t.sellerLocation.toLowerCase().contains(q);
            final matchesSellerNumber = t.sellerNumber.toLowerCase().contains(q) ||
                t.sellerNumber.replaceAll(' ', '').replaceAll('-', '').contains(cleanQ);
            final matchesBuyerNumber = t.buyerNumber != null &&
                (t.buyerNumber!.toLowerCase().contains(q) ||
                    t.buyerNumber!.replaceAll(' ', '').replaceAll('-', '').contains(cleanQ));
            final matchesSerial = t.serialNumber.toLowerCase().contains(q);
            final matchesGames = t.gamesIncluded.toLowerCase().contains(q) ||
                t.games.any((g) => g.name.toLowerCase().contains(q));
            final matchesNotes = t.notes.toLowerCase().contains(q);

            return matchesDevice ||
                matchesLocation ||
                matchesSellerNumber ||
                matchesBuyerNumber ||
                matchesSerial ||
                matchesGames ||
                matchesNotes;
          }).toList();
        }

        if (_sortOption != TradeSortOption.defaultLatest) {
          trades = List<Trade>.from(trades)..sort((a, b) {
            int comp = 0;
            switch (_sortOption) {
              case TradeSortOption.buyPrice:
                comp = a.purchasePrice.compareTo(b.purchasePrice);
                break;
              case TradeSortOption.sellPrice:
                final aPrice = a.sellPrice ?? 0.0;
                final bPrice = b.sellPrice ?? 0.0;
                comp = aPrice.compareTo(bPrice);
                break;
              case TradeSortOption.profit:
                final aProfit = a.profit ?? 0.0;
                final bProfit = b.profit ?? 0.0;
                comp = aProfit.compareTo(bProfit);
                break;
              case TradeSortOption.soldDays:
                final aDays = _getSoldDays(a);
                final bDays = _getSoldDays(b);
                comp = aDays.compareTo(bDays);
                break;
              case TradeSortOption.defaultLatest:
                break;
            }
            return _sortDescending ? -comp : comp;
          });
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                    const SizedBox(width: 12),
                    _ArrangeButton(
                      currentOption: _sortOption,
                      descending: _sortDescending,
                      onTap: () => _showArrangeBottomSheet(context),
                    ),
                  ],
                ),
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

class _ArrangeButton extends StatelessWidget {
  final TradeSortOption currentOption;
  final bool descending;
  final VoidCallback onTap;

  const _ArrangeButton({
    required this.currentOption,
    required this.descending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentOption != TradeSortOption.defaultLatest;
    final String label;
    switch (currentOption) {
      case TradeSortOption.buyPrice:
        label = AppStrings.sortByBuyPrice.tr(context);
        break;
      case TradeSortOption.sellPrice:
        label = AppStrings.sortBySellPrice.tr(context);
        break;
      case TradeSortOption.profit:
        label = AppStrings.sortByProfit.tr(context);
        break;
      case TradeSortOption.soldDays:
        label = AppStrings.sortBySoldDays.tr(context);
        break;
      case TradeSortOption.defaultLatest:
        label = AppStrings.arrangeBy.tr(context);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: isActive ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? '$label ${descending ? "↓" : "↑"}' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20)
          : null,
    );
  }
}
