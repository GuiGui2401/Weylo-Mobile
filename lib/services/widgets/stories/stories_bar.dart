import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/story.dart';
import '../../../providers/auth_provider.dart';
import '../../story_service.dart';
import '../common/avatar_widget.dart';

final Map<String, Future<Uint8List?>> _storyVideoThumbCache = {};

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> with WidgetsBindingObserver {
  final StoryService _storyService = StoryService();
  List<UserStories> _stories = [];
  List<Story> _myStories = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStories();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadStories();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStories();
    }
  }

  Future<void> _loadStories() async {
    try {
      final user = context.read<AuthProvider>().user;
      final results = await Future.wait([
        _storyService.getFeed(),
        _storyService.getMyStories(),
      ]);

      // Filter out the current user's stories from the feed to avoid duplication
      // Use realUserId to correctly identify the user even for anonymous stories
      var feedStories = results[0] as List<UserStories>;
      if (user != null) {
        feedStories = feedStories
            .where((s) => s.realUserId != user.id)
            .toList();
      }

      // Also remove duplicates based on realUserId (not user.id which can be null for anonymous)
      final seenUserIds = <int>{};
      feedStories = feedStories.where((s) {
        final id = s.realUserId > 0 ? s.realUserId : s.user.id;
        if (id <= 0 || seenUserIds.contains(id)) {
          return false;
        }
        seenUserIds.add(id);
        return true;
      }).toList();

      // Les stories sont déjà filtrées par le backend (actives uniquement)
      final myStories = results[1] as List<Story>;

      if (mounted) {
        setState(() {
          _stories = feedStories;
          _myStories = myStories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;

    if (_isLoading) {
      return Container(
        height: 180,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildMyStoryCard(context, user, l10n);
          }
          final userStories = _stories[index - 1];
          return _StoryCard(
            userStories: userStories,
            onTap: () {
              // Utiliser realUserId pour la navigation
              final userId = userStories.realUserId > 0
                  ? userStories.realUserId
                  : userStories.user.id;
              if (userId > 0) {
                context.push('/stories/$userId');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMyStoryCard(BuildContext context, user, AppLocalizations l10n) {
    final hasStory = _myStories.isNotEmpty;
    final lastStory = hasStory ? _myStories.first : null;

    return GestureDetector(
      onTap: () async {
        if (hasStory) {
          await context.push('/my-stories');
        } else {
          await context.push('/create-story');
        }
        if (mounted) {
          _loadStories();
        }
      },
      onLongPress: hasStory
          ? () async {
              await context.push('/create-story');
              if (mounted) {
                _loadStories();
              }
            }
          : null,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasStory ? AppColors.primaryGradient : null,
          border: hasStory
              ? null
              : Border.all(color: Colors.grey.shade300, width: 2),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background - dernière story ou avatar
                if (lastStory != null && lastStory.isVideo)
                  lastStory.thumbnailUrl != null
                      ? _buildStoryVideoThumbnail(lastStory.thumbnailUrl!)
                      : _buildStoryVideoThumbnailFromUrl(lastStory.mediaUrl)
                else if (lastStory != null && lastStory.mediaUrl != null)
                  CachedNetworkImage(
                    imageUrl: lastStory.mediaUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.shimmerBase),
                    errorWidget: (_, __, ___) => _buildAvatarBackground(user),
                  )
                else if (lastStory != null && lastStory.isText)
                  Container(
                    color: Color(
                      int.parse(
                        (lastStory.backgroundColor ?? '#8B5CF6').replaceFirst(
                          '#',
                          '0xFF',
                        ),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          lastStory.content ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  _buildAvatarBackground(user),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // Add button
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
                // Label
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    l10n.myStatusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarBackground(user) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: AvatarWidget(
          imageUrl: user?.avatar,
          name: user?.fullName ?? l10n.meLabel,
          size: 50,
        ),
      ),
    );
  }

  
}

class _StoryCard extends StatelessWidget {
  final UserStories userStories;
  final VoidCallback? onTap;

  const _StoryCard({required this.userStories, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAnonymous = userStories.isAnonymous;
    final isHidden = isAnonymous && !userStories.isIdentityRevealed;
    final displayName = isHidden
        ? l10n.userAnonymous
        : userStories.user.fullName;
    final hasUnviewed = userStories.hasUnviewed;
    final preview = userStories.preview;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background based on preview
                _buildPreviewBackground(preview, isAnonymous),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Avatar en haut à gauche
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnviewed ? AppColors.primary : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: isHidden
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_off,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        : ClipOval(
                            child: userStories.user.avatar != null
                                ? CachedNetworkImage(
                                    imageUrl: userStories.user.avatar!,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 28,
                                      height: 28,
                                      color: AppColors.shimmerBase,
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 28,
                                      height: 28,
                                      color: AppColors.primary,
                                      child: Center(
                                        child: Text(
                                          userStories.user.firstName.isNotEmpty
                                              ? userStories.user.firstName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 28,
                                    height: 28,
                                    color: AppColors.primary,
                                    child: Center(
                                      child: Text(
                                        userStories.user.firstName.isNotEmpty
                                            ? userStories.user.firstName[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                  ),
                ),
                // Nom en bas
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: hasUnviewed
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBackground(StoryPreview? preview, bool isAnonymous) {
    if (preview == null) {
      return Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      );
    }

    if (preview.type == 'video') {
      if (preview.thumbnailUrl != null) {
        return _buildStoryVideoThumbnail(preview.thumbnailUrl!);
      }
      if (preview.mediaUrl != null && preview.mediaUrl!.isNotEmpty) {
        return _buildStoryVideoThumbnailFromUrl(preview.mediaUrl);
      }
      return _buildStoryVideoPlaceholder();
    }

    if (preview.type == 'image' && preview.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: preview.mediaUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      );
    }

    if (preview.type == 'text') {
      final bgColor = preview.backgroundColor ?? '#8B5CF6';
      return Container(
        color: Color(int.parse(bgColor.replaceFirst('#', '0xFF'))),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              preview.content ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
    );
  }
}

Widget _buildStoryVideoThumbnail(String url) {
  return Stack(
    fit: StackFit.expand,
    children: [
      CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.shimmerBase),
        errorWidget: (_, __, ___) => _buildStoryVideoPlaceholder(),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            size: 10,
            color: Colors.white70,
          ),
        ),
      ),
    ],
  );
}

Widget _buildStoryVideoThumbnailFromUrl(String? url) {
  if (url == null || url.isEmpty) {
    return _buildStoryVideoPlaceholder();
  }

  final future = _storyVideoThumbCache.putIfAbsent(
    url,
    () => VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.JPEG,
      quality: 70,
      maxWidth: 720,
    ),
  );

  return FutureBuilder<Uint8List?>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.data != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 10,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        );
      }
      return _buildStoryVideoPlaceholder();
    },
  );
}

Widget _buildStoryVideoPlaceholder() {
  return Container(
    color: Colors.black,
    child: const Center(
      child: Icon(
        Icons.play_circle_fill,
        color: Colors.white,
        size: 42,
      ),
    ),
  );
}
