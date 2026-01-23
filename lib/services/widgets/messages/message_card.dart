import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/message.dart';
import '../common/avatar_widget.dart';

class MessageCard extends StatelessWidget {
  final AnonymousMessage message;
  final bool isReceived;
  final VoidCallback? onTap;

  const MessageCard({
    super.key,
    required this.message,
    this.isReceived = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: message.isRead ? 0 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSenderInfo(context),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.getTimeAgo(message.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!message.isRead && isReceived)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.replyToMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.replyToMessage!.content,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (message.isIdentityRevealed && message.sender != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.identityRevealed(message.sender!.fullName),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (isReceived) {
      if (message.sender?.avatar != null &&
          message.sender!.avatar!.isNotEmpty) {
        return AvatarWidget(
          imageUrl: message.sender!.avatar,
          name: message.isIdentityRevealed ? message.sender!.fullName : null,
          size: 48,
        );
      }
      return _PulsingAvatarPlaceholder(
        initials: message.senderInitials,
      );
    } else {
      return AvatarWidget(
        imageUrl: message.recipient?.avatar,
        name: message.recipient?.fullName,
        size: 48,
      );
    }
  }

  Widget _buildSenderInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isReceived) {
      if (message.isIdentityRevealed && message.sender != null) {
        return Text(
          message.sender!.fullName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        );
      }
      return Row(
        children: [
          const Icon(
            Icons.person_off,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.anonymousUser,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      return Text(
        l10n.toRecipient(message.recipient?.fullName ?? l10n.userFallback),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      );
    }
  }
}

class _PulsingAvatarPlaceholder extends StatefulWidget {
  final String initials;

  const _PulsingAvatarPlaceholder({required this.initials});

  @override
  State<_PulsingAvatarPlaceholder> createState() => _PulsingAvatarPlaceholderState();
}

class _PulsingAvatarPlaceholderState extends State<_PulsingAvatarPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(begin: 0.2, end: 0.6).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final opacity = 0.65 + _pulse.value * 0.25;
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(opacity),
                AppColors.secondary.withOpacity(opacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              widget.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
