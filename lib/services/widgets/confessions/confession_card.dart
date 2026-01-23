import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/confession.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../confession_service.dart';
import '../../promotion_service.dart';
import '../common/avatar_widget.dart';
import '../common/link_text.dart';
import '../common/premium_badge.dart';
import '../promotions/promote_post_modal.dart';

class ConfessionCard extends StatefulWidget {
  final Confession confession;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onPromote;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onDeleted;

  const ConfessionCard({
    super.key,
    required this.confession,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onPromote,
    this.onAuthorTap,
    this.onDeleted,
  });

  @override
  State<ConfessionCard> createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoInitError = false;
  bool _isVideoVisible = false;
  bool _isMuted = false;
  bool _isContentExpanded = false;
  bool _hasReportedView = false;
  bool _hasReportedPromotionImpression = false;
  final ConfessionService _confessionService = ConfessionService();
  final PromotionService _promotionService = PromotionService();
  late final AnimationController _likeController;
  late final Animation<double> _likeScale;
  bool _isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _likeScale = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.easeOutBack),
    );
    if (widget.confession.hasVideo) {
      _initVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_handleVideoProgress);
    _videoController?.dispose();
    _likeController.dispose();
    super.dispose();
  }

  void _initVideoPlayer() {
    final resolvedUrl = _resolveMediaUrl(widget.confession.videoUrl);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _isVideoInitialized = false;
        _videoInitError = true;
      });
      return;
    }
    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            _videoController?.setLooping(true);
            _videoController?.setVolume(_isMuted ? 0 : 1);
            if (_isVideoVisible) {
              _videoController?.play();
            } else {
              _videoController?.pause();
            }
            _videoController?.addListener(_handleVideoProgress);
            setState(() {
              _isVideoInitialized = true;
              _videoInitError = false;
            });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              _isVideoInitialized = false;
              _videoInitError = true;
            });
          });
  }

  String _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final cleaned = url.replaceAll('\\', '/');
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final baseUri = Uri.parse(base);

    if (cleaned.startsWith('http')) {
      final mediaUri = Uri.parse(cleaned);
      if (mediaUri.host != baseUri.host || mediaUri.port != baseUri.port) {
        final rewritten = mediaUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        );
        return Uri.encodeFull(rewritten.toString());
      }
      return Uri.encodeFull(cleaned);
    }
    if (cleaned.startsWith('//')) return Uri.encodeFull('https:$cleaned');

    if (cleaned.startsWith('/storage/')) {
      return Uri.encodeFull('$base$cleaned');
    }
    if (cleaned.startsWith('storage/')) {
      return Uri.encodeFull('$base/$cleaned');
    }
    return Uri.encodeFull('$base/storage/$cleaned');
  }

  Confession get confession => widget.confession;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().user;
    final isOwnPost = currentUser?.id == confession.authorId;
    final imageUrl = _resolveMediaUrl(confession.imageUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;
    final actionColor = _actionIconColor(context);

    final cardContent = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Photo toujours cliquable si l'auteur existe
                  GestureDetector(
                    onTap: confession.author != null
                        ? widget.onAuthorTap
                        : null,
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo toujours cliquable si l'auteur existe
                        GestureDetector(
                          onTap: confession.author != null
                              ? widget.onAuthorTap
                              : null,
                          child: _buildAuthorInfo(context),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Helpers.getTimeAgo(confession.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (confession.isSponsored) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Sponsorisé',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (confession.type == ConfessionType.private) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 12,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.visibilityPrivate,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (confession.isAnonymous && !isOwnPost) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_off,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.userAnonymous,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, isOwnPost),
                  ),
                ],
              ),
            ),
            // Content
            if (confession.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LinkText(
                  text: confession.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
                  linkStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: _shouldTruncateContent() && !_isContentExpanded
                      ? 6
                      : null,
                  overflow: _shouldTruncateContent() && !_isContentExpanded
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                  showPreview: true,
                  previewBackgroundColor: Colors.black.withOpacity(0.04),
                  previewTextColor: AppColors.textPrimary,
                ),
              ),
            if (_shouldTruncateContent())
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isContentExpanded = !_isContentExpanded;
                    });
                  },
                  child: Text(
                    _isContentExpanded
                        ? l10n.viewLessAction
                        : l10n.viewMoreAction,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // Image
            if (hasImage)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 260,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 260,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            // Video
            if (confession.hasVideo)
              _buildVideoSection(),
            if (confession.isSponsored)
              _buildSponsoredCta(context),
            // Recipient info if private
            if (confession.recipient != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      AvatarWidget(
                        imageUrl: confession.recipient!.avatar,
                        name: confession.recipient!.fullName,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.confessionForUser(
                            confession.recipient!.fullName,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: confession.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: Helpers.formatNumber(confession.likesCount),
                    color: confession.isLiked ? Colors.red : actionColor,
                    onTap: _handleLikeTap,
                    isLike: true,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: Helpers.formatNumber(confession.commentsCount),
                    color: actionColor,
                    onTap: widget.onComment,
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.visibility_rounded,
                    label: Helpers.formatNumber(confession.viewsCount),
                    color: actionColor,
                  ),
                  if (isOwnPost && confession.promotionId != null) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showPromotionStats,
                      icon: const Icon(Icons.bar_chart, size: 16),
                      label: const Text('Stats'),
                    ),
                    const SizedBox(width: 8),
                  ] else if (isOwnPost) ...[
                    const Spacer(),
                    _buildBoostButton(context),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Partager',
                    color: actionColor,
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!confession.isSponsored) return cardContent;

    return VisibilityDetector(
      key: ValueKey('confession_impression_${confession.id}'),
      onVisibilityChanged: (info) {
        if (_hasReportedPromotionImpression) return;
        if (info.visibleFraction >= 0.6) {
          _hasReportedPromotionImpression = true;
          _reportPromotionImpression();
        }
      },
      child: cardContent,
    );
  }

  Widget _buildAvatar() {
    final l10n = AppLocalizations.of(context)!;
    // Toujours afficher la photo si l'auteur existe et a une photo
    if (confession.author != null && confession.author!.avatar != null) {
      return AvatarWidget(
        imageUrl: confession.author!.avatar,
        name: confession.shouldShowAuthor
            ? confession.author!.fullName
            : l10n.userAnonymous,
        size: 44,
      );
    }
    // Sinon afficher l'icône anonyme par défaut
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person_off, color: Colors.white, size: 22),
      ),
    );
  }

  bool _shouldTruncateContent() {
    final content = confession.content.trim();
    if (content.isEmpty) return false;
    final lineBreaks = '\n'.allMatches(content).length + 1;
    return content.length > 240 || lineBreaks > 6;
  }

  Widget _buildVideoSection() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: Center(
          child: _videoInitError
              ? const Icon(Icons.error_outline, color: Colors.grey)
              : const CircularProgressIndicator(),
        ),
      );
    }

    return VisibilityDetector(
      key: ValueKey('confession_video_${confession.id}'),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction >= 0.6;
        if (_isVideoVisible == isVisible) return;
        _isVideoVisible = isVisible;
        if (!_isVideoInitialized || _videoController == null) return;
        if (isVisible) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 52,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        _videoController?.setVolume(_isMuted ? 0 : 1);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: Colors.white.withOpacity(0.4),
              backgroundColor: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  void _handleVideoProgress() {
    if (_hasReportedView) return;
    if (!_isVideoVisible || !_isVideoInitialized || _videoController == null)
      return;
    final duration = _videoController!.value.duration;
    if (duration.inMilliseconds == 0) return;
    final position = _videoController!.value.position;
    final progress = position.inMilliseconds / duration.inMilliseconds;
    if (progress >= 0.3) {
      _hasReportedView = true;
      _reportVideoView();
    }
  }

  Future<void> _reportVideoView() async {
    final currentUserId = context.read<AuthProvider>().user?.id ?? -1;
    if (confession.authorId == currentUserId) {
      return;
    }
    try {
      await _confessionService.markViewed(confession.id);
    } catch (_) {}
  }

  Future<void> _reportPromotionImpression() async {
    try {
      await _confessionService.markPromotionImpression(confession.id);
    } catch (_) {}
  }

  Future<void> _reportPromotionClick() async {
    try {
      await _confessionService.markPromotionClick(confession.id);
    } catch (_) {}
  }

  Widget _buildSponsoredCta(BuildContext context) {
    final label = confession.promotionCtaLabel ?? 'Voir plus';
    final websiteUrl = confession.promotionWebsiteUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            await _reportPromotionClick();
            if (websiteUrl != null && websiteUrl.isNotEmpty) {
              final uri = Uri.tryParse(websiteUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return;
              }
            }
            widget.onAuthorTap?.call();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _showPromotionStats() async {
    final promotionId = confession.promotionId;
    if (promotionId == null) return;
    try {
      final response = await _promotionService.getPromotionStats(promotionId);
      final stats = response['data'] ?? {};
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques sponsorisées',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _statRow('Impressions', '${stats['impressions'] ?? 0}'),
                _statRow('Clics', '${stats['clicks'] ?? 0}'),
                _statRow('CTR', '${stats['ctr'] ?? 0}%'),
                _statRow('Budget dépensé', '${stats['budget_spent'] ?? 0}'),
                _statRow('Reach estimé', '${stats['estimated_reach'] ?? '-'}'),
                _statRow('Vues estimées', '${stats['estimated_views'] ?? '-'}'),
                _statRow('Temps restant', '${stats['time_remaining'] ?? '-'}'),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().user;
    final isOwnPost = currentUser?.id == confession.authorId;
    if ((confession.shouldShowAuthor || isOwnPost) && confession.author != null) {
      return NameWithBadge(
        name: confession.author!.fullName,
        isPremium: confession.author!.isPremium,
        isVerified: confession.author!.isVerified,
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        badgeSize: 16,
      );
    }
    return Text(
      l10n.userAnonymous,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildBoostButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        if (widget.onPromote != null) {
          widget.onPromote?.call();
        } else {
          PromotePostModal.show(
            context,
            confessionId: confession.id,
            onPromoted: () {
              try {
                context.read<FeedProvider>().refresh();
              } catch (_) {}
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              l10n.boostAction,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    bool isLike = false,
  }) {
    final fillColor = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (isLike)
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: fillColor,
                  ),
                  if (_isLikeAnimating)
                    ScaleTransition(
                      scale: _likeScale,
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 22,
                        color: Colors.red,
                      ),
                    ),
                ],
              )
            else
              Icon(
                icon,
                size: 20,
                color: fillColor,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fillColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  void _handleLikeTap() {
    if (confession.isLiked) {
      widget.onLike?.call();
      return;
    }

    setState(() {
      _isLikeAnimating = true;
    });
    _likeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 180), () {
      widget.onLike?.call();
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() {
          _isLikeAnimating = false;
        });
      }
    });
  }

  void _showOptions(BuildContext context, bool isOwnPost) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option promouvoir pour ses propres publications
              if (isOwnPost)
                ListTile(
                  leading: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Icon(Icons.trending_up, color: Colors.white),
                  ),
                  title: Text(l10n.profilePromote),
                  subtitle: Text(l10n.profilePromoteSubtitle),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (widget.onPromote != null) {
                      widget.onPromote?.call();
                    } else {
                      // Ouvrir directement le modal de promotion
                      PromotePostModal.show(
                        context,
                        confessionId: confession.id,
                        onPromoted: () {
                          // Rafraîchir si possible
                          try {
                            context.read<FeedProvider>().refresh();
                          } catch (_) {}
                        },
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(l10n.shareAction),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onShare?.call();
                },
              ),
              if (isOwnPost)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    l10n.deleteAction,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              if (!isOwnPost)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(l10n.reportAction),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _showReportDialog(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    const reasons = [
      {'value': 'spam', 'label': 'Spam'},
      {'value': 'harassment', 'label': 'Harcèlement'},
      {'value': 'hate_speech', 'label': 'Discours haineux'},
      {'value': 'inappropriate_content', 'label': 'Contenu inapproprié'},
      {'value': 'impersonation', 'label': 'Usurpation d’identité'},
      {'value': 'other', 'label': 'Autre'},
    ];

    String? selectedReason;
    final descriptionController = TextEditingController();
    bool isOtherReason() => selectedReason == 'other';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.reportAction),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        value: reason['value']!,
                        groupValue: selectedReason,
                        onChanged: (value) => setState(() => selectedReason = value),
                        title: Text(reason['label']!),
                      ),
                    ),
                    if (isOtherReason())
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Expliquez brièvement la raison...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedReason == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez choisir une raison.')),
                      );
                      return;
                    }
                    if (isOtherReason() && descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez ajouter une description.')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.reportAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedReason == null) {
      descriptionController.dispose();
      return;
    }

    try {
      await _confessionService.reportConfession(
        confession.id,
        reason: selectedReason,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement envoyé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      descriptionController.dispose();
    }
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeletePostTitle),
        content: Text(l10n.profileDeletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final confessionService = ConfessionService();
                await confessionService.deleteConfession(confession.id);
                widget.onDeleted?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.postDeletedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorMessage(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.deleteAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
