import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../models/device_catalog.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback onTap;

  const TradeCard({super.key, required this.trade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSold = trade.status == TradeStatus.sold;
    final profit = trade.profit;
    final currency = intl.NumberFormat('#,##0');

    final statusText = isSold
        ? AppStrings.sold.tr(context)
        : AppStrings.inStock.tr(context);
    final buyText = AppStrings.buyLabel.tr(context);
    final profitText = AppStrings.profitLabel.tr(context);
    final egpText = AppStrings.egp.tr(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeviceThumbnail(trade: trade),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trade.deviceType,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isSold
                                    ? AppColors.accent
                                    : AppColors.gold)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSold
                                  ? AppColors.accent
                                  : AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '📍 ${trade.sellerLocation}   🎮 ${trade.controllers}   💽 ${trade.gamesCount}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trade.conditionRating > 0) ...[
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (i) => Icon(
                                i < trade.conditionRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 13,
                                color: i < trade.conditionRating
                                    ? AppColors.gold
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$buyText: ${currency.format(trade.purchasePrice)} $egpText',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 10),
                        if (isSold && profit != null)
                          Text(
                            '$profitText: ${currency.format(profit)} $egpText',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: profit >= 0
                                  ? AppColors.accent
                                  : AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceThumbnail extends StatelessWidget {
  final Trade trade;
  const _DeviceThumbnail({required this.trade});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 75,
        height: 75,
        alignment: Alignment.center,
        child: Image.asset(
          DeviceCatalog.assetImageFor(trade.deviceType),
          width: 75,
          height: 75,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Text(
      DeviceCatalog.iconFor(trade.deviceType),
      style: const TextStyle(fontSize: 26),
    );
  }
}
