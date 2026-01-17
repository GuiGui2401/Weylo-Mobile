import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/pusher_service.dart';
import '../feed/feed_screen.dart';
import '../messages/messages_screen.dart';
import '../chat/conversations_screen.dart';
import '../groups/groups_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/my_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PusherService _pusherService = PusherService();

  final List<Widget> _screens = [
    const FeedScreen(),
    const MessagesScreen(),
    const ConversationsScreen(),
    const GroupsScreen(),
    const WalletScreen(),
    const MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializePusher();
  }

  Future<void> _initializePusher() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await _pusherService.connect(userId: authProvider.user!.id.toString());
      await _pusherService.subscribeToUserChannel(authProvider.user!.id);
      await _pusherService.subscribeToNotifications(authProvider.user!.id);
    }
  }

  @override
  void dispose() {
    _pusherService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Feed',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.mail_outline,
                    activeIcon: Icons.mail,
                    label: 'Messages',
                    showBadge: true,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: 'Chat',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups,
                    label: 'Groupes',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'Wallet',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 5,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Icône avec dégradé si sélectionnée
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    if (isSelected) {
                      return AppColors.primaryGradient.createShader(bounds);
                    }
                    return LinearGradient(
                      colors: [AppColors.textSecondary, AppColors.textSecondary],
                    ).createShader(bounds);
                  },
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: Colors.white,
                    size: 26,
                    weight: 700, // Make icons bolder
                  ),
                ),
                if (showBadge)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Texte avec dégradé si sélectionné
            ShaderMask(
              shaderCallback: (Rect bounds) {
                if (isSelected) {
                  return AppColors.primaryGradient.createShader(bounds);
                }
                return LinearGradient(
                  colors: [AppColors.textSecondary, AppColors.textSecondary],
                ).createShader(bounds);
              },
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
