import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/story.dart';
import '../../models/user.dart';
import '../../services/story_service.dart';
import '../../services/story_reply_service.dart';
import '../../services/widgets/stories/story_reply_input.dart';
import '../../services/widgets/common/avatar_widget.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final User user;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  final StoryService _storyService = StoryService();
  final StoryReplyService _replyService = StoryReplyService();

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isReplying = false;
  bool _showComments = false;
  List<StoryComment> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStory(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    final story = widget.stories[index];

    // Mark as viewed
    _storyService.markAsViewed(story.id);

    // Reset progress
    _progressController.reset();

    // Handle video stories
    if (story.type == StoryType.video && story.mediaUrl != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl!),
      )..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _progressController.duration = _videoController!.value.duration;
          _progressController.forward();
        });
    } else {
      _progressController.duration = Duration(seconds: story.duration ?? 5);
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _loadStory(_currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _loadStory(_currentIndex);
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      _progressController.stop();
      _videoController?.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeStory() {
    if (_isPaused && !_isReplying) {
      _progressController.forward();
      _videoController?.play();
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _toggleReplyMode() {
    setState(() {
      _isReplying = !_isReplying;
    });
    if (_isReplying) {
      _pauseStory();
    } else {
      _resumeStory();
    }
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
    if (_showComments) {
      _pauseStory();
      if (_comments.isEmpty) {
        _loadComments();
      }
    } else {
      _resumeStory();
    }
  }

  Future<void> _loadComments() async {
    final story = widget.stories[_currentIndex];
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final comments = await _storyService.getComments(story.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _addComment(String content) async {
    final story = widget.stories[_currentIndex];
    try {
      final comment = await _storyService.addComment(story.id, content);
      setState(() {
        _comments.insert(0, comment);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout du commentaire')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),

            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double progress = 0;
                          if (index < _currentIndex) {
                            progress = 1;
                          } else if (index == _currentIndex) {
                            progress = _progressController.value;
                          }
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),

            // User info
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.user.avatar != null
                        ? CachedNetworkImageProvider(widget.user.avatar!)
                        : null,
                    child: widget.user.avatar == null
                        ? Text(widget.user.initials)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(story.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: Colors.white),
                    onPressed: _toggleComments,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Comments overlay
            if (_showComments) _buildCommentsOverlay(),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Comments button above reply input
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _toggleComments,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _comments.isEmpty
                          ? 'Voir les commentaires'
                          : 'Voir les ${_comments.length} commentaire${_comments.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Reply input
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: StoryReplyInput(
                storyId: story.id,
                isExpanded: _isReplying,
                onTap: _toggleReplyMode,
                onSend: (content, {isAnonymous = true, voiceFile, voiceEffect}) async {
                  try {
                    if (voiceFile != null) {
                      await _replyService.sendVoiceReply(
                        storyId: story.id,
                        audioFile: voiceFile,
                        voiceEffect: voiceEffect,
                        isAnonymous: isAnonymous,
                      );
                    } else {
                      await _replyService.sendTextReply(
                        storyId: story.id,
                        content: content,
                        isAnonymous: isAnonymous,
                      );
                    }
                    _toggleReplyMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Réponse envoyée')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de l\'envoi')),
                    );
                  }
                },
                onClose: _toggleReplyMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsOverlay() {
    final TextEditingController commentController = TextEditingController();

    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleComments,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Commentaires',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _toggleComments,
                      ),
                    ],
                  ),
                ),

                // Comments list
                Expanded(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on comments
                    child: _isLoadingComments
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : _comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun commentaire',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Soyez le premier à commenter !',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  return _buildCommentItem(comment);
                                },
                              ),
                  ),
                ),

                // Comment input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              _addComment(commentController.text.trim());
                              commentController.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(StoryComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(
            imageUrl: comment.user?.avatar,
            name: comment.user?.fullName ?? 'Utilisateur',
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Helpers.getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                // Replies
                if (comment.replies != null && comment.replies!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.replies!.map((reply) => Padding(
                        padding: const EdgeInsets.only(left: 24, top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarWidget(
                              imageUrl: reply.user?.avatar,
                              name: reply.user?.fullName ?? 'Utilisateur',
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply.user?.fullName ?? 'Utilisateur',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    reply.content,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    switch (story.type) {
      case StoryType.image:
        return story.mediaUrl != null
            ? CachedNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : const SizedBox();

      case StoryType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );

      case StoryType.text:
        return Container(
          color: _parseColor(story.backgroundColor),
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              story.content ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return AppColors.primary;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    }
    return 'Il y a ${difference.inDays}j';
  }
}
