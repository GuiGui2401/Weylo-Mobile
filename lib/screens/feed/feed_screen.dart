import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/deep_link_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/widgets/stories/stories_bar.dart';
import '../../services/widgets/confessions/confession_card.dart';
import '../../services/widgets/common/empty_state.dart';
import '../../services/widgets/promotions/promote_post_modal.dart';
import '../../services/confession_service.dart';
import '../stories/create_story_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RefreshController _refreshController = RefreshController();
  final ChatService _chatService = ChatService();
  int _maxStreakCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadConfessions(refresh: true);
    });
    _loadMaxStreak();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    await context.read<FeedProvider>().refresh();
    await _loadMaxStreak();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await context.read<FeedProvider>().loadMore();
    _refreshController.loadComplete();
  }

  Future<void> _loadMaxStreak() async {
    try {
      final conversations = await _chatService.getConversations();
      final maxStreak = conversations.fold<int>(
        0,
        (maxValue, conv) => conv.streakCount > maxValue ? conv.streakCount : maxValue,
      );
      if (mounted) {
        setState(() {
          _maxStreakCount = maxStreak;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actionColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'Weylo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FlameBadge(count: _maxStreakCount),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: actionColor),
            onPressed: () {
              context.push('/search');
            },
            tooltip: l10n.searchAction,
          ),
          IconButton(
            icon: Icon(Icons.add_rounded, color: actionColor),
            onPressed: () {
              _showCreatePostSheet();
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: actionColor),
            onPressed: () {
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.confessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (feedProvider.error != null && feedProvider.confessions.isEmpty) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.loadingErrorTitle,
              subtitle: feedProvider.error!,
              actionLabel: l10n.retry,
              onAction: () => feedProvider.refresh(),
            );
          }

          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: feedProvider.hasMore,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: const WaterDropMaterialHeader(
              backgroundColor: AppColors.primary,
            ),
            child: CustomScrollView(
              slivers: [
                // Stories bar
                const SliverToBoxAdapter(child: StoriesBar()),

                // Confessions feed
                if (feedProvider.confessions.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.article_outlined,
                      title: l10n.feedEmptyTitle,
                      subtitle: l10n.feedEmptySubtitle,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final confession = feedProvider.confessions[index];
                      final currentUser = context.read<AuthProvider>().user;
                      final isOwnPost = currentUser?.id == confession.authorId;
                      return ConfessionCard(
                        confession: confession,
                        onTap: () {
                          _navigateToConfessionDetail(confession.id);
                        },
                        onLike: () {
                          if (confession.isLiked) {
                            feedProvider.unlikeConfession(confession.id);
                          } else {
                            feedProvider.likeConfession(confession.id);
                          }
                        },
                        onComment: () {
                          _navigateToConfessionDetail(confession.id);
                        },
                        onShare: () {
                          _shareConfession(confession.id);
                        },
                        // Only allow promoting own posts
                        onPromote: isOwnPost
                            ? () {
                                _showPromoteSheet(confession.id);
                              }
                            : null,
                        onAuthorTap: () {
                          if (confession.author != null &&
                              confession.author!.username.isNotEmpty) {
                            context.push('/u/${confession.author!.username}');
                          }
                        },
                      );
                    }, childCount: feedProvider.confessions.length),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'feed_fab',
          onPressed: () => _showCreatePostSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        onPostCreated: () {
          this.context.read<FeedProvider>().refresh();
        },
      ),
    );
  }

  void _navigateToConfessionDetail(int confessionId) {
    context.push('/post/$confessionId');
  }

  void _shareConfession(int confessionId) {
    final l10n = AppLocalizations.of(context)!;
    final shareUrl = DeepLinkService.getPostShareLink(confessionId);
    Share.share(
      l10n.sharePostMessage(shareUrl),
      subject: l10n.sharePostSubject,
    );
  }

  void _showPromoteSheet(int confessionId) {
    PromotePostModal.show(
      context,
      confessionId: confessionId,
      onPromoted: () {
        context.read<FeedProvider>().refresh();
      },
    );
  }
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayCount = count < 0 ? 0 : count;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 20,
          color: Color(0xFFFF8A00),
        ),
        Positioned(
          top: 7,
          child: Text(
            '$displayCount',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for creating a new post
class _CreatePostSheet extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const _CreatePostSheet({this.onPostCreated});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  final ConfessionService _confessionService = ConfessionService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  File? _selectedVideo;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null;
      });
    }
  }

  Future<void> _pickGif() async {
    // For now, use gallery - in production you'd use a GIF picker like giphy_picker
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedImage = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null;
      });
    }
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (content.isEmpty && _selectedImage == null && _selectedVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addContentOrMediaError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _confessionService.createConfession(
        content: content.isNotEmpty ? content : '',
        type: 'public',
        isAnonymous: !_isPublic,
        image: _selectedImage,
        video: _selectedVideo,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPostCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.postCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                Text(
                  l10n.createPostTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _publishPost,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.publishAction),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Text input
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: l10n.feedPostHint,
                      border: InputBorder.none,
                    ),
                  ),

                  // Selected media preview
                  if (_selectedImage != null || _selectedVideo != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        size: 48,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.videoSelectedLabel,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _selectedVideo = null;
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
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                // Image button
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    color: _selectedImage != null
                        ? AppColors.primary
                        : Colors.grey[600],
                  ),
                  onPressed: _pickImage,
                  tooltip: l10n.addImageAction,
                ),
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: _takePhoto,
                  tooltip: l10n.takePhotoAction,
                ),
                // GIF button
                IconButton(
                  icon: Icon(Icons.gif_box_outlined, color: Colors.grey[600]),
                  onPressed: _pickGif,
                  tooltip: l10n.addGifAction,
                ),
                IconButton(
                  icon: Icon(
                    Icons.videocam_outlined,
                    color: _selectedVideo != null
                        ? AppColors.primary
                        : Colors.grey[600],
                  ),
                  onPressed: _pickVideo,
                  tooltip: l10n.addVideoAction,
                ),
                const Spacer(),
                // Visibility selector
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPublic = !_isPublic;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPublic
                              ? l10n.visibilityPublic
                              : l10n.visibilityAnonymous,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
