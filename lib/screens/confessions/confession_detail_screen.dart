import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/media_utils.dart';
import '../../models/confession.dart';
import '../../services/confession_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/widgets/common/avatar_widget.dart';
import '../../services/widgets/common/link_text.dart';
import '../../services/widgets/common/premium_badge.dart';
import '../../providers/auth_provider.dart';

class ConfessionDetailScreen extends StatefulWidget {
  final int confessionId;

  const ConfessionDetailScreen({super.key, required this.confessionId});

  @override
  State<ConfessionDetailScreen> createState() => _ConfessionDetailScreenState();
}

class _ConfessionDetailScreenState extends State<ConfessionDetailScreen> {
  final ConfessionService _confessionService = ConfessionService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Confession? _confession;
  List<ConfessionComment> _comments = [];
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoInitError = false;
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  File? _selectedCommentImage;
  ConfessionComment? _replyToComment;
  String? _error;
  final Set<int> _commentLikeLoading = {};
  final Set<int> _commentLikeAnimating = {};
  bool _hasManualLikeState = false;
  bool? _manualLikeState;

  @override
  void initState() {
    super.initState();
    _loadConfession();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadConfession() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final confession = await _confessionService.getConfession(
        widget.confessionId,
      );

      final displayConfession = _applyManualLikeState(confession);
      setState(() {
        _confession = displayConfession;
        _isLoading = false;
      });

      if (confession.hasVideo) {
        _initVideoPlayer(confession.videoUrl);
      } else {
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
        _videoInitError = false;
      }

      _loadComments();
    } catch (e) {
      setState(() {
        _error = l10n.loadingErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  void _initVideoPlayer(String? url) {
    final resolvedUrl = resolveMediaUrl(url);
    if (resolvedUrl.isEmpty) {
      setState(() {
        _isVideoInitialized = false;
        _videoInitError = true;
      });
      return;
    }

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl))
      ..initialize()
          .then((_) {
            if (!mounted) return;
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

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoadingComments = true);

      final comments = await _confessionService.getComments(
        widget.confessionId,
      );

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
        if (_confession != null) {
          _confession = _confession!.copyWith(commentsCount: comments.length);
        }
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  Confession _applyManualLikeState(Confession confession) {
    if (!_hasManualLikeState || _manualLikeState == null) {
      return confession;
    }
    if (_manualLikeState == confession.isLiked) {
      _hasManualLikeState = false;
      return confession;
    }
    return confession.copyWith(isLiked: _manualLikeState);
  }

  String _resolveMediaUrl(String? url) {
    final resolved = resolveMediaUrl(url);
    return resolved.isEmpty ? '' : resolved;
  }

  Future<void> _sendComment() async {
    final l10n = AppLocalizations.of(context)!;
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedCommentImage == null) return;

    try {
      setState(() => _isSendingComment = true);

      final comment = await _confessionService.addComment(
        widget.confessionId,
        content,
        image: _selectedCommentImage,
        parentId: _replyToComment?.id,
      );

      _commentController.clear();
      setState(() {
        _selectedCommentImage = null;
        _replyToComment = null;
      });

      setState(() {
        _comments.insert(0, comment);
        _isSendingComment = false;
        if (_confession != null) {
          _confession = _confession!.copyWith(
            commentsCount: _confession!.commentsCount + 1,
          );
        }
      });

      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => _isSendingComment = false);
      if (mounted) {
        Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
      }
    }
  }

  Future<void> _toggleLike() async {
    final l10n = AppLocalizations.of(context)!;
    if (_confession == null) return;

    try {
      if (_confession!.isLiked) {
        final updated = await _confessionService.unlikeConfession(
          widget.confessionId,
        );
        setState(() {
          _manualLikeState = updated.isLiked;
          _hasManualLikeState = true;
          _confession = updated;
        });
      } else {
        final updated = await _confessionService.likeConfession(
          widget.confessionId,
        );
        setState(() {
          _manualLikeState = updated.isLiked;
          _hasManualLikeState = true;
          _confession = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
      }
    }
  }

  Future<void> _shareConfession() async {
    if (_confession == null) return;

    final l10n = AppLocalizations.of(context)!;
    final shareUrl = DeepLinkService.getPostShareLink(_confession!.id);
    await Share.share(
      l10n.sharePostMessage(shareUrl),
      subject: l10n.sharePostSubject,
    );
    try {
      final sharesCount = await _confessionService.shareConfession(
        _confession!.id,
      );
      if (mounted) {
        setState(() {
          _confession = _confession!.copyWith(sharesCount: sharesCount);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareConfession,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadConfession, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (_confession == null) {
      return Center(child: Text(l10n.postNotFound));
    }

    return RefreshIndicator(
      onRefresh: _loadConfession,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfessionCard(),
            const Divider(height: 1),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfessionCard() {
    final confession = _confession!;
    final imageUrl = resolveMediaUrl(confession.imageUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;
    final hasVideo = confession.hasVideo;
    final l10n = AppLocalizations.of(context)!;
    final actionColor = _actionIconColor(context);
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwnPost = currentUserId != null && confession.authorId == currentUserId;
    final canShowAuthor = confession.isIdentityRevealed || isOwnPost;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (canShowAuthor && confession.author != null) {
                    context.push('/u/${confession.author!.username}');
                  }
                },
                child: _buildAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (canShowAuthor && confession.author != null) {
                          context.push('/u/${confession.author!.username}');
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            canShowAuthor && confession.author != null
                                ? confession.author!.fullName
                                : l10n.userAnonymous,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (confession.author?.isPremium == true) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 14),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          Helpers.getTimeAgo(confession.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (confession.isSponsored) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptions(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (confession.content.isNotEmpty)
            LinkText(
              text: confession.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.5,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              linkStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                height: 1.5,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
              showPreview: true,
              previewBackgroundColor: Colors.black.withOpacity(0.04),
              previewTextColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),

          // Image
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],

          if (hasVideo) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isVideoInitialized && _videoController != null
                  ? AspectRatio(
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
                              size: 56,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: _videoInitError
                            ? const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
            ),
          ],

          if (confession.isSponsored) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _confessionService.markPromotionClick(confession.id);
                  final url = confession.promotionWebsiteUrl;
                  if (url != null && url.isNotEmpty) {
                    final uri = Uri.tryParse(url);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      return;
                    }
                  }
                  if (confession.author != null) {
                    // ignore: use_build_context_synchronously
                    context.push('/u/${confession.author!.username}');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  confession.promotionCtaLabel ?? 'Voir plus',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                l10n.viewsCount(Helpers.formatNumber(confession.viewsCount)),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                l10n.likesCount(Helpers.formatNumber(confession.likesCount)),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                l10n.commentsCount(
                  Helpers.formatNumber(confession.commentsCount),
                ),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTwitterActionButton(
                icon: confession.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: l10n.likeAction,
                color: actionColor,
                onTap: _toggleLike,
              ),
              _buildTwitterActionButton(
                icon: Icons.mode_comment_rounded,
                label: l10n.commentAction,
                color: actionColor,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              _buildTwitterActionButton(
                icon: Icons.share_rounded,
                label: l10n.shareAction,
                color: actionColor,
                onTap: _shareConfession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final fillColor = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fillColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fillColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.grey.shade600;
  }

  Widget _buildAvatar() {
    if (_confession!.isIdentityRevealed && _confession!.author != null) {
      return AvatarWidget(
        imageUrl: _confession!.author!.avatar,
        name: _confession!.author!.fullName,
        size: 48,
      );
    }
    // Avatar anonyme
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person_off, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.commentsCountTitle(_confession?.commentsCount ?? 0),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        if (_isLoadingComments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCommentsTitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noCommentsSubtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildCommentItem(_comments[index]);
            },
          ),

        // Add some padding at the bottom
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCommentItem(ConfessionComment comment) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMine = currentUserId != null && comment.user?.id == currentUserId;
    final resolvedMediaUrl = _resolveMediaUrl(
      comment.mediaFullUrl ?? comment.mediaUrl,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onLongPress: isMine
            ? () {
                _showCommentActions(comment);
              }
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (comment.user != null) {
                  context.push('/u/${comment.user!.username}');
                }
              },
              child: AvatarWidget(
                imageUrl: comment.user?.avatar,
                name: comment.user?.fullName ?? l10n.userFallback,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (comment.user != null) {
                            context.push('/u/${comment.user!.username}');
                          }
                        },
                        child: Text(
                          comment.user?.fullName ?? l10n.userFallback,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (comment.user?.isPremium == true) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 12),
                      ],
                      const Spacer(),
                      Text(
                        Helpers.getTimeAgo(comment.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (comment.parent != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.parent?.user?.fullName ??
                                      l10n.userAnonymous,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comment.parent?.content ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (comment.content.isNotEmpty)
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  if (resolvedMediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: resolvedMediaUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  comment.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: comment.isLiked
                                      ? Colors.redAccent
                                      : Colors.grey[600],
                                ),
                                if (_commentLikeAnimating.contains(comment.id))
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.6, end: 1.2),
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutBack,
                                    builder: (context, scale, child) =>
                                        Transform.scale(
                                      scale: scale,
                                      child: child,
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyToComment = comment;
                          });
                        },
                        child: Text(
                          l10n.replyAction,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCommentLike(ConfessionComment comment) async {
    if (_confession == null || _commentLikeLoading.contains(comment.id)) {
      return;
    }

    setState(() {
      _commentLikeLoading.add(comment.id);
    });

    try {
      if (!comment.isLiked) {
        setState(() {
          _commentLikeAnimating.add(comment.id);
        });
        Future.delayed(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          setState(() {
            _commentLikeAnimating.remove(comment.id);
          });
        });
      }

      final response = comment.isLiked
          ? await _confessionService.unlikeComment(
              _confession!.id,
              comment.id,
            )
          : await _confessionService.likeComment(
              _confession!.id,
              comment.id,
            );

      final likesCount =
          response['likes_count'] ?? response['likesCount'] ?? comment.likesCount;
      final isLiked = response['is_liked'] ?? response['isLiked'] ?? !comment.isLiked;

      setState(() {
        _comments = _comments
            .map(
              (c) => c.id == comment.id
                  ? c.copyWith(likesCount: likesCount, isLiked: isLiked)
                  : c,
            )
            .toList();
      });
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(
          context,
          AppLocalizations.of(context)!.errorMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _commentLikeLoading.remove(comment.id);
        });
      }
    }
  }

  Future<void> _showCommentActions(ConfessionComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                l10n.deleteAction,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Supprimer le commentaire'),
                    content: const Text(
                      'Voulez-vous supprimer ce commentaire ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(l10n.deleteAction),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                try {
                  await _confessionService.deleteComment(
                    widget.confessionId,
                    comment.id,
                  );
                  setState(() {
                    _comments.removeWhere((c) => c.id == comment.id);
                    if (_confession != null) {
                      _confession = _confession!.copyWith(
                        commentsCount: (_confession!.commentsCount - 1).clamp(
                          0,
                          1 << 30,
                        ),
                      );
                    }
                  });
                  if (mounted) {
                    Helpers.showSuccessSnackBar(context, 'Commentaire supprimé');
                  }
                } catch (e) {
                  if (mounted) {
                    Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToComment != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToComment?.user?.fullName ?? l10n.userAnonymous,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToComment?.content ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _replyToComment = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_selectedCommentImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedCommentImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCommentImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                tooltip: l10n.addImageAction,
                icon: const Icon(Icons.image_outlined),
                onPressed: () async {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1080,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedCommentImage = File(image.path);
                    });
                  }
                },
              ),
              IconButton(
                tooltip: l10n.addGifAction,
                icon: const Icon(Icons.gif_box_outlined),
                onPressed: () async {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedCommentImage = File(image.path);
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: l10n.commentHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              _isSendingComment
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendComment,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.shareAction),
              onTap: () {
                Navigator.pop(context);
                _shareConfession();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.reportAction),
              onTap: () {
                Navigator.pop(context);
                _reportConfession();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportConfession() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportPostTitle),
        content: Text(l10n.reportPostPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _confessionService.reportConfession(widget.confessionId);
                if (mounted) {
                  Helpers.showSuccessSnackBar(context, l10n.reportPostSuccess);
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.reportAction),
          ),
        ],
      ),
    );
  }
}
