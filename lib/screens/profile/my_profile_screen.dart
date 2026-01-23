import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/confession.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/confession_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/widgets/confessions/confession_card.dart';
import '../../services/widgets/common/premium_badge.dart';
import '../../services/gift_service.dart';
import '../../services/widgets/promotions/promote_post_modal.dart';
import '../../models/gift.dart';
import '../settings/settings_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GiftService _giftService = GiftService();
  final ConfessionService _confessionService = ConfessionService();
  List<GiftTransaction> _receivedGifts = [];
  bool _isLoadingGifts = false;
  final Map<String, Future<Uint8List?>> _videoThumbnails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadReceivedGifts();
    });
  }

  void _loadProfile() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      final profileProvider = context.read<ProfileProvider>();
      profileProvider.loadProfile(
        authProvider.user!.username,
        loadConfessions: false,
      );
      profileProvider.loadLikedConfessions();
      profileProvider.loadOwnConfessions();
    }
  }

  Future<void> _onRefresh() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadProfile(
      authProvider.user!.username,
      loadConfessions: false,
    );
    await profileProvider.loadLikedConfessions();
    await profileProvider.loadOwnConfessions();
    await _loadReceivedGifts();
  }

  Future<void> _loadReceivedGifts() async {
    setState(() => _isLoadingGifts = true);
    try {
      final gifts = await _giftService.getReceivedGifts();
      if (mounted) {
        setState(() {
          _receivedGifts = gifts;
          _isLoadingGifts = false;
        });
        debugPrint('MyProfile: Loaded gifts: ${gifts.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGifts = false);
      }
      debugPrint('MyProfile: Error loading gifts: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<AuthProvider, ProfileProvider>(
      builder: (context, authProvider, profileProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '@${user.username}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(user, profileProvider),
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
                          Tab(
                            icon: const Icon(Icons.grid_on),
                            text: l10n.profilePostsTab,
                          ),
                          Tab(
                            icon: const Icon(Icons.favorite_border),
                            text: l10n.profileLikesTab,
                          ),
                          Tab(
                            icon: const Icon(Icons.card_giftcard),
                            text: l10n.profileGiftsTab,
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(profileProvider),
                  _buildLikesTab(),
                  _buildGiftsTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(user, ProfileProvider profileProvider) {
    final l10n = AppLocalizations.of(context)!;
    final profileUser = profileProvider.profileUser ?? user;
    final coverUrl = profileUser.coverUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Avatar avec bordure dégradé
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: user.avatar != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.avatar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : ShaderMask(
                              shaderCallback: (bounds) => AppColors
                                  .primaryGradient
                                  .createShader(bounds),
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (user.isPremium || user.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: const VerifiedBadge(size: 20),
                    ),
                ],
              ),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      '${profileUser.confessionsCount ?? profileProvider.userConfessions.length}',
                      l10n.profilePostsTab,
                    ),
                    _buildStatColumn(
                      '${profileUser.followersCount}',
                      l10n.profileFollowers,
                      onTap: () => _showFollowersList(),
                    ),
                    _buildStatColumn(
                      '${profileUser.followingCount}',
                      l10n.profileFollowing,
                      onTap: () => _showFollowingList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and bio
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Edit profile button avec bordure dégradé
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/edit-profile'),
                  borderRadius: BorderRadius.circular(6),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        l10n.profileEditProfile,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Share profile button avec dégradé
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _shareProfile();
                },
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.profileShareProfile,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/promotions'),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Promotions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPostsTab(ProfileProvider profileProvider) {
    final l10n = AppLocalizations.of(context)!;
    final confessions = List<Confession>.from(
      profileProvider.userConfessions,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (confessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.profileNoPostsTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileNoPostsSubtitle,
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
      itemBuilder: (context, index) =>
          _buildConfessionTile(confessions[index], profileProvider),
    );
  }

  Widget _buildConfessionTile(
    Confession confession,
    ProfileProvider profileProvider,
  ) {
    final imageUrl = _resolveMediaUrl(confession.imageUrl);
    final videoUrl = _resolveMediaUrl(confession.videoUrl);
    final hasImage = confession.hasImage && imageUrl.isNotEmpty;
    final hasVideo = confession.hasVideo && videoUrl.isNotEmpty;

    return InkWell(
      onTap: () => context.push('/confession/${confession.id}'),
      onLongPress: () => _showPostOptions(context, confession, profileProvider),
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
              Positioned(
                left: 6,
                top: 6,
                child: InkWell(
                  onTap: () =>
                      _showPostOptions(context, confession, profileProvider),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 18,
                    ),
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
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatNumber(confession.viewsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  void _showPostOptions(
    BuildContext context,
    Confession confession,
    ProfileProvider profileProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  PromotePostModal.show(
                    context,
                    confessionId: confession.id,
                    onPromoted: () {
                      profileProvider.loadOwnConfessions();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(l10n.profileShare),
                onTap: () async {
                  Navigator.pop(ctx);
                  final shareUrl = DeepLinkService.getPostShareLink(confession.id);
                  await Share.share(
                    l10n.profileSharePostMessage(
                      shareUrl,
                    ),
                    subject: l10n.profileSharePostSubject,
                  );
                  try {
                    await _confessionService.shareConfession(confession.id);
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n.profileDelete,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, confession, profileProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Confession confession,
    ProfileProvider profileProvider,
  ) {
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
                await profileProvider.loadOwnConfessions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.profileDeletePostSuccess),
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
              l10n.profileDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
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

  Widget _buildLikesTab() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        final likedConfessions = profileProvider.likedConfessions;

        if (profileProvider.isLoading && likedConfessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (likedConfessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.profileNoLikesTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileNoLikesSubtitle,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: likedConfessions.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final confession = likedConfessions[index];
            return ConfessionCard(
              confession: confession,
              onTap: () {
                context.push('/confession/${confession.id}');
              },
              onComment: () {
                context.push('/confession/${confession.id}');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGiftsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingGifts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedGifts.isEmpty) {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileNoGiftsSubtitle,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReceivedGifts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedGifts.length,
        itemBuilder: (context, index) {
          final transaction = _receivedGifts[index];
          return _buildGiftCard(context, transaction);
        },
      ),
    );
  }

  Widget _buildGiftCard(BuildContext context, GiftTransaction transaction) {
    final l10n = AppLocalizations.of(context)!;
    final gift = transaction.gift;
    final sender = transaction.sender;
    final giftPrice = gift?.price ?? transaction.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gift icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: gift != null ? _buildGiftMedia(gift) : const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Gift info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift?.name ?? l10n.giftDefaultName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sender != null
                        ? l10n.giftFromUser(sender.username)
                        : l10n.giftAnonymous,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (transaction.message != null &&
                      transaction.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.message!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${giftPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(context, transaction.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
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
          width: 56,
          height: 56,
          fit: BoxFit.contain,
        );
      }
      return CachedNetworkImage(
        imageUrl: animationUrl,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
      );
    }

    if (isEmojiIcon) {
      return _buildGiftEmoji(rawIcon);
    }

    if (iconUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: iconUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      );
    }

    return const Icon(
      Icons.card_giftcard,
      color: Colors.white,
      size: 28,
    );
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
        style: const TextStyle(fontSize: 32),
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

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return l10n.timeAgoMinutes(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.timeAgoHours(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.timeAgoDays(diff.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFollowersList() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.push('/followers/${user.username}');
    }
  }

  void _showFollowingList() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.push('/following/${user.username}');
    }
  }

  void _shareProfile() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final colorScheme = Theme.of(ctx).colorScheme;
        final webLink = 'https://weylo.app/${user.username}';
        final appLink = 'weylo://m/${user.username}';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.shareProfileTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.shareProfileSubtitle,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),

                // QR Code option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code, color: AppColors.primary),
                  ),
                  title: Text(l10n.shareQrCodeTitle),
                  subtitle: Text(l10n.shareQrCodeSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showQRCode(user.username, appLink);
                  },
                ),
                const Divider(),

                // Share web link
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.language, color: Colors.blue),
                  ),
                  title: Text(l10n.shareWebLinkTitle),
                  subtitle: Text(webLink, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Share.share(
                      l10n.shareWebLinkMessage(webLink),
                      subject: l10n.shareWebLinkSubject,
                    );
                  },
                ),
                const Divider(),

                // Copy app link (for testing)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy, color: Colors.orange),
                  ),
                  title: Text(l10n.shareAppLinkTitle),
                  subtitle: Text(appLink, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: appLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copyToClipboardSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQRCode(String username, String link) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.scanQrTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 168,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '@$username',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              link,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.close),
          ),
        ],
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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => true;
}
