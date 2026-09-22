import 'dart:async';
import 'package:flutter/material.dart';
import '../config/rawg_config.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../models/trade_game.dart';
import '../services/rawg_api_service.dart';
import '../theme/app_theme.dart';

class GameSearchBottomSheet extends StatefulWidget {
  final List<TradeGame> existingGames;
  final ValueChanged<TradeGame>? onGameSelected;

  const GameSearchBottomSheet({
    super.key,
    required this.existingGames,
    this.onGameSelected,
  });

  static Future<TradeGame?> show(
    BuildContext context, {
    required List<TradeGame> existingGames,
    ValueChanged<TradeGame>? onGameSelected,
  }) {
    return showModalBottomSheet<TradeGame>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GameSearchBottomSheet(
        existingGames: existingGames,
        onGameSelected: onGameSelected,
      ),
    );
  }

  @override
  State<GameSearchBottomSheet> createState() => _GameSearchBottomSheetState();
}

class _GameSearchBottomSheetState extends State<GameSearchBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _manualNameCtrl = TextEditingController();
  final RawgApiService _apiService = RawgApiService();

  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _errorMessage;
  List<TradeGame> _searchResults = [];
  bool _showManualAdd = false;

  @override
  void initState() {
    super.initState();
    if (!RawgConfig.isConfigured) {
      _showManualAdd = true;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _manualNameCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!RawgConfig.isConfigured) {
      setState(() {
        _showManualAdd = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchGames(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool _isAlreadyAdded(TradeGame game) {
    return widget.existingGames.any((existing) =>
        existing.name.trim().toLowerCase() == game.name.trim().toLowerCase() ||
        (existing.id.isNotEmpty && existing.id == game.id));
  }

  void _selectGame(TradeGame game) {
    if (_isAlreadyAdded(game)) return;
    widget.onGameSelected?.call(game);
    Navigator.of(context).pop(game);
  }

  void _addManualGame() {
    final name = _manualNameCtrl.text.trim();
    if (name.isEmpty) return;

    final manualGame = TradeGame(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      coverUrl: '',
      source: 'manual',
    );

    _selectGame(manualGame);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.addGameTitle.tr(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: AppStrings.searchGamesHint.tr(context),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // RAWG API not configured note or manual option
          if (!RawgConfig.isConfigured || _showManualAdd) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            !RawgConfig.isConfigured
                                ? AppStrings.rawgKeyMissingNotice.tr(context)
                                : AppStrings.addGameManually.tr(context),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualNameCtrl,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: AppStrings.enterGameNameHint.tr(context),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addManualGame(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addManualGame,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(AppStrings.add.tr(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Search Results / States
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'جاري البحث في قاعدة بيانات الألعاب...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _performSearch(_searchCtrl.text),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.retry.tr(context)),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchCtrl.text.trim().isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                AppStrings.noGamesFound.tr(context),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (!_showManualAdd)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showManualAdd = true),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(AppStrings.addGameManually.tr(context)),
                ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              AppStrings.searchGamesInstructions.tr(context),
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        final alreadyAdded = _isAlreadyAdded(game);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alreadyAdded ? AppColors.border : AppColors.border,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 64,
                child: game.coverUrl.isNotEmpty
                    ? Image.network(
                        game.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                      )
                    : _buildThumbPlaceholder(),
              ),
            ),
            title: Text(
              game.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (game.releaseYear != null) game.releaseYear,
                  if (game.platforms != null) game.platforms,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            trailing: alreadyAdded
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.gameAlreadyAdded.tr(context),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _selectGame(game),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(AppStrings.add.tr(context)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 22,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
