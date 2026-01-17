import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/gift_service.dart';
import '../../widgets/confessions/confession_card.dart';
import '../../widgets/common/loading_overlay.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile(widget.username);
    });
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(provider.error ?? 'Utilisateur introuvable'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadProfile(widget.username),
            child: const Text('Réessayer'),
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
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: NestedScrollView(
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
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Bloquer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Signaler'),
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
                labelColor: AppColors.secondary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Publications'),
                  Tab(text: 'Cadeaux'),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
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
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Name - Afficher "Anonyme" si l'utilisateur a choisi de ne pas montrer son nom
            Text(
              (user.settings?.showNameOnPosts ?? true) ? user.fullName : 'Anonyme',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontStyle: (user.settings?.showNameOnPosts ?? true) ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            // Afficher le username seulement si l'utilisateur est visible
            if (user.settings?.showNameOnPosts ?? true)
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
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
                  'Abonnés',
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
                  'Abonnements',
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
                  'Publications',
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
    final isFollowing = user.isFollowing ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Follow/Unfollow button avec dégradé
        Container(
          decoration: BoxDecoration(
            gradient: isFollowing ? null : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(25),
            border: isFollowing ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Material(
            color: isFollowing ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
                            isFollowing ? 'Abonné' : 'Suivre',
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Message',
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
    final confessions = provider.userConfessions;

    if (confessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune publication',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: confessions.length,
      itemBuilder: (context, index) {
        final confession = confessions[index];
        return ConfessionCard(
          confession: confession,
          onTap: () {
            context.push('/confessions/${confession.id}');
          },
          onComment: () {
            context.push('/confessions/${confession.id}');
          },
        );
      },
    );
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
        builder: (context) => SendMessageScreen(recipientUsername: user.username),
      ),
    );
  }

  void _blockUser() {
    // Block user
  }

  void _reportUser() {
    // Report user
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
    return false;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error == 'private') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Les cadeaux sont privés',
              style: TextStyle(color: Colors.grey),
            ),
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
            Text(
              'Erreur lors du chargement',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGifts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_gifts == null || _gifts!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun cadeau reçu',
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

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gift?.icon != null && gift!.icon.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: gift.icon,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.card_giftcard, size: 40),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Icon(Icons.card_giftcard, size: 40),
                ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  gift?.name ?? 'Cadeau',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (sender != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Text(
                    'de ${sender.username}',
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
}
