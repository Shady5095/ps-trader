import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../cubits/trades/trades_cubit.dart';
import '../models/device_catalog.dart';
import '../models/trade.dart';
import '../models/trade_game.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_drop_down_menu.dart';
import '../widgets/device_image_picker.dart';
import '../widgets/game_card_item.dart';
import '../widgets/game_search_bottom_sheet.dart';
import '../widgets/star_rating_widget.dart';
import 'barcode_scanner_screen.dart';

class AddEditTradeScreen extends StatefulWidget {
  final Trade? existing;
  const AddEditTradeScreen({super.key, this.existing});

  @override
  State<AddEditTradeScreen> createState() => _AddEditTradeScreenState();
}

class _AddEditTradeScreenState extends State<AddEditTradeScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _deviceType;
  bool _hasBox = true;
  String? _modelCode;
  final _serialNumberCtrl = TextEditingController();
  String _purchasePlatform = 'Marketplace';
  final _warrantyMonthsCtrl = TextEditingController(text: '0');

  final _controllersCtrl = TextEditingController();
  final _gamesCountCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _sellerNumberCtrl = TextEditingController();
  final _sellerLocationCtrl = TextEditingController();
  final _gamesIncludedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  List<String> _imagePaths = [];
  List<TradeGame> _selectedGames = [];
  int? _conditionRating;
  bool _conditionRatingError = false;
  bool _saving = false;

  late final TextEditingController _deviceSellPriceCtrl;
  late final TextEditingController _accessoriesSellPriceCtrl;
  late final TextEditingController _buyerNumberCtrl;
  String? _sellingPlatform;
  DateTime? _sellDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _deviceType = e?.deviceType; // Starts empty (null) when adding a new device
    _hasBox = e?.hasBox ?? true;
    _modelCode = (e != null && e.modelCode.isNotEmpty) ? e.modelCode : null;
    _serialNumberCtrl.text = e?.serialNumber ?? '';
    _purchasePlatform = e?.purchasePlatform ?? 'Marketplace';
    _warrantyMonthsCtrl.text = (e?.warrantyMonths ?? 0).toString();

    _controllersCtrl.text = (e?.controllers ?? 2).toString();
    _gamesCountCtrl.text = (e?.gamesCount ?? 0).toString();
    _purchasePriceCtrl.text =
        e != null ? e.purchasePrice.toStringAsFixed(0) : '';
    _sellerNumberCtrl.text = e?.sellerNumber ?? '';
    _sellerLocationCtrl.text = e?.sellerLocation ?? '';
    _gamesIncludedCtrl.text = e?.gamesIncluded ?? '';
    _notesCtrl.text = e?.notes ?? '';
    _purchaseDate = e?.purchaseDate ?? DateTime.now();
    _imagePaths = List<String>.from(
      e?.imagePaths ?? (e?.imagePath != null ? [e!.imagePath!] : const []),
    );
    _selectedGames = List<TradeGame>.from(e?.games ?? const []);
    _conditionRating = e?.conditionRating;

    final isSold = e?.status == TradeStatus.sold;
    _deviceSellPriceCtrl = TextEditingController(
      text: isSold
          ? ((e?.deviceSellPrice ?? e?.sellPrice)?.toStringAsFixed(0) ?? '')
          : '',
    );
    _accessoriesSellPriceCtrl = TextEditingController(
      text: isSold
          ? (e?.accessoriesSellPrice?.toStringAsFixed(0) ?? '0')
          : '0',
    );
    _buyerNumberCtrl = TextEditingController(
      text: isSold ? (e?.buyerNumber ?? '') : '',
    );
    _sellingPlatform = isSold
        ? (e?.sellingPlatform ?? DeviceCatalog.platforms.first)
        : null;
    _sellDate = isSold ? (e?.sellDate ?? DateTime.now()) : null;
  }

  @override
  void dispose() {
    _controllersCtrl.dispose();
    _gamesCountCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellerNumberCtrl.dispose();
    _sellerLocationCtrl.dispose();
    _gamesIncludedCtrl.dispose();
    _notesCtrl.dispose();
    _serialNumberCtrl.dispose();
    _warrantyMonthsCtrl.dispose();
    _deviceSellPriceCtrl.dispose();
    _accessoriesSellPriceCtrl.dispose();
    _buyerNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _scanSerialNumberBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scannedCode != null && scannedCode.trim().isNotEmpty) {
      setState(() {
        _serialNumberCtrl.text = scannedCode.trim();
      });
    }
  }

  Future<void> _addGameToSelection() async {
    final selectedGame = await GameSearchBottomSheet.show(
      context,
      existingGames: _selectedGames,
    );
    if (selectedGame != null) {
      setState(() {
        _selectedGames.add(selectedGame);
        _gamesCountCtrl.text = _selectedGames.length.toString();
        _gamesIncludedCtrl.text = _selectedGames.map((g) => g.name).join(', ');
      });
    }
  }

  void _removeGameFromSelection(TradeGame game) {
    setState(() {
      _selectedGames.removeWhere((g) => g == game || g.id == game.id || g.name == game.name);
      _gamesCountCtrl.text = _selectedGames.length.toString();
      _gamesIncludedCtrl.text = _selectedGames.map((g) => g.name).join(', ');
    });
  }

  Future<void> _save() async {
    final bool hasRating = _conditionRating != null &&
        _conditionRating! >= 1 &&
        _conditionRating! <= 3;
    if (!hasRating) {
      setState(() => _conditionRatingError = true);
    } else if (_conditionRatingError) {
      setState(() => _conditionRatingError = false);
    }

    if (!_formKey.currentState!.validate() || !hasRating) return;
    setState(() => _saving = true);

    try {
      final tradesCubit = context.read<TradesCubit>();

      if (_isEditing) {
        final isSold = widget.existing!.status == TradeStatus.sold;
        final devSell = isSold
            ? double.tryParse(_deviceSellPriceCtrl.text)
            : widget.existing!.deviceSellPrice;
        final accSell = isSold
            ? (double.tryParse(_accessoriesSellPriceCtrl.text) ?? 0.0)
            : widget.existing!.accessoriesSellPrice;
        final totalSell = (devSell != null || accSell != null)
            ? ((devSell ?? 0.0) + (accSell ?? 0.0))
            : widget.existing!.sellPrice;

        final updated = widget.existing!.copyWith(
          deviceType: _deviceType,
          controllers: int.tryParse(_controllersCtrl.text) ?? 0,
          gamesCount: _selectedGames.isNotEmpty ? _selectedGames.length : (int.tryParse(_gamesCountCtrl.text) ?? 0),
          purchaseDate: _purchaseDate,
          purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
          sellerNumber: _sellerNumberCtrl.text.trim(),
          sellerLocation: _sellerLocationCtrl.text.trim(),
          gamesIncluded: _gamesIncludedCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          hasBox: _hasBox,
          modelCode: _modelCode ?? '',
          serialNumber: _serialNumberCtrl.text.trim(),
          purchasePlatform: _purchasePlatform,
          sellingPlatform:
              isSold ? _sellingPlatform : widget.existing?.sellingPlatform,
          warrantyMonths: int.tryParse(_warrantyMonthsCtrl.text) ?? 0,
          imagePaths: _imagePaths,
          clearImage: _imagePaths.isEmpty,
          deviceSellPrice: devSell,
          accessoriesSellPrice: accSell,
          sellPrice: totalSell,
          buyerNumber: isSold
              ? _buyerNumberCtrl.text.trim()
              : widget.existing?.buyerNumber,
          sellDate: isSold ? _sellDate : widget.existing?.sellDate,
          games: _selectedGames,
          conditionRating: _conditionRating!,
        );
        await tradesCubit.updateTrade(updated);
      } else {
        await tradesCubit.addTrade(
          deviceType: _deviceType!,
          controllers: int.tryParse(_controllersCtrl.text) ?? 0,
          gamesCount: _selectedGames.isNotEmpty ? _selectedGames.length : (int.tryParse(_gamesCountCtrl.text) ?? 0),
          purchaseDate: _purchaseDate,
          purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
          sellerNumber: _sellerNumberCtrl.text.trim(),
          sellerLocation: _sellerLocationCtrl.text.trim(),
          gamesIncluded: _gamesIncludedCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          hasBox: _hasBox,
          modelCode: _modelCode ?? '',
          serialNumber: _serialNumberCtrl.text.trim(),
          purchasePlatform: _purchasePlatform,
          warrantyMonths: int.tryParse(_warrantyMonthsCtrl.text) ?? 0,
          imagePaths: _imagePaths,
          games: _selectedGames,
          conditionRating: _conditionRating!,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? AppStrings.editDevice.tr(context)
            : AppStrings.addDevice.tr(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(AppStrings.realDevicePhotos.tr(context)),
            DeviceImagePicker(
              imagePaths: _imagePaths,
              onChanged: (paths) => setState(() => _imagePaths = paths),
            ),
            const SizedBox(height: 16),
            CustomDropDownMenu(
              label: AppStrings.deviceType.tr(context),
              hint: AppStrings.selectDeviceType.tr(context),
              value: _deviceType,
              dropdownItems: DeviceCatalog.allLabels,
              validator: (v) => (v == null || v.isEmpty)
                  ? AppStrings.fieldRequired.tr(context)
                  : null,
              onChanged: _saving
                  ? (_) {}
                  : (v) {
                      setState(() => _deviceType = v);
                    },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    controller: _purchasePriceCtrl,
                    label: AppStrings.purchasePrice.tr(context),
                    requiredText: AppStrings.fieldRequired.tr(context),
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _saving ? null : _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: AppStrings.purchaseDate.tr(context)),
                      child: Text(
                          intl.DateFormat('yyyy/MM/dd').format(_purchaseDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    controller: _controllersCtrl,
                    label: AppStrings.controllersCount.tr(context),
                    requiredText: AppStrings.fieldRequired.tr(context),
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    controller: _gamesCountCtrl,
                    label: AppStrings.gamesCount.tr(context),
                    requiredText: AppStrings.fieldRequired.tr(context),
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomDropDownMenu(
                    label: AppStrings.releaseNumber.tr(context),
                    hint: AppStrings.selectReleaseNumber.tr(context),
                    value: _modelCode,
                    dropdownItems: DeviceCatalog.modelCodes,
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.fieldRequired.tr(context)
                        : null,
                    onChanged: _saving
                        ? (_) {}
                        : (v) {
                            setState(() => _modelCode = v);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropDownMenu(
                    label: AppStrings.box.tr(context),
                    value: _hasBox
                        ? AppStrings.boxAvailable.tr(context)
                        : AppStrings.boxNotAvailable.tr(context),
                    dropdownItems: [
                      AppStrings.boxAvailable.tr(context),
                      AppStrings.boxNotAvailable.tr(context),
                    ],
                    onChanged: _saving
                        ? (_) {}
                        : (v) {
                            if (v != null) {
                              setState(() {
                                _hasBox =
                                    (v == AppStrings.boxAvailable.tr(context));
                              });
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _conditionRatingError
                      ? AppColors.danger
                      : AppColors.border,
                  width: _conditionRatingError ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grade_outlined,
                          size: 18, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.deviceCondition.tr(context),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      StarRatingWidget(
                        rating: _conditionRating,
                        starSize: 22,
                        showLabel: false,
                        onChanged: _saving
                            ? null
                            : (val) {
                                setState(() {
                                  _conditionRating = val;
                                  _conditionRatingError = false;
                                });
                              },
                      ),
                    ],
                  ),
                  if (_conditionRatingError) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.conditionRatingRequired.tr(context),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serialNumberCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.serialNumber.tr(context),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: AppStrings.scanBarcode.tr(context),
                        onPressed: _saving ? null : _scanSerialNumberBarcode,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _warrantyMonthsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.remainingWarrantyMonths.tr(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomDropDownMenu(
                    label: AppStrings.purchasePlatform.tr(context),
                    value: _purchasePlatform,
                    dropdownItems: DeviceCatalog.platforms,
                    onChanged: _saving
                        ? (_) {}
                        : (v) {
                            if (v != null) {
                              setState(() => _purchasePlatform = v);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellerLocationCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.sellerLocation.tr(context),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.fieldRequired.tr(context)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerNumberCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: AppStrings.sellerNumber.tr(context)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_esports_rounded, size: 20, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.gamesIncludedSection.tr(context),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${_selectedGames.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _saving ? null : _addGameToSelection,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(AppStrings.addGame.tr(context)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedGames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedGames.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final game = _selectedGames[index];
                          return GameCardItem(
                            game: game,
                            width: 105,
                            height: 150,
                            onDelete: _saving ? null : () => _removeGameFromSelection(game),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gamesIncludedCtrl,
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: AppStrings.gamesIncluded.tr(context),
                      hintText: AppStrings.gamesIncludedHint.tr(context),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                  labelText: AppStrings.notes.tr(context)),
            ),
            if (_isEditing && widget.existing!.status == TradeStatus.sold) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.saleData.tr(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _deviceSellPriceCtrl,
                      label: AppStrings.deviceSellPrice.tr(context),
                      required: true,
                      requiredText: AppStrings.fieldRequired.tr(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      controller: _accessoriesSellPriceCtrl,
                      label: AppStrings.accessoriesSellPrice.tr(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDropDownMenu(
                      label: AppStrings.sellingPlatform.tr(context),
                      value: _sellingPlatform,
                      dropdownItems: DeviceCatalog.platforms,
                      onChanged: _saving
                          ? (_) {}
                          : (v) {
                              if (v != null) {
                                setState(() => _sellingPlatform = v);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _sellDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _sellDate = picked);
                              }
                            },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppStrings.sellDate.tr(context),
                        ),
                        child: Text(
                          _sellDate != null
                              ? intl.DateFormat('yyyy/MM/dd').format(_sellDate!)
                              : '—',
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerNumberCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppStrings.buyerNumber.tr(context),
                ),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing
                      ? AppStrings.saveChanges.tr(context)
                      : AppStrings.save.tr(context)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? requiredText,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      enabled: !_saving,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? (requiredText ?? 'مطلوب') : null
          : null,
    );
  }
}
