import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/confession.dart';
import '../../models/gift.dart';
import '../../models/user.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/gift_service.dart';
import '../../services/user_service.dart';

import '../../services/widgets/common/premium_badge.dart';
import '../messages/send_message_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final Map<String, Future<Uint8List?>> _videoThumbnails = {};


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile(widget.username);
    });
  }



  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ProfileProvider>().loadProfile(widget.username);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final user = profileProvider.profileUser;
        final isLoading = profileProvider.isLoading;
        final currentUser = context.read<AuthProvider>().user;
        final isOwnProfile = currentUser?.username == widget.username;

        return Scaffold(
          body: isLoading && user == null
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? _buildErrorState(profileProvider)
              : _buildProfileContent(user, profileProvider, isOwnProfile),
        );
      },
    );
  }

  Widget _buildErrorState(ProfileProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(provider.error ?? l10n.userNotFound),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadProfile(widget.username),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<ProfileProvider>().loadProfile(widget.username);
  }

  Widget _buildProfileContent(
    User user,
    ProfileProvider provider,
    bool isOwnProfile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: NestedScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(user, provider, isOwnProfile),
            ),
            actions: [
              if (!isOwnProfile)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') {
                      _blockUser();
                    } else if (value == 'report') {
                      _reportUser();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.block),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(l10n.report),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(text: l10n.profilePostsTab),
                  Tab(text: l10n.profileGiftsTab),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfessionsTab(provider),
          _buildGiftsTab(),
        ],
      ),
    ),
    );
  }

  Widget _buildProfileHeader(
    User user,
    ProfileProvider provider,
    bool isOwnProfile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final coverUrl = user.coverUrl;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.15),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: user.avatar != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                user.initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    // Badge vérifié bleu pour les utilisateurs premium/vérifiés
                    if (user.isPremium || user.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: const VerifiedBadge(size: 18, showTooltip: false),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(
                      '${user.followersCount}',
                      l10n.profileFollowers,
                      () => _showFollowersList(),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _buildStatItem(
                      '${user.followingCount}',
                      l10n.profileSubscriptions,
                      () => _showFollowingList(),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _buildStatItem(
                      '${user.confessionsCount ?? 0}',
                      l10n.profilePostsTab,
                      null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                if (!isOwnProfile) _buildActionButtons(user, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(User user, ProfileProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final isFollowing = user.isFollowing ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow/Unfollow button avec dégradé
        Container(
          decoration: BoxDecoration(
            gradient: isFollowing ? null : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            border: isFollowing
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Material(
            color: isFollowing
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              onTap: provider.isFollowLoading
                  ? null
                  : () {
                      if (isFollowing) {
                        provider.unfollowUser(user.username);
                      } else {
                        provider.followUser(user.username);
                      }
                    },
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                child: provider.isFollowLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing ? Icons.check : Icons.person_add,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFollowing ? l10n.followed : l10n.follow,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Message button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              onTap: () => _sendMessage(user),
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfessionsTab(ProfileProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final confessions = provider.userConfessions;

    if (confessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.profileNoPostsTitle,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: confessions.length,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) => _buildConfessionTile(confessions[index]),
    );
  }

  Widget _buildConfessionTile(Confession confession) {
    final imageUrl = _resolveMediaUrl(confession.imageUrl);
    final videoUrl = _resolveMediaUrl(confession.videoUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;
    final hasVideo = confession.hasVideo && videoUrl.isNotEmpty;

    return InkWell(
      onTap: () => context.push('/confession/${confession.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.05),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, _) =>
                      _buildConfessionPlaceholder(hasVideo: hasVideo),
                  errorWidget: (context, _, __) =>
                      _buildConfessionPlaceholder(hasVideo: hasVideo),
                )
              else if (hasVideo)
                _buildVideoThumbnail(videoUrl)
              else
                _buildConfessionPlaceholder(hasVideo: hasVideo),
              if (hasVideo)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              if (!hasImage)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    confession.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfessionPlaceholder({required bool hasVideo}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.15),
            Colors.black.withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          hasVideo ? Icons.videocam : Icons.notes,
          color: Colors.white70,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String url) {
    final future = _videoThumbnails.putIfAbsent(
      url,
      () => VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 512,
      ),
    );

    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return _buildConfessionPlaceholder(hasVideo: true);
      },
    );
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

  Widget _buildGiftsTab() {
    return _GiftsTabView(username: widget.username);
  }

  void _showFollowersList() {
    // Navigate to followers list
  }

  void _showFollowingList() {
    // Navigate to following list
  }

  void _sendMessage(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SendMessageScreen(recipientUsername: user.username),
      ),
    );
  }

  void _blockUser() {
    final l10n = AppLocalizations.of(context)!;
    final username = widget.username;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUserTitle),
        content: Text(l10n.blockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.blockUser(username);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.userBlocked)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorMessage(e.toString()))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.block),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String reason = 'spam';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reportUserTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reason,
                items: [
                  DropdownMenuItem(value: 'spam', child: Text(l10n.reportSpam)),
                  DropdownMenuItem(
                    value: 'harassment',
                    child: Text(l10n.reportHarassment),
                  ),
                  DropdownMenuItem(
                    value: 'inappropriate',
                    child: Text(l10n.reportInappropriate),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(l10n.reportOther),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      reason = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.reportReason,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.reportDetailsHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _userService.reportUser(
                    widget.username,
                    reason: reason,
                    description: controller.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.reportSent)));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorMessage(e.toString()))),
                    );
                  }
                }
              },
              child: Text(l10n.report),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true;
  }
}

class _GiftsTabView extends StatefulWidget {
  final String username;

  const _GiftsTabView({required this.username});

  @override
  State<_GiftsTabView> createState() => _GiftsTabViewState();
}

class _GiftsTabViewState extends State<_GiftsTabView> {
  List<dynamic>? _gifts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    // Only show gifts for the current user's own profile
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser?.username != widget.username) {
      setState(() {
        _isLoading = false;
        _error = 'private';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final giftService = GiftService();
      final gifts = await giftService.getReceivedGifts();
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gifts: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error == 'private') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.giftsPrivate, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.giftsLoadError, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadGifts, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (_gifts == null || _gifts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.profileNoGiftsTitle,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _gifts!.length,
      itemBuilder: (context, index) {
        final giftTransaction = _gifts![index];
        final gift = giftTransaction.gift;
        final sender = giftTransaction.sender;
        final giftPrice = gift?.price ?? giftTransaction.amount;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: gift != null ? _buildGiftMedia(gift) : const Icon(
                    Icons.card_giftcard,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  gift?.name ?? l10n.giftDefaultName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${giftPrice.toStringAsFixed(0)} FCFA',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (sender != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Text(
                    l10n.giftFromUserLower(sender.username),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftMedia(Gift gift) {
    final rawIcon = gift.icon;
    final isEmojiIcon = _isEmojiIcon(rawIcon);
    final animationUrl = _resolveGiftUrl(gift.animation);
    final iconUrl = isEmojiIcon ? '' : _resolveGiftUrl(gift.icon);

    if (animationUrl.isNotEmpty) {
      final lower = animationUrl.toLowerCase();
      if (lower.endsWith('.json')) {
        return Lottie.network(
          animationUrl,
          fit: BoxFit.contain,
        );
      }
      return CachedNetworkImage(
        imageUrl: animationUrl,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => const Icon(Icons.card_giftcard, size: 40),
      );
    }

    if (isEmojiIcon) {
      return _buildGiftEmoji(rawIcon);
    }

    if (iconUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: iconUrl,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => const Icon(Icons.card_giftcard, size: 40),
      );
    }

    return const Icon(Icons.card_giftcard, size: 40);
  }

  Widget _buildGiftEmoji(String emoji) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  bool _isEmojiIcon(String value) {
    if (value.isEmpty) return false;
    final lower = value.toLowerCase();
    if (lower.startsWith('http') || lower.contains('/') || lower.contains('.')) {
      return false;
    }
    return true;
  }

  String _resolveGiftUrl(String? url) {
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
}
