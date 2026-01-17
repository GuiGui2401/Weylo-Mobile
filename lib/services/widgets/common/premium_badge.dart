import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Badge de vérification bleu style Facebook
class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2), // Bleu Facebook
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.65,
        color: Colors.white,
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: 'Compte vérifié',
        child: badge,
      );
    }
    return badge;
  }
}

/// A badge widget to indicate premium/verified status (ancien badge doré)
class PremiumBadge extends StatelessWidget {
  final double size;
  final bool showTooltip;

  const PremiumBadge({
    super.key,
    this.size = 16,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x40FFD700),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.star,
        size: size * 0.6,
        color: Colors.white,
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: 'Compte Premium',
        child: badge,
      );
    }
    return badge;
  }
}

/// A row widget that displays a name with optional premium/verified badge
class NameWithBadge extends StatelessWidget {
  final String name;
  final bool isPremium;
  final bool isVerified;
  final TextStyle? textStyle;
  final double badgeSize;
  final double spacing;

  const NameWithBadge({
    super.key,
    required this.name,
    this.isPremium = false,
    this.isVerified = false,
    this.textStyle,
    this.badgeSize = 14,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    // Badge bleu de vérification si premium OU verified (les utilisateurs qui paient)
    final showVerifiedBadge = isPremium || isVerified;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: textStyle ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showVerifiedBadge) ...[
          SizedBox(width: spacing),
          VerifiedBadge(size: badgeSize),
        ],
      ],
    );
  }
}

/// Badge style variants
enum BadgeStyle { gold, blue, green }

/// Premium badge with different styles
class StyledPremiumBadge extends StatelessWidget {
  final BadgeStyle style;
  final double size;

  const StyledPremiumBadge({
    super.key,
    this.style = BadgeStyle.gold,
    this.size = 16,
  });

  List<Color> get _gradientColors {
    switch (style) {
      case BadgeStyle.gold:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case BadgeStyle.blue:
        return [AppColors.primary, AppColors.secondary];
      case BadgeStyle.green:
        return [Colors.green, Colors.teal];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gradientColors.first.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
