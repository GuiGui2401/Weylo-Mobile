import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../messages/messages_screen.dart';
import '../confessions/confessions_screen.dart';
import '../chat/conversations_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Key> _screenKeys;

  final List<Widget> _screens = const [
    MessagesScreen(),
    ConfessionsScreen(),
    ConversationsScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _screenKeys = List<Key>.generate(_screens.length, (_) => UniqueKey());
    // Refresh user data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              if (_currentIndex == index) {
                _screenKeys[index] = UniqueKey();
              }
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey.shade600,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.mark_email_unread_rounded, weight: 700),
              activeIcon: const Icon(Icons.mark_email_unread_rounded, weight: 700),
              label: l10n.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_rounded, weight: 700),
              activeIcon: const Icon(Icons.favorite_rounded, weight: 700),
              label: 'Confessions',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_rounded, weight: 700),
              activeIcon: const Icon(Icons.forum_rounded, weight: 700),
              label: l10n.navChat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.group_rounded, weight: 700),
              activeIcon: const Icon(Icons.group_rounded, weight: 700),
              label: l10n.navGroups,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_rounded, weight: 700),
              activeIcon: const Icon(Icons.account_circle_rounded, weight: 700),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
