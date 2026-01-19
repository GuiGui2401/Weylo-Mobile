import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/pusher_service.dart';
import '../feed/feed_screen.dart';
import '../messages/messages_screen.dart';
import '../chat/conversations_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/my_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PusherService _pusherService = PusherService();
  late final List<Key> _screenKeys;

  final List<Widget> _screens = [
    const FeedScreen(),
    const MessagesScreen(),
    const ConversationsScreen(),
    const GroupsScreen(),
    const MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _screenKeys = List<Key>.generate(_screens.length, (_) => UniqueKey());
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _screens.length,
          (index) => KeyedSubtree(
            key: _screenKeys[index],
            child: _screens[index],
          ),
        ),
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
                    icon: Icons.home_rounded,
                    activeIcon: Icons.home_rounded,
                    label: l10n.navFeedLabel,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.mark_email_unread_rounded,
                    activeIcon: Icons.mark_email_unread_rounded,
                    label: l10n.navMessagesLabel,
                    showBadge: true,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.forum_rounded,
                    activeIcon: Icons.forum_rounded,
                    label: l10n.navChatLabel,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.group_rounded,
                    activeIcon: Icons.group_rounded,
                    label: l10n.navGroupsLabel,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.account_circle_rounded,
                    activeIcon: Icons.account_circle_rounded,
                    label: l10n.navProfileLabel,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : Colors.black87;
    final unselectedColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_currentIndex == index) {
            _screenKeys[index] = UniqueKey();
          }
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
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 26,
                  weight: 700,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
