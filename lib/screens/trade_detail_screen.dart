import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../cubits/trades/trades_cubit.dart';
import '../cubits/trades/trades_state.dart';
import '../models/device_catalog.dart';
import '../models/trade.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_drop_down_menu.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'add_edit_trade_screen.dart';

class TradeDetailScreen extends StatelessWidget {
  final Trade trade;
  const TradeDetailScreen({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final currency = intl.NumberFormat('#,##0');
    final dateFmt = intl.DateFormat('yyyy/MM/dd');

    final tradesState = context.watch<TradesCubit>().state;
    final trades =
        (tradesState is TradesLoaded) ? tradesState.trades : <Trade>[];
    final currentTrade = trades.firstWhere(
      (t) => t.id == trade.id,
      orElse: () => trade,
    );
    final isSold = currentTrade.status == TradeStatus.sold;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.dealDetails.tr(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTradeScreen(existing: currentTrade),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, currentTrade),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DeviceImageCarousel(
            imagePaths: currentTrade.imagePaths,
            deviceType: currentTrade.deviceType,
          ),
          _DetailCard(
            children: [
              _row(AppStrings.deviceType.tr(context), currentTrade.deviceType),
              if (currentTrade.modelCode.isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _row(AppStrings.releaseNumber.tr(context),
                    currentTrade.modelCode),
              ],
              const Divider(color: AppColors.border),
              _row(
                AppStrings.box.tr(context),
                currentTrade.hasBox
                    ? AppStrings.boxAvailable.tr(context)
                    : AppStrings.boxNotAvailable.tr(context),
                valueColor: currentTrade.hasBox
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              const Divider(color: AppColors.border),
              _row(AppStrings.controllersCount.tr(context),
                  '${currentTrade.controllers}'),
              const Divider(color: AppColors.border),
              _row(AppStrings.remainingWarranty.tr(context),
                  '${currentTrade.warrantyMonths} ${AppStrings.months.tr(context)}'),
              const Divider(color: AppColors.border),
              _row(AppStrings.purchaseDate.tr(context),
                  dateFmt.format(currentTrade.purchaseDate)),
              const Divider(color: AppColors.border),
              _priceRow(AppStrings.purchasePrice.tr(context),
                  currentTrade.purchasePrice, AppStrings.egp.tr(context)),
              const Divider(color: AppColors.border),
              _row(AppStrings.gamesCount.tr(context),
                  '${currentTrade.gamesCount}'),
              const Divider(color: AppColors.border),
              _row(
                AppStrings.status.tr(context),
                isSold
                    ? AppStrings.sold.tr(context)
                    : AppStrings.inStock.tr(context),
                valueColor: isSold ? AppColors.accent : AppColors.gold,
              ),
              if (currentTrade.gamesIncluded.isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _row(AppStrings.gamesIncluded.tr(context),
                    currentTrade.gamesIncluded),
              ],
              const Divider(color: AppColors.border),
              _row(
                  AppStrings.sellerLocation.tr(context),
                  currentTrade.sellerLocation.isEmpty
                      ? '—'
                      : currentTrade.sellerLocation),
              const Divider(color: AppColors.border),
              _row(
                  AppStrings.sellerNumber.tr(context),
                  currentTrade.sellerNumber.isEmpty
                      ? '—'
                      : currentTrade.sellerNumber),
              if (currentTrade.purchasePlatform.isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _row(AppStrings.purchasePlatform.tr(context),
                    currentTrade.purchasePlatform),
              ],
              if (currentTrade.serialNumber.isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _row(AppStrings.serialNumber.tr(context),
                    currentTrade.serialNumber),
              ],
              if (currentTrade.notes.isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _row(AppStrings.notes.tr(context),
                    currentTrade.notes),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isSold) ...[
            _DetailCard(
              children: [
                _row(AppStrings.deviceSellPrice.tr(context),
                    '${currency.format(currentTrade.deviceSellPrice ?? currentTrade.sellPrice ?? 0)} ${AppStrings.egp.tr(context)}'),
                const Divider(color: AppColors.border),
                _row(AppStrings.accessoriesSellPrice.tr(context),
                    '${currency.format(currentTrade.accessoriesSellPrice ?? 0)} ${AppStrings.egp.tr(context)}'),
                const Divider(color: AppColors.border),
                _row(AppStrings.totalSellPrice.tr(context),
                    '${currency.format(currentTrade.sellPrice ?? 0)} ${AppStrings.egp.tr(context)}',
                    valueColor: AppColors.accent),
                if (currentTrade.sellingPlatform != null &&
                    currentTrade.sellingPlatform!.isNotEmpty) ...[
                  const Divider(color: AppColors.border),
                  _row(AppStrings.sellingPlatform.tr(context),
                      currentTrade.sellingPlatform!),
                ],
                const Divider(color: AppColors.border),
                _row(
                  AppStrings.sellDate.tr(context),
                  currentTrade.sellDate != null
                      ? dateFmt.format(currentTrade.sellDate!)
                      : '—',
                ),
                const Divider(color: AppColors.border),
                _row(
                    AppStrings.buyerNumber.tr(context),
                    currentTrade.buyerNumber?.isEmpty ?? true
                        ? '—'
                        : currentTrade.buyerNumber!),
                const Divider(color: AppColors.border),
                _row(
                  AppStrings.netProfit.tr(context),
                  '${currency.format(currentTrade.profit ?? 0)} ${AppStrings.egp.tr(context)}',
                  valueColor: (currentTrade.profit ?? 0) >= 0
                      ? AppColors.accent
                      : AppColors.danger,
                ),
                const Divider(color: AppColors.border),
                _row(
                  AppStrings.profitMargin.tr(context),
                  '${(currentTrade.profitMargin ?? 0).toStringAsFixed(1)}%',
                  valueColor: (currentTrade.profitMargin ?? 0) >= 0
                      ? AppColors.accent
                      : AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          if (!isSold)
            ElevatedButton.icon(
              onPressed: () => _showMarkAsSoldSheet(context, currentTrade),
              icon: const Icon(Icons.sell_outlined),
              label: Text(AppStrings.recordSale.tr(context)),
            )
          else
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<TradesCubit>().revertToStock(currentTrade),
              icon: const Icon(Icons.undo),
              label: Text(AppStrings.revertToStock.tr(context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, String currencyText) {
    final currency = intl.NumberFormat('#,###', 'en_US');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: currency.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.primary,
                ),
                children: [
                  TextSpan(
                    text: ' $currencyText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Trade currentTrade) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(AppStrings.deleteDevice.tr(ctx)),
        content: Text(AppStrings.deleteDeviceConfirm.tr(ctx)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel.tr(ctx))),
          TextButton(
            onPressed: () async {
              await ctx.read<TradesCubit>().deleteTrade(currentTrade.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(ctx);
              }
            },
            child: Text(AppStrings.delete.tr(ctx),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showMarkAsSoldSheet(BuildContext context, Trade currentTrade) {
    final deviceSellPriceCtrl = TextEditingController();
    final accessoriesSellPriceCtrl = TextEditingController(text: '0');
    final buyerNumberCtrl = TextEditingController();
    String sellingPlatform = currentTrade.sellingPlatform ?? 'Marketplace';
    DateTime sellDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final devP = double.tryParse(deviceSellPriceCtrl.text) ?? 0.0;
          final accP = double.tryParse(accessoriesSellPriceCtrl.text) ?? 0.0;
          final totalSell = devP + accP;
          final currency = intl.NumberFormat('#,##0');

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.recordSale.tr(ctx),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: deviceSellPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: AppStrings.deviceSellPrice.tr(ctx)),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: accessoriesSellPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText:
                                  AppStrings.accessoriesSellPrice.tr(ctx)),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.totalSellPrice.tr(ctx),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${currency.format(totalSell)} ${AppStrings.egp.tr(ctx)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomDropDownMenu(
                    label: AppStrings.sellingPlatform.tr(ctx),
                    value: sellingPlatform,
                    dropdownItems: DeviceCatalog.platforms,
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => sellingPlatform = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buyerNumberCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: AppStrings.buyerNumber.tr(ctx)),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: sellDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setSheetState(() => sellDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: AppStrings.sellDate.tr(ctx)),
                      child: Text(
                          intl.DateFormat('yyyy/MM/dd').format(sellDate)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final devPrice =
                            double.tryParse(deviceSellPriceCtrl.text);
                        if (devPrice == null || devPrice <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.fieldRequired.tr(ctx)),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          return;
                        }
                        final accPrice =
                            double.tryParse(accessoriesSellPriceCtrl.text) ?? 0.0;
                        final total = devPrice + accPrice;

                        await ctx.read<TradesCubit>().markAsSold(
                              currentTrade,
                              deviceSellPrice: devPrice,
                              accessoriesSellPrice: accPrice,
                              sellPrice: total,
                              sellDate: sellDate,
                              buyerNumber: buyerNumberCtrl.text.trim(),
                              sellingPlatform: sellingPlatform,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(AppStrings.confirmSale.tr(ctx)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeviceImageCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final String deviceType;

  const _DeviceImageCarousel({
    required this.imagePaths,
    required this.deviceType,
  });

  @override
  State<_DeviceImageCarousel> createState() => _DeviceImageCarouselState();
}

class _DeviceImageCarouselState extends State<_DeviceImageCarousel> {
  int _currentIndex = 0;

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image,
              size: 48, color: AppColors.textSecondary),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const Center(
        child:
            Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 180,
          width: double.infinity,
          color: AppColors.surfaceAlt,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DeviceCatalog.iconFor(widget.deviceType),
                style: const TextStyle(fontSize: 54),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.noPhotosAvailable.tr(context),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: MediaQuery.of(context).size.width * 0.6,
        width: double.infinity,
        color: AppColors.surfaceAlt,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.imagePaths.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final path = widget.imagePaths[index];
                return GestureDetector(
                  onTap: () => FullScreenImageViewer.open(
                    context,
                    imagePaths: widget.imagePaths,
                    initialIndex: index,
                  ),
                  child: _buildImage(path),
                );
              },
            ),

            // Top zoom hint badge
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () => FullScreenImageViewer.open(
                  context,
                  imagePaths: widget.imagePaths,
                  initialIndex: _currentIndex,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.zoom.tr(context),
                        style: const TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom counter badge (when multiple photos)
            if (widget.imagePaths.length > 1)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${_currentIndex + 1} / ${widget.imagePaths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}
