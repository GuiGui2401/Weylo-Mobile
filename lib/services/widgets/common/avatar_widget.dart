import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineIndicator;
  final bool isOnline;
  final bool isPremium;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.isPremium = false,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Helpers.getInitials(name, null);
    final bgColor = backgroundColor ?? Helpers.getAvatarColor(name ?? '');

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: isPremium
            ? Border.all(
                color: AppColors.premiumGold,
                width: 2,
              )
            : null,
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(initials),
                errorWidget: (context, url, error) => _buildPlaceholder(initials),
              ),
            )
          : _buildPlaceholder(initials),
    );

    if (showOnlineIndicator || isPremium) {
      avatar = Stack(
        children: [
          avatar,
          if (showOnlineIndicator)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          if (isPremium)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: AppColors.premiumGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  size: size * 0.2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StoryAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool hasUnviewedStory;
  final bool isMyStory;
  final VoidCallback? onTap;

  const StoryAvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 64,
    this.hasUnviewedStory = false,
    this.isMyStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 6,
        height: size + 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnviewedStory ? AppColors.storyGradient : null,
          border: !hasUnviewedStory
              ? Border.all(
                  color: AppColors.textHint,
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            AvatarWidget(
              imageUrl: imageUrl,
              name: name,
              size: size,
            ),
            if (isMyStory)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: size * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
