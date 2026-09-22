import 'package:flutter/material.dart';
import '../models/trade_game.dart';
import '../theme/app_theme.dart';

class GameCardItem extends StatelessWidget {
  final TradeGame game;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const GameCardItem({
    super.key,
    required this.game,
    this.onDelete,
    this.onTap,
    this.width = 115,
    this.height = 165,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover Image or Fallback
          if (game.coverUrl.isNotEmpty)
            Image.network(
              game.coverUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.surfaceAlt,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Dark Gradient Overlay for Title readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Game Title & Year
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (game.releaseYear != null && game.releaseYear!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    game.releaseYear!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Delete Button (if provided)
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.65),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ),

          // Ink response for whole card if onTap is passed
          if (onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceAlt,
            AppColors.primary.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          size: 38,
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
