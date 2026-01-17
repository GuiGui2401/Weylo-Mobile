import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stories/stories_bar.dart';
import '../../widgets/confessions/confession_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/promotions/promote_post_modal.dart';
import '../../services/confession_service.dart';
import '../stories/create_story_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadConfessions(refresh: true);
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    await context.read<FeedProvider>().refresh();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await context.read<FeedProvider>().loadMore();
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'Weylo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.search, color: Colors.white),
            ),
            onPressed: () {
              context.push('/search');
            },
            tooltip: 'Rechercher',
          ),
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.add_box_outlined, color: Colors.white),
            ),
            onPressed: () {
              _showCreatePostSheet();
            },
          ),
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () {
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          if (feedProvider.isLoading && feedProvider.confessions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (feedProvider.error != null && feedProvider.confessions.isEmpty) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Erreur de chargement',
              subtitle: feedProvider.error!,
              actionLabel: 'Réessayer',
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
                const SliverToBoxAdapter(
                  child: StoriesBar(),
                ),

                // Confessions feed
                if (feedProvider.confessions.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.article_outlined,
                      title: 'Aucune publication',
                      subtitle: 'Soyez le premier à publier!',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                          onPromote: isOwnPost ? () {
                            _showPromoteSheet(confession.id);
                          } : null,
                          onAuthorTap: () {
                            if (confession.author != null &&
                                confession.author!.username.isNotEmpty) {
                              context.push('/u/${confession.author!.username}');
                            }
                          },
                        );
                      },
                      childCount: feedProvider.confessions.length,
                    ),
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
    final shareUrl = 'https://weylo.app/post/$confessionId';
    Share.share(
      'Découvre cette publication sur Weylo! $shareUrl',
      subject: 'Publication Weylo',
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
      });
    }
  }

  Future<void> _publishPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire quelque chose ou ajouter une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _confessionService.createConfession(
        content: content.isNotEmpty ? content : '',
        type: 'public',
        isAnonymous: !_isPublic,
        image: _selectedImage,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPostCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publication créée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Text('Annuler'),
                ),
                const Text(
                  'Nouvelle publication',
                  style: TextStyle(
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
                      : const Text('Publier'),
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
                    decoration: const InputDecoration(
                      hintText: 'Exprimez-vous...',
                      border: InputBorder.none,
                    ),
                  ),

                  // Selected image preview
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
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
                    color: _selectedImage != null ? AppColors.primary : Colors.grey[600],
                  ),
                  onPressed: _pickImage,
                  tooltip: 'Ajouter une image',
                ),
                // GIF button
                IconButton(
                  icon: Icon(
                    Icons.gif_box_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: _pickGif,
                  tooltip: 'Ajouter un GIF',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          _isPublic ? 'Public' : 'Anonyme',
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
