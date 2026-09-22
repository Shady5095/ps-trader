import 'package:flutter/material.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../theme/app_theme.dart';

class StarRatingWidget extends StatelessWidget {
  final int? rating; // 1 to 3, or null if unrated
  final ValueChanged<int>? onChanged;
  final double starSize;
  final bool showLabel;
  final bool hasError;
  final String? errorText;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onChanged,
    this.starSize = 24,
    this.showLabel = false,
    this.hasError = false,
    this.errorText,
  });

  bool get isInteractive => onChanged != null;

  String? _getConditionLabel(BuildContext context, int? value) {
    if (value == null || value < 1) return null;
    switch (value) {
      case 3:
        return AppStrings.conditionExcellent.tr(context);
      case 2:
        return AppStrings.conditionVeryGood.tr(context);
      case 1:
        return AppStrings.conditionFair.tr(context);
      default:
        return null;
    }
  }

  Color _getStarColor(int index) {
    final currentRating = rating ?? 0;
    if (index <= currentRating) {
      return AppColors.gold;
    }
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final label = _getConditionLabel(context, rating);

    return Column(
      crossAxisAlignment:
          isInteractive ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 1; i <= 3; i++) ...[
              _StarButton(
                index: i,
                isFilled: (rating != null && i <= rating!),
                starSize: starSize,
                color: _getStarColor(i),
                isInteractive: isInteractive,
                onTap: isInteractive ? () => onChanged!(i) : null,
              ),
              if (i < 3) const SizedBox(width: 4),
            ],
            if (showLabel && label != null) ...[
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(label),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasError && errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StarButton extends StatefulWidget {
  final int index;
  final bool isFilled;
  final double starSize;
  final Color color;
  final bool isInteractive;
  final VoidCallback? onTap;

  const _StarButton({
    required this.index,
    required this.isFilled,
    required this.starSize,
    required this.color,
    required this.isInteractive,
    this.onTap,
  });

  @override
  State<_StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<_StarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.isFilled
        ? Icons.star_rounded
        : Icons.star_outline_rounded;

    if (!widget.isInteractive) {
      return Icon(
        icon,
        size: widget.starSize,
        color: widget.color,
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: widget.isFilled
                ? AppColors.gold.withValues(alpha: 0.12)
                : AppColors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isFilled
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            size: widget.starSize,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
