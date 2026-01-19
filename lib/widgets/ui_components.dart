import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium Card Widget - Inspired by reference design
/// Card with rounded corners, subtle border, and optional shadow
class PremiumCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: const Color(0x40000000), // More visible border
                      width: 1.2,
                    )
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000), // Stronger shadow (10%)
                  blurRadius: 20,
                  offset: Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Circular Action Button - For arrow, heart, etc. actions
class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final bool hasShadow;

  const CircularActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 36,
    this.iconSize = 18,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryTeal,
          shape: BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withAlpha(77), // ~30%
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Secondary Circular Button - White/glass style for favorites etc.
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool isActive;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 32,
    this.iconSize = 16,
    this.iconColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryTeal.withAlpha(26) // ~10%
              : const Color(0xE6FFFFFF), // ~90% white
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? AppColors.primaryTeal.withAlpha(77) // ~30%
                : Colors.grey.shade200,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // ~8% black
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color:
              iconColor ??
              (isActive ? AppColors.primaryTeal : AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Stat Chip - Icon + value display (e.g., ⭐ 4.8)
class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? iconColor;
  final double iconSize;
  final double fontSize;

  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor,
    this.iconSize = 14,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Price Tag - Bold price with lighter suffix
class PriceTag extends StatelessWidget {
  final String price;
  final String suffix;
  final Color? priceColor;
  final double priceSize;
  final double suffixSize;
  final bool isOverlay; // For dark backgrounds

  const PriceTag({
    super.key,
    required this.price,
    this.suffix = '/day',
    this.priceColor,
    this.priceSize = 16,
    this.suffixSize = 12,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isOverlay
        ? Colors.white
        : (priceColor ?? AppColors.textPrimary);
    final suffixColor = isOverlay
        ? const Color(0xCCFFFFFF) // ~80% white
        : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          price,
          style: TextStyle(
            fontSize: priceSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          suffix,
          style: TextStyle(
            fontSize: suffixSize,
            color: suffixColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Status Badge - For "Available", "Rented" etc.
class StatusBadge extends StatelessWidget {
  final String text;
  final bool isPositive;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.isPositive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isPositive
            ? AppColors.primaryGradient
            : LinearGradient(
                colors: [
                  AppColors.error,
                  AppColors.error.withAlpha(204), // ~80%
                ],
              ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primaryTeal : AppColors.error)
                .withAlpha(77), // ~30%
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill Search Bar Widget
class PillSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onClear;

  const PillSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search...',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // ~4% black
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryTeal,
            size: 22,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: onClear,
                )
              : null,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textLight,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
