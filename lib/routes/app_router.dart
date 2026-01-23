import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:story_view/story_view.dart' as story_view;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../providers/auth_provider.dart';
import '../services/story_service.dart';
import '../services/user_service.dart';
import '../services/confession_service.dart';
import '../services/confession_background_uploader.dart';
import '../services/confession_upload_queue.dart';
import '../services/follow_service.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../services/group_service.dart';
import '../services/message_service.dart';
import '../services/story_reply_service.dart';
import '../services/chat_service.dart';
import '../services/deep_link_service.dart';
import '../models/story.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/notification.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../core/constants/api_constants.dart';
import '../services/voice_effects_service.dart';
import '../services/widgets/common/avatar_widget.dart';
import '../services/widgets/common/link_text.dart';
import '../core/errors/exceptions.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/send_gift_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/my_profile_screen.dart';
import '../screens/messages/send_message_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stories/create_story_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/monetization/earnings_screen.dart';
import '../screens/premium/subscriptions_screen.dart';
import '../screens/premium/premium_settings_screen.dart';
import '../screens/confessions/confession_detail_screen.dart';
import '../screens/promotions/promotions_screen.dart';
import '../screens/search/search_screen.dart';
import '../services/widgets/stories/story_reply_input.dart';
import '../services/widgets/voice/voice_recorder_widget.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/welcome',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';

        // Allow deep links for public profiles and anonymous messages
        if (state.matchedLocation.startsWith('/u/') ||
            state.matchedLocation.startsWith('/send-anonymous/')) {
          return null;
        }

        if (!isAuthenticated && !isAuthRoute) {
          return '/welcome';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Main Navigation (with bottom nav)
        GoRoute(
          path: '/',
          name: 'main',
          builder: (context, state) => const MainNavigationScreen(),
        ),

        // Legacy home route (redirects to main)
        GoRoute(path: '/home', redirect: (_, __) => '/'),

        // User Profile (public + deep link support)
        GoRoute(
          path: '/u/:username',
          name: 'user-profile',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return UserProfileScreen(username: username);
          },
        ),

        // Profile by ID
        GoRoute(
          path: '/profile/:id',
          name: 'profile-by-id',
          builder: (context, state) {
            final username = state.pathParameters['id'] ?? '';
            return UserProfileScreen(username: username);
          },
        ),

        // Chat
        GoRoute(
          path: '/chat/:id',
          name: 'chat',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final replyTitle = state.uri.queryParameters['reply_title'];
            final replyContent = state.uri.queryParameters['reply_content'];
            final sentContent = state.uri.queryParameters['sent_content'];
            return ChatScreen(
              conversationId: id,
              initialReplyTitle: replyTitle,
              initialReplyContent: replyContent,
              initialSentContent: sentContent,
            );
          },
        ),

        // Wallet
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => const WalletScreen(),
        ),

        // Send Message (with recipient)
        GoRoute(
          path: '/send-message/:username',
          name: 'send-message-to',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return SendMessageScreen(recipientUsername: username);
          },
        ),

        // Send Anonymous Message (alias for deep links)
        GoRoute(
          path: '/send-anonymous/:username',
          name: 'send-anonymous',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return SendMessageScreen(recipientUsername: username);
          },
        ),

        // Send Message (search for recipient)
        GoRoute(
          path: '/send-message',
          name: 'send-message',
          builder: (context, state) {
            return const SendMessageScreen(recipientUsername: '');
          },
        ),

        // Send Gift via conversation
        GoRoute(
          path: '/send-gift/:conversationId',
          name: 'send-gift',
          builder: (context, state) {
            final id =
                int.tryParse(state.pathParameters['conversationId'] ?? '') ?? 0;
            return SendGiftScreen(conversationId: id);
          },
        ),

        // Payment WebView
        GoRoute(
          path: '/payment',
          name: 'payment',
          builder: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            final url = state.uri.queryParameters['url'] ?? '';
            if (url.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(l10n.paymentTitle)),
                body: Center(child: Text(l10n.invalidPaymentUrl)),
              );
            }
            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.paymentTitle),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse(Uri.decodeComponent(url))),
              ),
            );
          },
        ),

        // New Chat (search for user to chat with)
        GoRoute(
          path: '/new-chat',
          name: 'new-chat',
          builder: (context, state) {
            return const _NewChatScreen();
          },
        ),

        // Create Confession
        GoRoute(
          path: '/create-confession',
          name: 'create-confession',
          builder: (context, state) {
            return const _CreateConfessionScreen();
          },
        ),

        // Confession Detail
        GoRoute(
          path: '/confession/:id',
          name: 'confession-detail',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return ConfessionDetailScreen(confessionId: id);
          },
        ),

        // Message Detail
        GoRoute(
          path: '/message/:id',
          name: 'message-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return _AnonymousMessageDetailScreen(
              messageId: int.tryParse(id) ?? 0,
            );
          },
        ),

        // Privacy Settings
        GoRoute(
          path: '/privacy',
          name: 'privacy',
          builder: (context, state) {
            return const _PrivacySettingsScreen();
          },
        ),

        // Terms of Service
        GoRoute(
          path: '/terms',
          name: 'terms',
          builder: (context, state) {
            return _LegalScreen(
              title: AppLocalizations.of(context)!.termsOfUse,
              type: 'terms',
            );
          },
        ),

        // Privacy Policy
        GoRoute(
          path: '/privacy-policy',
          name: 'privacy-policy',
          builder: (context, state) {
            return _LegalScreen(
              title: AppLocalizations.of(context)!.privacyPolicy,
              type: 'privacy',
            );
          },
        ),

        // Confession/Post Detail
        GoRoute(
          path: '/post/:id',
          name: 'post-detail',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return ConfessionDetailScreen(confessionId: id);
          },
        ),

        // Search
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const SearchScreen(),
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/promotions',
          name: 'promotions',
          builder: (context, state) => const PromotionsScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          name: 'subscriptions',
          builder: (context, state) => const SubscriptionsScreen(),
        ),
        GoRoute(
          path: '/earnings',
          name: 'earnings',
          builder: (context, state) => const EarningsScreen(),
        ),
        GoRoute(
          path: '/premium-settings',
          name: 'premium-settings',
          builder: (context, state) => const PremiumSettingsScreen(),
        ),

        // Edit Profile
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const _EditProfileScreen(),
        ),

        // Followers/Following Lists
        GoRoute(
          path: '/followers/:username',
          name: 'followers',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return _FollowersScreen(username: username);
          },
        ),
        GoRoute(
          path: '/following/:username',
          name: 'following',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return _FollowingScreen(username: username);
          },
        ),

        // Group
        GoRoute(
          path: '/groups',
          name: 'groups',
          builder: (context, state) => const GroupsScreen(),
        ),
        GoRoute(path: '/group', redirect: (_, __) => '/groups'),
        GoRoute(
          path: '/group/:id',
          name: 'group',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return _GroupChatScreen(groupId: id);
          },
        ),
        GoRoute(
          path: '/create-group',
          name: 'create-group',
          builder: (context, state) => const CreateGroupScreen(),
        ),

        // Stories
        GoRoute(
          path: '/stories/:userId',
          name: 'stories',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return _StoryViewerScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/my-stories',
          name: 'my-stories',
          builder: (context, state) => const _MyStoriesScreen(),
        ),
        GoRoute(
          path: '/create-story',
          name: 'create-story',
          builder: (context, state) => const CreateStoryScreen(),
        ),

        // Premium
        GoRoute(
          path: '/premium',
          name: 'premium',
          builder: (context, state) => const _PremiumScreen(),
        ),

        // Notifications
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const _NotificationsScreen(),
        ),

        // Help/About
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const _HelpScreen(),
        ),
        GoRoute(
          path: '/about',
          name: 'about',
          builder: (context, state) => const _AboutScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(
                  context,
                )!.pageNotFound(state.uri.toString()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: Text(AppLocalizations.of(context)!.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Private Screen Classes ====================

/// Screen for searching and starting a new chat
class _NewChatScreen extends StatefulWidget {
  const _NewChatScreen();

  @override
  State<_NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<_NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final Set<int> _startingConversationIds = {};
  Map<String, ConversationIndex> _conversationIndex = {};
  List<User> _defaultUsers = [];
  List<User> _searchResults = [];
  String _lastQuery = '';
  bool _isInitialLoading = true;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      final usersFuture = _userService.searchUsers('', perPage: 1000);
      final convsFuture = _chatService.getConversations();
      final results = await Future.wait([usersFuture, convsFuture]);
      final users = results[0] as List<User>;
      final conversations = results[1] as List<Conversation>;
      final conversationIndex = await _chatService
          .getConversationsIndexByUsername(conversations: conversations);

      if (!mounted) return;
      setState(() {
        _defaultUsers = users;
        _conversationIndex = conversationIndex;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _lastQuery = query;
    });

    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final users = await _userService.searchUsers(query, perPage: 100);
      if (!mounted) return;
      setState(() {
        _searchResults = users;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startConversation(User user) async {
    if (_startingConversationIds.contains(user.id)) return;
    setState(() => _startingConversationIds.add(user.id));
    try {
      final conversation = await _chatService.startConversation(user.username);
      if (!mounted) return;
      context.go('/chat/${conversation.id}');
    } catch (e) {
      Helpers.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.startConversationError,
      );
    } finally {
      if (!mounted) return;
      setState(() => _startingConversationIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newChatTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchUserHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    final showSearchResults = _lastQuery.isNotEmpty;
    final usersToShow = showSearchResults ? _searchResults : _defaultUsers;
    final l10n = AppLocalizations.of(context)!;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (usersToShow.isEmpty) {
      return Center(
        child: Text(
          showSearchResults ? l10n.noUsersFound : l10n.noUsersAvailable,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final sections = _buildUserSections(l10n, usersToShow);
    final sectionWidgets = <Widget>[];

    for (final section in sections) {
      if (section.users.isEmpty) continue;
      sectionWidgets.add(_buildSectionHeader(section));
      for (var i = 0; i < section.users.length; i++) {
        sectionWidgets.add(_buildUserTile(section.users[i]));
        if (i < section.users.length - 1) {
          sectionWidgets.add(const Divider(height: 0));
        }
      }
      sectionWidgets.add(const SizedBox(height: 12));
    }

    if (sectionWidgets.isEmpty) {
      return Center(
        child: Text(
          showSearchResults ? l10n.noUsersFound : l10n.noUsersAvailable,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: sectionWidgets,
    );
  }

  Widget _buildUserTile(User user) {
    final l10n = AppLocalizations.of(context)!;
    final index = _conversationIndex[user.username];
    final hasConversation = index?.hasConversation ?? false;
    final isIdentityRevealed = index?.isIdentityRevealed ?? false;

    final shouldHideInfo = !hasConversation || !isIdentityRevealed;
    final title = shouldHideInfo ? l10n.anonymousUser : user.fullName;
    final subtitle = shouldHideInfo ? l10n.maskedInfo : '@${user.username}';
    final avatarName = shouldHideInfo
        ? (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
        : user.fullName;

    late String statusBadge;
    late Color statusColor;
    if (!hasConversation) {
      statusBadge = l10n.statusNew;
      statusColor = Colors.blue;
    } else if (isIdentityRevealed) {
      statusBadge = l10n.statusRevealed;
      statusColor = Colors.green;
    } else {
      statusBadge = l10n.statusAnonymous;
      statusColor = Colors.orange;
    }

    final isStarting = _startingConversationIds.contains(user.id);

    return ListTile(
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          AvatarWidget(
            imageUrl: !shouldHideInfo ? user.avatar : null,
            name: avatarName,
            size: 48,
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasConversation
                  ? (isIdentityRevealed
                        ? Icons.visibility
                        : Icons.visibility_off)
                  : Icons.person_outline,
              size: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusBadge,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      trailing: isStarting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () => _startConversation(user),
              child: Text(l10n.startAction),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => _startConversation(user),
    );
  }

  Widget _buildSectionHeader(_UserSection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: section.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${section.users.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (section.helper.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                section.helper,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  List<_UserSection> _buildUserSections(
    AppLocalizations l10n,
    List<User> users,
  ) {
    final revealed = <User>[];
    final anonymous = <User>[];
    final withoutConversation = <User>[];

    for (final user in users) {
      final username = user.username;
      final index = _conversationIndex[username];
      final hasConversation = index?.hasConversation ?? false;
      final isIdentityRevealed = index?.isIdentityRevealed ?? false;

      if (hasConversation) {
        if (isIdentityRevealed) {
          revealed.add(user);
        } else {
          anonymous.add(user);
        }
      } else {
        withoutConversation.add(user);
      }
    }

    void sortByName(List<User> list) => list.sort(
      (a, b) => _userDisplayName(
        a,
      ).toLowerCase().compareTo(_userDisplayName(b).toLowerCase()),
    );

    sortByName(revealed);
    sortByName(anonymous);
    sortByName(withoutConversation);

    return [
      _UserSection(
        title: l10n.revealedConversations,
        helper: l10n.revealedConversationsHelper,
        accentColor: Colors.green,
        users: revealed,
      ),
      _UserSection(
        title: l10n.anonymousConversations,
        helper: l10n.anonymousConversationsHelper,
        accentColor: Colors.orange,
        users: anonymous,
      ),
      _UserSection(
        title: l10n.noConversation,
        helper: l10n.noConversationHelper,
        accentColor: Colors.blue,
        users: withoutConversation,
      ),
    ];
  }

  String _userDisplayName(User user) {
    final name = user.fullName;
    if (name.isNotEmpty) return name;
    return user.username;
  }
}

class _UserSection {
  final String title;
  final String helper;
  final Color accentColor;
  final List<User> users;

  const _UserSection({
    required this.title,
    required this.helper,
    required this.accentColor,
    required this.users,
  });
}

/// Screen for creating a new confession/post
class _CreateConfessionScreen extends StatefulWidget {
  const _CreateConfessionScreen();

  @override
  State<_CreateConfessionScreen> createState() =>
      _CreateConfessionScreenState();
}

class _CreateConfessionScreenState extends State<_CreateConfessionScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAnonymous = true;
  bool _isPublic = true;
  bool _isLoading = false;
  File? _selectedImage;
  File? _selectedVideo;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null; // Clear video if image is selected
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
        _selectedImage = null; // Clear image if video is selected
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();

    // Validate that there's either content or media
    if (content.isEmpty && _selectedImage == null && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addContentOrMediaError),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final hasMedia = _selectedImage != null || _selectedVideo != null;
    if (hasMedia) {
      final job = ConfessionUploadJob(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _isPublic ? 'public' : 'private',
        isAnonymous: _isAnonymous,
        content: content.isNotEmpty ? content : null,
        imagePath: _selectedImage?.path,
        videoPath: _selectedVideo?.path,
      );
      await ConfessionUploadQueue().enqueue(job);
      await ConfessionBackgroundUploader.enqueue(job);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.statusSending)),
        );
      }
      return;
    }

    try {
      final confessionService = ConfessionService();
      await confessionService.createConfession(
        content: content.isNotEmpty ? content : null,
        type: _isPublic ? 'public' : 'private',
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.postCreatedSuccess),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating confession: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.postCreateError(e.toString())),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createPostTitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publish,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.confessionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Media preview
            if (_selectedImage != null || _selectedVideo != null) ...[
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_library,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.videoSelected,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: _removeMedia,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Media buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(l10n.attachmentImage),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: Text(l10n.attachmentVideo),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.photoAction),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.postAnonymousTitle),
              subtitle: Text(l10n.postAnonymousSubtitle),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
            SwitchListTile(
              title: Text(l10n.postPublicTitle),
              subtitle: Text(l10n.postPublicSubtitle),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for privacy settings
class _PrivacySettingsScreen extends StatefulWidget {
  const _PrivacySettingsScreen();

  @override
  State<_PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<_PrivacySettingsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<User> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final users = await _userService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unblockUser(User user) async {
    try {
      await _userService.unblockUser(user.username);
      setState(() => _blockedUsers.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.userUnblocked(user.username),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showBlockedUsersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.block),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.blockedUsersWithCount(_blockedUsers.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.noBlockedUsers),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _blockedUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: user.avatar != null
                                ? CachedNetworkImageProvider(user.avatar!)
                                : null,
                            child: user.avatar == null
                                ? Text(user.initials)
                                : null,
                          ),
                          title: Text(user.fullName),
                          subtitle: Text('@${user.username}'),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _unblockUser(user);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.unblockAction,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.accountManagementHeader),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountManagementHeader),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.accountManagementHeader,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(AppLocalizations.of(context)!.blockedUsersTitle),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  )!.blockedUsersCount(_blockedUsers.length),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBlockedUsersSheet,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.deleteAccountTitle,
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.deleteAccountSubtitle,
                ),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
        content: Text(AppLocalizations.of(context)!.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteAccount();
                if (mounted) {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.errorMessage(e.toString()),
                      ),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAction),
          ),
        ],
      ),
    );
  }
}

/// Screen for legal pages (Terms, Privacy Policy)
class _LegalScreen extends StatelessWidget {
  final String title;
  final String type;

  const _LegalScreen({required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalLastUpdated,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(l10n.legalIntro, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Text(
              l10n.legalBody,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Help screen with FAQ
class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.help)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.faqTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            l10n.faqSendAnonymousQuestion,
            l10n.faqSendAnonymousAnswer,
          ),
          _buildFAQItem(
            l10n.faqRevealIdentityQuestion,
            l10n.faqRevealIdentityAnswer,
          ),
          _buildFAQItem(l10n.faqShareLinkQuestion, l10n.faqShareLinkAnswer),
          _buildFAQItem(
            l10n.faqContactSupportQuestion,
            l10n.faqContactSupportAnswer,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@weylo.app',
                queryParameters: {
                  'subject': AppLocalizations.of(context)!.supportEmailSubject,
                },
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.emailClientError)),
                  );
                }
              }
            },
            icon: const Icon(Icons.email_outlined),
            label: Text(l10n.contactSupport),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

/// About screen
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.versionLabel('1.0.0'),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.aboutTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.copyrightNotice,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edit Profile Screen
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  String? _avatarUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName ?? '';
      _bioController.text = user.bio ?? '';
      _avatarUrl = user.avatar;
      _coverUrl = user.coverUrl;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppLocalizations.of(ctx)!.takePhotoAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  _uploadAvatar(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(ctx)!.chooseFromGalleryAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  _uploadAvatar(image.path);
                }
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppLocalizations.of(ctx)!.deletePhotoAction,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  _deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(String path) async {
    setState(() => _isUploadingAvatar = true);

    try {
      final userService = UserService();
      final updatedUser = await userService.uploadAvatar(path);

      if (mounted) {
        context.read<AuthProvider>().updateUser(updatedUser);
        setState(() {
          _avatarUrl = updatedUser.avatar;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _isUploadingAvatar = true);

    try {
      final userService = UserService();
      await userService.deleteAvatar();

      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.updateUser(authProvider.user!.copyWith(avatar: null));
        setState(() {
          _avatarUrl = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoDeleted),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      final updatedUser = await userService.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      if (mounted) {
        // Update user in auth provider
        context.read<AuthProvider>().updateUser(updatedUser);

        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadCover() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppLocalizations.of(ctx)!.takePhotoAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1600,
                  maxHeight: 900,
                  imageQuality: 80,
                );
                if (image != null) {
                  _uploadCover(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(ctx)!.chooseFromGalleryAction),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  maxHeight: 900,
                  imageQuality: 80,
                );
                if (image != null) {
                  _uploadCover(image.path);
                }
              },
            ),
            if (_coverUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppLocalizations.of(ctx)!.deletePhotoAction,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  _deleteCover();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadCover(String path) async {
    setState(() => _isUploadingCover = true);

    try {
      final userService = UserService();
      final updatedUser = await userService.uploadCover(path);

      if (mounted) {
        context.read<AuthProvider>().updateUser(updatedUser);
        setState(() {
          _coverUrl = updatedUser.coverUrl;
          _isUploadingCover = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteCover() async {
    setState(() => _isUploadingCover = true);

    try {
      final userService = UserService();
      await userService.deleteCover();

      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.updateUser(authProvider.user!.copyWith(coverUrl: null));
        setState(() {
          _coverUrl = null;
          _isUploadingCover = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profilePhotoDeleted),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveAction),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _isUploadingCover ? null : _pickAndUploadCover,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: _coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _coverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingCover
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarUrl != null
                          ? CachedNetworkImageProvider(_avatarUrl!)
                          : null,
                      child: _isUploadingAvatar
                          ? const CircularProgressIndicator(color: Colors.white)
                          : _avatarUrl == null
                          ? Text(
                              user?.initials ?? '?',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Text(l10n.changeProfilePhoto),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: l10n.firstName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.firstNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: l10n.lastName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: l10n.bio,
                hintText: l10n.bioHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Screen
class _PremiumScreen extends StatefulWidget {
  const _PremiumScreen();

  @override
  State<_PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<_PremiumScreen> {
  final PremiumService _premiumService = PremiumService();
  PremiumPassStatusResponse? _passStatus;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isPurchasingMonthly = false;
  bool _isPurchasingYearly = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final status = await _premiumService.getPassStatus();
      setState(() {
        _passStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePremium({required String plan}) async {
    setState(() => _isPurchasing = true);
    if (plan == 'monthly') {
      setState(() => _isPurchasingMonthly = true);
    } else if (plan == 'yearly') {
      setState(() => _isPurchasingYearly = true);
    }

    try {
      await _premiumService.purchasePass(plan: plan);
      await _loadPremiumStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.premiumActivated),
          ),
        );
        // Update user in auth provider
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          authProvider.updateUser(authProvider.user!.copyWith(isPremium: true));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _isPurchasingMonthly = false;
          _isPurchasingYearly = false;
        });
      }
    }
  }

  Future<void> _toggleAutoRenew() async {
    try {
      if (_passStatus?.autoRenew == true) {
        await _premiumService.disableAutoRenew();
      } else {
        await _premiumService.enableAutoRenew();
      }
      await _loadPremiumStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _passStatus?.autoRenew == true
                  ? AppLocalizations.of(context)!.autoRenewEnabled
                  : AppLocalizations.of(context)!.autoRenewDisabled,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPremium = user?.isPremium ?? false;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weyloPremium)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weyloPremium)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Premium Status
            if (isPremium || _passStatus?.isActive == true) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      l10n.premiumActiveTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_passStatus?.daysRemaining != null &&
                        _passStatus!.daysRemaining > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.premiumDaysRemaining(_passStatus!.daysRemaining),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Auto-renew toggle
              Card(
                child: SwitchListTile(
                  title: Text(l10n.autoRenewTitle),
                  subtitle: Text(l10n.autoRenewSubtitle),
                  value: _passStatus?.autoRenew ?? false,
                  onChanged: (_) => _toggleAutoRenew(),
                ),
              ),
            ] else ...[
              // Premium badge for non-premium users
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      l10n.weyloPremium,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.premiumUnlockTitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Features
            _buildFeature(
              Icons.visibility,
              l10n.featureRevealTitle,
              l10n.featureRevealSubtitle,
            ),
            _buildFeature(
              Icons.verified,
              l10n.featureBadgeTitle,
              l10n.featureBadgeSubtitle,
            ),
            _buildFeature(
              Icons.block,
              l10n.featureNoAdsTitle,
              l10n.featureNoAdsSubtitle,
            ),
            _buildFeature(
              Icons.analytics,
              l10n.featureStatsTitle,
              l10n.featureStatsSubtitle,
            ),
            const SizedBox(height: 24),
            // Pricing (only for non-premium users)
            if (!isPremium && _passStatus?.isActive != true) ...[
              Card(
                child: ListTile(
                  title: Text(l10n.monthlyPlanTitle),
                  subtitle: Text(l10n.monthlyPlanPrice),
                  trailing: ElevatedButton(
                    onPressed: _isPurchasing
                        ? null
                        : () => _purchasePremium(plan: 'monthly'),
                    child: _isPurchasingMonthly
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.subscribeAction),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(l10n.yearlyPlanTitle),
                  subtitle: Text(l10n.yearlyPlanPrice),
                  trailing: ElevatedButton(
                    onPressed: _isPurchasing
                        ? null
                        : () => _purchasePremium(plan: 'yearly'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    child: _isPurchasingYearly
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.subscribeAction),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

/// Notifications Screen
class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();

  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  final NotificationApiService _notificationService = NotificationApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    try {
      final notifications = await _notificationService.getNotifications(
        page: loadMore ? _page : 1,
      );

      setState(() {
        if (loadMore) {
          _notifications.addAll(notifications);
        } else {
          _notifications = notifications;
          _page = 1;
        }
        _hasMore = notifications.length >= 20;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      _loadNotifications();
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.notificationsMarkedRead,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
      case 'anonymous_message':
        return Icons.mail;
      case 'follow':
      case 'follower':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'gift':
        return Icons.card_giftcard;
      case 'story_reply':
        return Icons.reply;
      case 'group':
        return Icons.group;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(onPressed: _markAllAsRead, child: Text(l10n.markAllRead)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noNotifications),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadNotifications(),
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notif.isRead
                            ? Colors.grey.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notif.type),
                        color: notif.isRead ? Colors.grey : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notif.body),
                    trailing: Text(
                      _formatTime(notif.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      _markAsRead(notif);
                      _handleNotificationTap(notif);
                    },
                  );
                },
              ),
            ),
    );
  }

  void _handleNotificationTap(AppNotification notif) {
    final data = notif.data;
    if (data == null) return;

    switch (notif.type) {
      case 'message':
      case 'anonymous_message':
        final messageId = data['message_id'] ?? data['id'];
        if (messageId != null) {
          context.push('/message/$messageId');
        }
        break;
      case 'follow':
      case 'follower':
        final username = data['username'];
        if (username != null) {
          context.push('/u/$username');
        }
        break;
      case 'like':
      case 'comment':
        final confessionId = data['confession_id'] ?? data['post_id'];
        if (confessionId != null) {
          context.push('/post/$confessionId');
        }
        break;
      case 'gift':
        // Navigate to gifts tab in profile
        break;
      case 'group':
        final groupId = data['group_id'];
        if (groupId != null) {
          context.push('/group/$groupId');
        }
        break;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    final l10n = AppLocalizations.of(context)!;
    if (diff.inMinutes < 60) return l10n.timeAgoMinutesShort(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeAgoHoursShort(diff.inHours);
    return l10n.timeAgoDaysShort(diff.inDays);
  }
}

/// Story Viewer Screen - View stories of a user
class _StoryViewerScreen extends StatefulWidget {
  final String userId;

  const _StoryViewerScreen({required this.userId});

  @override
  State<_StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<_StoryViewerScreen> {
  final story_view.StoryController _storyController =
      story_view.StoryController();
  final StoryService _storyService = StoryService();
  final StoryReplyService _replyService = StoryReplyService();
  final ChatService _chatService = ChatService();
  List<story_view.StoryItem> _storyItems = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  User? _storyUser;
  int _currentIndex = 0;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    try {
      // Load stories for this user by ID
      final userId = int.tryParse(widget.userId);
      if (userId == null || userId <= 0) {
        setState(() {
          _error = AppLocalizations.of(context)!.storyInvalidUserId;
          _isLoading = false;
        });
        return;
      }
      final stories = await _storyService.getUserStoriesById(userId);

      if (stories.isEmpty) {
        setState(() {
          _error = AppLocalizations.of(context)!.storyNoAvailable;
          _isLoading = false;
        });
        return;
      }

      _stories = stories;
      _storyUser = stories.first.user;

      // If user is not included in story, load it separately
      if (_storyUser == null && stories.first.userId > 0) {
        try {
          final userService = UserService();
          _storyUser = await userService.getUserById(stories.first.userId);
        } catch (e) {
          // User could not be loaded, but continue with stories
          print('Could not load user: $e');
        }
      }

      if (_storyUser == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.userNotFound;
          _isLoading = false;
        });
        return;
      }

      // Convert to StoryItems
      final items = <story_view.StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            story_view.StoryItem.text(
              title: story.content ?? '',
              backgroundColor:
                  _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            story_view.StoryItem.pageImage(
              url: story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        } else if (story.isVideo && story.mediaUrl != null) {
          items.add(
            story_view.StoryItem.pageVideo(
              story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        }

        // Mark as viewed
        _storyService.markAsViewed(story.id);
      }

      setState(() {
        _storyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.storyLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  void _toggleReplyMode() {
    setState(() {
      _isReplying = !_isReplying;
    });
    if (_isReplying) {
      _storyController.pause();
    } else {
      _storyController.play();
    }
  }

  Story? get _currentStory {
    if (_currentIndex < 0 || _currentIndex >= _stories.length) {
      return null;
    }
    return _stories[_currentIndex];
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _sendReplyToChat({
    required String content,
    File? voiceFile,
    String? voiceEffect,
  }) async {
    final username = _storyUser?.username;
    if (username == null || username.isEmpty) return;

    final conversation = await _chatService.startConversation(username);
    if (voiceFile != null) {
      await _chatService.sendMessage(
        conversation.id,
        voice: voiceFile,
        voiceEffect: voiceEffect,
      );
      return;
    }

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    await _chatService.sendMessage(conversation.id, content: trimmed);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null || _storyItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? AppLocalizations.of(context)!.storyNoAvailable,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          story_view.StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == story_view.Direction.down) {
                Navigator.of(context).pop();
              }
            },
            onStoryShow: (storyItem, index) {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _currentIndex = index;
                });
              });
            },
            progressPosition: story_view.ProgressPosition.top,
            repeat: false,
          ),
          // User info overlay
          if (_storyUser != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    backgroundImage: _storyUser!.avatar != null
                        ? CachedNetworkImageProvider(_storyUser!.avatar!)
                        : null,
                    child: _storyUser!.avatar == null
                        ? Text(
                            _storyUser!.initials,
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storyUser!.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${_storyUser!.username}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: StoryReplyInput(
              storyId: _currentStory?.id ?? 0,
              isExpanded: _isReplying,
              onTap: _toggleReplyMode,
              onSend:
                  (
                    content, {
                    isAnonymous = true,
                    voiceFile,
                    voiceEffect,
                  }) async {
                    final story = _currentStory;
                    if (story == null) return;
                    try {
                      if (voiceFile != null) {
                        await _replyService.sendVoiceReply(
                          storyId: story.id,
                          audioFile: voiceFile,
                          voiceEffect: voiceEffect,
                          isAnonymous: isAnonymous,
                        );
                        await _sendReplyToChat(
                          content: '',
                          voiceFile: voiceFile,
                          voiceEffect: voiceEffect,
                        );
                      } else {
                        await _replyService.sendTextReply(
                          storyId: story.id,
                          content: content,
                          isAnonymous: isAnonymous,
                        );
                        await _sendReplyToChat(content: content);
                      }
                      _toggleReplyMode();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.storyReplySent,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.storyReplyError,
                            ),
                          ),
                        );
                      }
                    }
                  },
              onClose: _toggleReplyMode,
            ),
          ),
        ],
      ),
    );
  }
}

/// My Stories Screen - View and manage my own stories
class _MyStoriesScreen extends StatefulWidget {
  const _MyStoriesScreen();

  @override
  State<_MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<_MyStoriesScreen> {
  final story_view.StoryController _storyController =
      story_view.StoryController();
  final StoryService _storyService = StoryService();
  List<story_view.StoryItem> _storyItems = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMyStories();
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _loadMyStories() async {
    try {
      var stories = await _storyService.getMyStories();

      // Filtrer les stories expirées
      stories = stories.where((s) => !s.isExpired).toList();

      if (stories.isEmpty) {
        setState(() {
          _error = AppLocalizations.of(context)!.storyNoActive;
          _isLoading = false;
        });
        return;
      }

      _stories = stories;

      // Convert to StoryItems
      final items = <story_view.StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            story_view.StoryItem.text(
              title: story.content ?? '',
              backgroundColor:
                  _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            story_view.StoryItem.pageImage(
              url: story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        } else if (story.isVideo && story.mediaUrl != null) {
          items.add(
            story_view.StoryItem.pageVideo(
              story.mediaUrl!,
              controller: _storyController,
              duration: Duration(seconds: story.duration),
              caption: story.content != null
                  ? Text(
                      story.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          );
        }
      }

      setState(() {
        _storyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.storyLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _deleteCurrentStory() async {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;

    final story = _stories[_currentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteStoryTitle),
        content: Text(AppLocalizations.of(context)!.deleteStoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.deleteStory(story.id);

        if (_stories.length == 1) {
          Navigator.of(context).pop();
        } else {
          _loadMyStories();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.storyDeleted)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null || _storyItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/create-story');
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                _error ?? AppLocalizations.of(context)!.storyNoneTitle,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/create-story');
                },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.createStoryAction),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          story_view.StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == story_view.Direction.down) {
                Navigator.of(context).pop();
              }
            },
            onStoryShow: (storyItem, index) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _currentIndex = index);
                }
              });
            },
            progressPosition: story_view.ProgressPosition.top,
            repeat: false,
          ),
          // User info overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  backgroundImage: user?.avatar != null
                      ? CachedNetworkImageProvider(user!.avatar!)
                      : null,
                  child: user?.avatar == null
                      ? Text(
                          user?.initials ?? '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myStoryTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_stories.isNotEmpty &&
                          _currentIndex < _stories.length)
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.viewsCount(_stories[_currentIndex].viewsCount),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom actions
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // View viewers
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.white),
                  onPressed: () => _showViewers(),
                ),
                const SizedBox(width: 24),
                // Add new story
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/create-story');
                  },
                ),
                const SizedBox(width: 24),
                // Delete story
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteCurrentStory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showViewers() {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;

    final story = _stories[_currentIndex];
    final hasViewerSubscription = story.hasViewerSubscription;

    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<StoryView>>(
        future: _storyService.getViewers(story.id),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.errorMessage(snapshot.error.toString()),
                ),
              ),
            );
          }
          final viewers = snapshot.data ?? [];
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility),
                    const SizedBox(width: 8),
                    Text(
                      l10n.viewsCount(story.viewsCount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (viewers.isNotEmpty)
                  ...viewers.map((viewer) {
                    final displayName = hasViewerSubscription
                        ? (viewer.user?.fullName ?? l10n.userFallback)
                        : l10n.userAnonymous;
                    final username = hasViewerSubscription
                        ? (viewer.user?.username ?? '')
                        : '';
                    final avatarUrl = hasViewerSubscription
                        ? viewer.user?.avatar
                        : null;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        backgroundColor:
                            avatarUrl == null ? AppColors.primary : null,
                        child: avatarUrl == null
                            ? const Text(
                                '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      title: Text(displayName),
                      subtitle: username.isNotEmpty ? Text('@$username') : null,
                    );
                  })
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: Text(l10n.storyViewsEmpty)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Followers Screen
class _FollowersScreen extends StatefulWidget {
  final String username;

  const _FollowersScreen({required this.username});

  @override
  State<_FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<_FollowersScreen> {
  final FollowService _followService = FollowService();
  List<User> _followers = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    try {
      final response = await _followService.getFollowers(
        widget.username,
        page: loadMore ? _page : 1,
      );
      final List<dynamic> data = _extractUsers(response);
      final newFollowers = data.map((json) => User.fromJson(json)).toList();

      setState(() {
        if (loadMore) {
          _followers.addAll(newFollowers);
        } else {
          _followers = newFollowers;
          _page = 1;
        }
        _hasMore = newFollowers.length >= 20;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(e.toString()))),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(User user) async {
    try {
      if (user.isFollowing == true) {
        await _followService.unfollowUser(user.username);
      } else {
        await _followService.followUser(user.username);
      }
      _loadFollowers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(e.toString()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.followersTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFollowers,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFollowers(),
              child: ListView.builder(
                itemCount: _followers.length,
                itemBuilder: (context, index) {
                  final user = _followers[index];
                  return _buildUserTile(user);
                },
              ),
            ),
    );
  }

  Widget _buildUserTile(User user) {
    final currentUser = context.read<AuthProvider>().user;
    final isCurrentUser = currentUser?.id == user.id;
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: user.avatar != null
            ? CachedNetworkImageProvider(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(
                user.initials,
                style: const TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text('@${user.username}'),
      trailing: isCurrentUser
          ? null
          : OutlinedButton(
              onPressed: () => _toggleFollow(user),
              style: OutlinedButton.styleFrom(
                backgroundColor: user.isFollowing == true
                    ? null
                    : AppColors.primary,
                foregroundColor: user.isFollowing == true
                    ? AppColors.primary
                    : Colors.white,
              ),
              child: Text(
                user.isFollowing == true ? l10n.followed : l10n.follow,
              ),
            ),
      onTap: () => context.push('/u/${user.username}'),
    );
  }

  List<dynamic> _extractUsers(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
      if (data['followers'] is List) return data['followers'] as List;
    }
    if (data is List) return data;
    if (response['followers'] is List) return response['followers'] as List;
    return [];
  }
}

/// Following Screen
class _FollowingScreen extends StatefulWidget {
  final String username;

  const _FollowingScreen({required this.username});

  @override
  State<_FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<_FollowingScreen> {
  final FollowService _followService = FollowService();
  List<User> _following = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    try {
      final response = await _followService.getFollowing(
        widget.username,
        page: loadMore ? _page : 1,
      );
      final List<dynamic> data = _extractUsers(response);
      final newFollowing = data.map((json) => User.fromJson(json)).toList();

      setState(() {
        if (loadMore) {
          _following.addAll(newFollowing);
        } else {
          _following = newFollowing;
          _page = 1;
        }
        _hasMore = newFollowing.length >= 20;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorMessage(e.toString()))),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow(User user) async {
    try {
      if (user.isFollowing == true) {
        await _followService.unfollowUser(user.username);
      } else {
        await _followService.followUser(user.username);
      }
      _loadFollowing();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorMessage(e.toString()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.followingTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _following.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFollowing,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFollowing(),
              child: ListView.builder(
                itemCount: _following.length,
                itemBuilder: (context, index) {
                  final user = _following[index];
                  return _buildUserTile(user);
                },
              ),
            ),
    );
  }

  Widget _buildUserTile(User user) {
    final currentUser = context.read<AuthProvider>().user;
    final isCurrentUser = currentUser?.id == user.id;
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: user.avatar != null
            ? CachedNetworkImageProvider(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(
                user.initials,
                style: const TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text('@${user.username}'),
      trailing: isCurrentUser
          ? null
          : OutlinedButton(
              onPressed: () => _toggleFollow(user),
              style: OutlinedButton.styleFrom(
                backgroundColor: user.isFollowing == true
                    ? null
                    : AppColors.primary,
                foregroundColor: user.isFollowing == true
                    ? AppColors.primary
                    : Colors.white,
              ),
              child: Text(
                user.isFollowing == true ? l10n.followed : l10n.follow,
              ),
            ),
      onTap: () => context.push('/u/${user.username}'),
    );
  }

  List<dynamic> _extractUsers(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
      if (data['following'] is List) return data['following'] as List;
    }
    if (data is List) return data;
    if (response['following'] is List) return response['following'] as List;
    return [];
  }
}

/// Group Chat Screen with image and voice support
class _GroupChatScreen extends StatefulWidget {
  final String groupId;

  const _GroupChatScreen({required this.groupId});

  @override
  State<_GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<_GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final GroupService _groupService = GroupService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showVoiceRecorder = false;
  File? _selectedImage;
  File? _selectedVideo;
  File? _voiceFile;
  VoiceEffect? _selectedVoiceEffect;
  int? _playingMessageId;
  bool _isAudioLoading = false;
  String? _groupName;
  Group? _group;
  int? _currentUserId;
  Map<String, dynamic>? _replyToMessage;
  int? _editingMessageId;
  final Map<String, Future<Uint8List?>> _videoThumbnails = {};

  // Colors for different users
  static const List<Color> _userColors = [
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Rose
    Color(0xFF10B981), // Vert
    Color(0xFFF59E0B), // Orange
    Color(0xFF3B82F6), // Bleu
    Color(0xFFEF4444), // Rouge
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
  ];

  Color _getUserColor(int senderId) {
    return _userColors[senderId % _userColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadGroup();
    _loadMessages();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingMessageId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    try {
      final group = await _groupService.getGroup(
        int.tryParse(widget.groupId) ?? 0,
      );
      // Get current user ID from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _group = group;
        _groupName = group.name;
        _currentUserId = authProvider.user?.id;
      });
    } catch (e) {
      // Handle error
    }
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

  Future<void> _toggleVoicePlayback(
    int messageId,
    String mediaUrl,
    String? voiceEffect,
  ) async {
    if (mediaUrl.isEmpty) return;
    try {
      debugPrint('[GroupChat] Play voice -> id=$messageId url=$mediaUrl');
      if (_playingMessageId == messageId && _audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      setState(() {
        _playingMessageId = messageId;
        _isAudioLoading = true;
      });
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(mediaUrl),
          headers: const {'Accept': '*/*', 'Range': 'bytes=0-'},
        ),
      );
      await VoiceEffectsService.applyEffectToPlayer(
        _audioPlayer,
        VoiceEffectsService.stringToEffect(voiceEffect),
      );
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.audioPlaybackError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _openVideoPlayer(String mediaUrl) async {
    if (mediaUrl.isEmpty) return;
    debugPrint('[GroupChat] Open video -> url=$mediaUrl');
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(mediaUrl),
      httpHeaders: const {'Accept': '*/*', 'Range': 'bytes=0-'},
    );
    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.videoPlaybackError(e.toString()),
            ),
          ),
        );
      }
      await controller.dispose();
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              IconButton(
                onPressed: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 56,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await controller.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      final result = await _groupService.getMessages(
        int.tryParse(widget.groupId) ?? 0,
      );
      setState(() {
        _messages = result.messages.map((m) {
          final json = m.toJson();
          // Add is_mine field for message bubbles
          json['is_mine'] =
              json['sender_id'] == currentUserId ||
              json['user_id'] == currentUserId;
          return json;
        }).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        _voiceFile = null;
        _showVoiceRecorder = false;
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
        _voiceFile = null;
        _showVoiceRecorder = false;
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
        _voiceFile = null;
        _showVoiceRecorder = false;
      });
    }
  }

  void _onVoiceRecorded(File file, dynamic effect) {
    setState(() {
      _voiceFile = file;
      _selectedVoiceEffect = effect is VoiceEffect ? effect : VoiceEffect.none;
      _selectedImage = null;
      _selectedVideo = null;
      _showVoiceRecorder = false;
    });
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final isOwnerOnly = _group?.onlyOwnerCanPost ?? false;
    final canSend = !isOwnerOnly || (_currentUserId != null && _currentUserId == _group?.creatorId);

    if (!canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seul le propriétaire du groupe peut écrire.')),
      );
      return;
    }
    if (content.isEmpty && _selectedImage == null && _selectedVideo == null && _voiceFile == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Handle editing
      if (_editingMessageId != null) {
        await _groupService.editMessage(
          int.tryParse(widget.groupId) ?? 0,
          _editingMessageId!,
          content: content,
        );

        _messageController.clear();
        setState(() {
          _editingMessageId = null;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.messageEdited)),
        );
        _loadMessages();
        return;
      }

      // Handle reply
      final replyToId = _replyToMessage?['id'];

      final voice = (_selectedImage != null || _selectedVideo != null)
          ? null
          : _voiceFile;

      await _groupService.sendMessage(
        groupId: int.tryParse(widget.groupId) ?? 0,
        content: content,
        image: _selectedImage,
        video: _selectedVideo,
        voice: voice,
        replyToId: replyToId,
        voiceEffect: _selectedVoiceEffect != null
            ? VoiceEffectsService.effectToString(_selectedVoiceEffect!)
            : null,
      );

      _messageController.clear();
      setState(() {
        _selectedImage = null;
        _selectedVideo = null;
        _voiceFile = null;
        _selectedVoiceEffect = null;
        _replyToMessage = null;
        _isSending = false;
      });

      _loadMessages();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        final errorMessage = _extractErrorMessage(e);
        final voiceInfo = _voiceFile != null
            ? _voiceDebugInfo(_voiceFile!)
            : null;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              voiceInfo != null
                  ? l10n.errorWithDebug(
                      l10n.errorMessage(errorMessage),
                      voiceInfo,
                    )
                  : l10n.errorMessage(errorMessage),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOwnerOnly = _group?.onlyOwnerCanPost ?? false;
    final canSend = !isOwnerOnly || (_currentUserId != null && _currentUserId == _group?.creatorId);
    final groupStatusText = _buildGroupStatusText(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: _group?.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _group!.avatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        (_groupName ?? l10n.groupTitleFallback)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_groupName ?? l10n.groupTitleFallback),
                  if (groupStatusText != null)
                    Text(
                      groupStatusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            AppColors.textSecondary,
                      ),
                    )
                  else if (_group != null)
                    Text(
                      l10n.membersCount(_group!.membersCount),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              _showMembers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fond.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.groupEmptyTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.groupEmptySubtitle,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Dismissible(
                          key: ValueKey(
                            'group_message_${message['id']}_${message['created_at'] ?? index}',
                          ),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            color: AppColors.primary.withOpacity(0.08),
                            child: const Icon(
                              Icons.reply,
                              color: AppColors.primary,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            setState(() {
                              _replyToMessage = message;
                            });
                            return false;
                          },
                          child: _buildMessageBubble(message),
                        );
                      },
                    ),
            ),

            // Selected image preview
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedVideo != null)
              Container(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 28,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.videoSelected,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedVideo = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Voice recorder
            if (_showVoiceRecorder)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: VoiceRecorderWidget(
                  onRecordingComplete: _onVoiceRecorded,
                  showEffectSelector: true,
                ),
              ),

            // Reply preview
            if (_replyToMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.replyToUser(
                              _replyToMessage!['sender']?['full_name'] ??
                                  l10n.userFallback,
                            ),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _replyToMessage!['content'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _replyToMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Editing indicator
            if (_editingMessageId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  border: Border(top: BorderSide(color: Colors.amber[300]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.messageEditMode,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _editingMessageId = null;
                          _messageController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

          if (!canSend)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Seul le propriétaire du groupe peut écrire.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Input area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image,
                            color: _selectedImage != null
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          onPressed: canSend ? _pickImage : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.videocam,
                            color: _selectedVideo != null
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          onPressed: canSend ? _pickVideo : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: _showVoiceRecorder
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          onPressed: () {
                          if (!canSend) return;
                            setState(() {
                              _showVoiceRecorder = !_showVoiceRecorder;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                          enabled: canSend,
                            decoration: InputDecoration(
                              hintText: _editingMessageId != null
                                  ? l10n.editMessageHint
                                  : (canSend
                                    ? l10n.messageInputHint
                                    : 'Seul le propriétaire peut écrire.'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => canSend ? _sendMessage() : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: AppColors.primary,
                                ),
                                onPressed: canSend ? _sendMessage : null,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _buildGroupStatusText(BuildContext context) {
    if (_group == null) return null;
    final locale = Localizations.localeOf(context).languageCode;
    final members = _group!.members ?? [];
    final onlineCount =
        members.where((m) => m.user?.isOnline == true).length;
    final membersLabel = locale == 'fr'
        ? '${_group!.membersCount} membres'
        : '${_group!.membersCount} members';

    if (onlineCount > 0) {
      final onlineLabel =
          locale == 'fr' ? '$onlineCount en ligne' : '$onlineCount online';
      return '$onlineLabel • $membersLabel';
    }

    final lastActivity =
        _group!.lastMessage?.createdAt ?? _group!.updatedAt ?? _group!.createdAt;
    if (lastActivity != null) {
      final now = DateTime.now();
      final isToday =
          now.year == lastActivity.year &&
          now.month == lastActivity.month &&
          now.day == lastActivity.day;
      final timeText = Helpers.formatTime(lastActivity);
      if (locale == 'fr') {
        final base = isToday
            ? "Derniere activite aujourd'hui a $timeText"
            : 'Derniere activite le ${Helpers.formatDate(lastActivity)} a $timeText';
        return '$base • $membersLabel';
      }
      final base = isToday
          ? 'Last active today at $timeText'
          : 'Last active on ${Helpers.formatDate(lastActivity)} at $timeText';
      return '$base • $membersLabel';
    }

    return membersLabel;
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['is_mine'] == true;
    final rawMediaUrl = message['media_full_url'] ?? message['media_url'];
    final mediaUrl = _resolveMediaUrl(rawMediaUrl);
    final messageType = message['type'] ?? 'text';
    final hasImage = messageType == 'image' && mediaUrl.isNotEmpty;
    final hasVoice = messageType == 'voice' && mediaUrl.isNotEmpty;
    final hasVideo = messageType == 'video' && mediaUrl.isNotEmpty;
    final isDecoratedMedia = hasVoice;
    final senderId = message['sender_id'] ?? message['sender']?['id'] ?? 0;
    final senderColor = isMe ? AppColors.primary : _getUserColor(senderId);
    final replyTo = message['reply_to_message'];
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderName =
        sender?['full_name'] ??
        sender?['username'] ??
        AppLocalizations.of(context)!.userFallback;
    final senderAvatar = sender?['avatar'] ?? sender?['avatar_url'];

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: AvatarWidget(
                  imageUrl: senderAvatar,
                  name: senderName,
                  size: 32,
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: isDecoratedMedia
                    ? const EdgeInsets.all(0)
                    : const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isDecoratedMedia
                      ? Colors.transparent
                      : (isMe ? AppColors.primary : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && sender != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: senderColor,
                          ),
                        ),
                      ),
                    // Reply to preview
                    if (replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white70 : senderColor,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          _replyPreviewText(replyTo),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: mediaUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hasVideo)
                      _buildVideoPreview(mediaUrl, isMe, senderColor),
                    if (hasVoice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isMe ? Colors.white : senderColor)
                                .withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon:
                                  _isAudioLoading &&
                                      _playingMessageId == message['id']
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _playingMessageId == message['id'] &&
                                              _audioPlayer.playing
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: isMe ? Colors.white : senderColor,
                                    ),
                              onPressed: () => _toggleVoicePlayback(
                                message['id'],
                                mediaUrl,
                                message['voice_effect'],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color:
                                      isMe ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message['content'] != null &&
                        message['content'].isNotEmpty)
                      LinkText(
                        text: message['content'],
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                        linkStyle: TextStyle(
                          color: isMe ? Colors.white : AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                        showPreview: true,
                        previewBackgroundColor: isMe
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.05),
                        previewTextColor: isMe ? Colors.white : Colors.black87,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _replyPreviewText(Map<String, dynamic> replyTo) {
    final l10n = AppLocalizations.of(context)!;
    final content = replyTo['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    final type = replyTo['type'] ?? 'text';
    switch (type) {
      case 'image':
        return l10n.attachmentImage;
      case 'voice':
        return l10n.voiceMessageLabel;
      case 'video':
        return l10n.attachmentVideo;
      default:
        return l10n.messageLabel;
    }
  }

  Widget _buildVideoPreview(String url, bool isMe, Color senderColor) {
    final future = _videoThumbnails.putIfAbsent(
      url,
      () => VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
        maxWidth: 720,
      ),
    );

    return GestureDetector(
      onTap: () => _openVideoPlayer(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                );
              },
            ),
            Icon(
              Icons.play_circle_fill,
              size: 56,
              color: isMe ? Colors.white : senderColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final isMe = message['is_mine'] == true;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(AppLocalizations.of(context)!.reply),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyToMessage = message;
                });
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.editAction),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessageId = message['id'];
                    _messageController.text = message['content'] ?? '';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.deleteAction,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(message['id']);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(AppLocalizations.of(context)!.copyAction),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: message['content'] ?? ''),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.messageCopied),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessageTitle),
        content: Text(AppLocalizations.of(context)!.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupService.deleteMessage(
                  int.tryParse(widget.groupId) ?? 0,
                  messageId,
                );
                setState(() {
                  _messages.removeWhere((m) => m['id'] == messageId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.messageDeleted),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.errorMessage(e.toString()),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAction),
          ),
        ],
      ),
    );
  }

  String _voiceDebugInfo(File voice) {
    final filename = voice.path.split('/').last;
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    String contentType = 'audio/m4a';
    String signature = 'unknown';

    switch (extension) {
      case 'mp3':
        contentType = 'audio/mpeg';
        break;
      case 'm4a':
        contentType = 'audio/m4a';
        break;
      case 'aac':
        contentType = 'audio/aac';
        break;
      case 'wav':
        contentType = 'audio/wav';
        break;
      case 'ogg':
        contentType = 'audio/ogg';
        break;
      case 'webm':
        contentType = 'audio/webm';
        break;
    }

    try {
      final bytes = voice.readAsBytesSync();
      if (bytes.length >= 12) {
        final header4 = String.fromCharCodes(bytes.sublist(0, 4));
        final header8 = String.fromCharCodes(bytes.sublist(8, 12));
        final ftyp = String.fromCharCodes(bytes.sublist(4, 8));
        if (header4 == 'RIFF' && header8 == 'WAVE') {
          signature = 'RIFF/WAVE';
        } else if (ftyp == 'ftyp') {
          signature = 'ftyp';
        } else if (header4 == 'OggS') {
          signature = 'OggS';
        } else if (header4 == 'ID3') {
          signature = 'ID3';
        } else {
          signature = header4;
        }
      }
    } catch (_) {
      signature = 'read_error';
    }

    return 'file=$filename ext=$extension type=$contentType sig=$signature';
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null) return message.toString();
        final errors = data['errors'];
        if (errors is Map) {
          return errors.values.map((v) => v.toString()).join(' ');
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    return error.toString();
  }

  void _showMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _MembersListWidget(
          groupId: int.tryParse(widget.groupId) ?? 0,
          groupService: _groupService,
          scrollController: scrollController,
          isAdmin:
              _group != null &&
              _currentUserId != null &&
              _group!.creatorId == _currentUserId,
          onMemberRemoved: () => _loadGroup(),
        ),
      ),
    );
  }

  void _showOptions() {
    final isAdmin =
        _group != null &&
        _currentUserId != null &&
        _group!.creatorId == _currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Invite code
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: Text(AppLocalizations.of(context)!.inviteCodeTitle),
              subtitle: Text(_group?.inviteCode ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (_group?.inviteCode != null) {
                    Clipboard.setData(ClipboardData(text: _group!.inviteCode));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.inviteCodeCopied,
                        ),
                      ),
                    );
                  }
                },
              ),
              onTap: () {
                if (_group?.inviteCode != null) {
                  _showInviteCodeDialog();
                }
              },
            ),
            // Settings (admin only)
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.editGroup),
                onTap: () {
                  Navigator.pop(context);
                  _showEditGroupDialog();
                },
              ),
            if (isAdmin)
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: const Text('Seul le propriétaire peut écrire'),
                value: _group?.onlyOwnerCanPost ?? false,
                onChanged: (value) async {
                  Navigator.pop(context);
                  try {
                    final updated = await _groupService.updateGroup(
                      int.tryParse(widget.groupId) ?? 0,
                      onlyOwnerCanPost: value,
                    );
                    setState(() {
                      _group = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Seul le propriétaire peut écrire.'
                              : 'Les membres peuvent écrire.',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorMessage(e.toString())),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(AppLocalizations.of(context)!.notifications),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.groupInfo),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfoDialog();
              },
            ),
            // Regenerate invite code (admin only)
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(AppLocalizations.of(context)!.regenerateInviteCode),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final newCode = await _groupService.regenerateInviteCode(
                      int.tryParse(widget.groupId) ?? 0,
                    );
                    await _loadGroup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.newInviteCode(newCode),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.regenerateInviteError,
                        ),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)!.leaveGroup,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                _showLeaveGroupDialog();
              },
            ),
            // Option supprimer le groupe (créateur uniquement)
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.deleteGroup,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteGroupDialog();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteGroup),
        content: Text(AppLocalizations.of(context)!.deleteGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _groupService.deleteGroup(
                  int.tryParse(widget.groupId) ?? 0,
                );
                Navigator.pop(context);
                context.go('/groups');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.groupDeleted),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.errorMessage(e.toString()),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteAction),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.inviteCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _group?.inviteCode ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.inviteCodeShareHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(AppLocalizations.of(context)!.copyAction),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _group!.inviteCode));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.inviteCodeCopied),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showGroupInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _group?.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _group!.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _group?.name.substring(0, 1).toUpperCase() ?? 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _group?.name ??
                    AppLocalizations.of(context)!.groupTitleFallback,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_group?.description != null &&
                _group!.description!.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!.descriptionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_group!.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.membersCountWithMax(
                    _group?.membersCount ?? 0,
                    _group?.maxMembers ?? 50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _group?.isPublic == true ? Icons.public : Icons.lock,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _group?.isPublic == true
                      ? AppLocalizations.of(context)!.publicGroup
                      : AppLocalizations.of(context)!.privateGroup,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: _group?.name ?? '');
    final descriptionController = TextEditingController(
      text: _group?.description ?? '',
    );
    final maxMembersController = TextEditingController(
      text: (_group?.maxMembers ?? AppConstants.maxGroupMembers).toString(),
    );
    bool isPublic = _group?.isPublic ?? false;
    File? avatarFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.editGroup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        ImageProvider<Object>? backgroundImage;
                        if (avatarFile != null) {
                          backgroundImage = FileImage(avatarFile!);
                        } else if (_group?.avatarUrl != null) {
                          backgroundImage = CachedNetworkImageProvider(
                            _group!.avatarUrl!,
                          );
                        }

                        return CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: backgroundImage,
                          child: avatarFile == null && _group?.avatarUrl == null
                              ? const Icon(Icons.group, color: Colors.grey)
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setDialogState(() {
                            avatarFile = File(image.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: Text(
                        AppLocalizations.of(context)!.changeGroupLogo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.groupNameLabel,
                    prefixIcon: const Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.descriptionLabel,
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxMembersController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.maxMembersLabel,
                    prefixIcon: const Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.publicGroup),
                  subtitle: Text(
                    AppLocalizations.of(context)!.publicGroupSubtitle,
                  ),
                  value: isPublic,
                  onChanged: (value) {
                    setDialogState(() {
                      isPublic = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final maxMembers = int.tryParse(
                    maxMembersController.text.trim(),
                  );
                  await _groupService.updateGroup(
                    int.tryParse(widget.groupId) ?? 0,
                    name: nameController.text,
                    description: descriptionController.text,
                    isPublic: isPublic,
                    maxMembers: maxMembers,
                    avatar: avatarFile,
                  );
                  Navigator.pop(context);
                  _loadGroup();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.groupUpdated),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.errorMessage(e.toString()),
                      ),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.saveAction),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.leaveGroup),
        content: Text(AppLocalizations.of(context)!.leaveGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _groupService.leaveGroup(
                  int.tryParse(widget.groupId) ?? 0,
                );
                Navigator.pop(context);
                context.go('/groups');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.leftGroupSuccess,
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.errorMessage(e.toString()),
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.leaveGroup),
          ),
        ],
      ),
    );
  }
}

// ==================== MEMBERS LIST WIDGET ====================

class _MembersListWidget extends StatefulWidget {
  final int groupId;
  final GroupService groupService;
  final ScrollController scrollController;
  final bool isAdmin;
  final VoidCallback onMemberRemoved;

  const _MembersListWidget({
    required this.groupId,
    required this.groupService,
    required this.scrollController,
    required this.isAdmin,
    required this.onMemberRemoved,
  });

  @override
  State<_MembersListWidget> createState() => _MembersListWidgetState();
}

class _MembersListWidgetState extends State<_MembersListWidget> {
  List<GroupMember> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await widget.groupService.getMembers(widget.groupId);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.groupMembersTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(context)!.membersCount(_members.length),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.errorMessage(_error ?? ''),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMembers,
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  )
                : _members.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noMembers))
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return _buildMemberTile(member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member) {
    final isAdmin = member.role == 'admin' || member.role == 'creator';
    final displayName =
        member.user?.fullName ?? AppLocalizations.of(context)!.anonymousUser;
    final initial = member.user?.initials ?? 'A';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.user?.avatar != null
            ? CachedNetworkImageProvider(member.user!.avatar!)
            : null,
        child: member.user?.avatar == null ? Text(initial) : null,
      ),
      title: Row(
        children: [
          Text(displayName),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.role == 'creator'
                    ? AppLocalizations.of(context)!.roleCreator
                    : AppLocalizations.of(context)!.roleAdmin,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: member.user?.username != null
          ? Text('@${member.user!.username}')
          : null,
      trailing: widget.isAdmin && member.role != 'creator'
          ? PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'remove') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        AppLocalizations.of(context)!.removeMemberTitle,
                      ),
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.removeMemberConfirm(displayName),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.removeAction,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await widget.groupService.removeMember(
                        widget.groupId,
                        member.id,
                      );
                      _loadMembers();
                      widget.onMemberRemoved();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.memberRemoved,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.errorMessage(e.toString()),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_remove,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.removeAction,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

// ==================== ANONYMOUS MESSAGE DETAIL SCREEN ====================

class _AnonymousMessageDetailScreen extends StatefulWidget {
  final int messageId;

  const _AnonymousMessageDetailScreen({required this.messageId});

  @override
  State<_AnonymousMessageDetailScreen> createState() =>
      _AnonymousMessageDetailScreenState();
}

class _AnonymousMessageDetailScreenState
    extends State<_AnonymousMessageDetailScreen> {
  final MessageService _messageService = MessageService();
  final ChatService _chatService = ChatService();
  AnonymousMessage? _message;
  bool _isLoading = true;
  bool _isRevealing = false;
  bool _isReplying = false;
  bool _isSharingStatus = false;
  final TextEditingController _replyController = TextEditingController();
  final GlobalKey _statusShareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadMessage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _messageService.getMessage(widget.messageId);
      setState(() {
        _message = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _revealIdentity() async {
    if (_message == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.revealIdentityTitle),
        content: Text(
          AppLocalizations.of(context)!.revealIdentityCreditsPrompt,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(AppLocalizations.of(context)!.revealIdentityAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isRevealing = true;
    });

    try {
      final revealedMessage = await _messageService.revealIdentity(
        widget.messageId,
      );
      setState(() {
        _message = revealedMessage;
        _isRevealing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.revealIdentitySuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRevealing = false;
      });
      if (mounted) {
        if (e is AppException && e.statusCode == 402) {
          final requiredAmount = Helpers.extractRequiredAmount(e.data);
          Helpers.showErrorSnackBar(
            context,
            Helpers.insufficientBalanceMessage(
              requiredAmount: requiredAmount,
            ),
          );
          context.push('/wallet');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _replyOnce() async {
    if (_message == null || _replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterMessageError),
        ),
      );
      return;
    }

    setState(() {
      _isReplying = true;
    });

    try {
      // Start conversation by replying to the message
      final result = await _messageService.startConversation(widget.messageId);
      final conversation = result['conversation'] ?? result['data'];
      final conversationId = conversation is Map
          ? (conversation['id'] ??
                conversation['conversation_id'] ??
                conversation['conversationId'])
          : (result['conversation_id'] ?? result['conversationId']);

      setState(() {
        _isReplying = false;
      });

      if (mounted) {
        // Navigate to the chat conversation
        if (conversationId != null) {
          final sentContent = _replyController.text.trim();
          final replyContent = _message?.content ?? '';
          await _chatService.sendMessage(conversationId, content: sentContent);
          _replyController.clear();
          final replyTitle = Uri.encodeComponent(
            AppLocalizations.of(context)!.anonymousMessage,
          );
          final replyEncoded = Uri.encodeComponent(replyContent);
          final sentEncoded = Uri.encodeComponent(sentContent);
          context.go(
            '/chat/$conversationId?reply_title=$replyTitle&reply_content=$replyEncoded&sent_content=$sentEncoded',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.conversationStarted),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.replySent)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isReplying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorMessage(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareOnWhatsAppStatus() async {
    if (_message == null || _isSharingStatus) return;

    setState(() {
      _isSharingStatus = true;
    });

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      if (mounted) {
        setState(() {
          _isSharingStatus = false;
        });
      }
      return;
    }
    try {
      await Future.delayed(const Duration(milliseconds: 80));

      final messageId = _message?.id;
      if (messageId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.messageNotFound)),
          );
        }
        return;
      }

      final shareContext = _statusShareKey.currentContext;
      if (shareContext == null) {
        throw Exception('status_capture_missing');
      }
      final boundaryObject = shareContext.findRenderObject();
      final boundary = boundaryObject is RenderRepaintBoundary
          ? boundaryObject
          : null;
      if (boundary == null) {
        throw Exception('status_capture_missing');
      }

      await WidgetsBinding.instance.endOfFrame;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 32));
      }
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('status_capture_failed');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/weylo_status_$messageId.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);
      if (!await file.exists()) {
        throw Exception('status_capture_failed');
      }

      try {
        await Share.shareXFiles([XFile(file.path)]);
      } on Error catch (e) {
        if (e.toString().contains('LateInitializationError')) {
          throw Exception('share_failed');
        }
        rethrow;
      }
      await _openWhatsApp();

      final username = context.read<AuthProvider>().user?.username ??
          _message?.recipient?.username;
      if (username != null && username.isNotEmpty) {
        final shareUrl = DeepLinkService.getAnonymousMessageShareLink(username);
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.copyToClipboardSuccess)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorText = e.toString();
        final isCaptureError =
            errorText.contains('status_capture_missing') ||
            errorText.contains('status_capture_failed');
        final isShareError = errorText.contains('share_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCaptureError
                  ? 'Impossible de generer l\'image du statut WhatsApp.'
                  : isShareError
                  ? 'Impossible d\'ouvrir le partage WhatsApp.'
                  : l10n.errorMessage(errorText),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingStatus = false;
        });
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final whatsappUri = Uri.parse('whatsapp://app');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }
    final fallbackUri = Uri.parse('https://wa.me/');
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp indisponible.')),
      );
    }
  }

  Widget _buildStatusShareCard(BuildContext context) {
    final message = _message?.content ?? '';

    return SizedBox(
      width: 720,
      height: 1280,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 90),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 56),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.3,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Text(
                'Weylo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    final senderId = _message?.senderId ?? 0;
    final isReceived =
        _message != null &&
        (currentUserId == null || currentUserId == 0
            ? senderId != 0
            : senderId != currentUserId);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.anonymousMessage),
        actions: [
          if (_message != null && !_message!.isIdentityRevealed)
            IconButton(
              tooltip: l10n.revealIdentityTitle,
              onPressed: _isRevealing ? null : _revealIdentity,
              icon: _isRevealing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility),
              color: AppColors.primary,
            ),
          if (_message != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.report),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.deleteAction,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'report') {
                  await _messageService.reportMessage(widget.messageId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.messageReported)),
                    );
                  }
                } else if (value == 'delete') {
                  await _messageService.deleteMessage(widget.messageId);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.messageDeleted)),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _message == null
              ? Center(child: Text(l10n.messageNotFound))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/fond.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          kToolbarHeight + 16,
                          16,
                          16,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height -
                                MediaQuery.of(context).padding.vertical,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sender info card
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      _buildAvatar(),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (_message!.isIdentityRevealed &&
                                                _message!.sender != null)
                                              Text(
                                                _message!.sender!.fullName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person_off,
                                                    size: 18,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    l10n.anonymousSender,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  Helpers.getTimeAgo(
                                                    _message!.createdAt,
                                                  ),
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (!_message!
                                                    .isIdentityRevealed)
                                                  IconButton(
                                                    tooltip: l10n
                                                        .revealIdentityTitle,
                                                    onPressed: _isRevealing
                                                        ? null
                                                        : _revealIdentity,
                                                    icon: _isRevealing
                                                        ? const SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : const Icon(
                                                            Icons.visibility,
                                                          ),
                                                    color: AppColors.primary,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Message content
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.messageLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _message!.content,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              if (_message!.isIdentityRevealed)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.success,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.identityRevealedTitle,
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.sentByUser(
                                                _message!.sender?.fullName ??
                                                    l10n.userFallback,
                                              ),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_message!.sender != null)
                                        IconButton(
                                          icon: const Icon(Icons.person),
                                          onPressed: () {
                                            context.push(
                                              '/u/${_message!.sender!.username}',
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              if (isReceived)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.reply,
                                              size: 20,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Répondre une fois',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Répondez à ce message pour démarrer une conversation dans le chat.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _replyController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Écrivez votre réponse...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: !_isReplying
                                                ? AppColors.primaryGradient
                                                : null,
                                            color: _isReplying
                                                ? Colors.grey[300]
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isReplying
                                                  ? null
                                                  : _replyOnce,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Center(
                                                child: _isReplying
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.send,
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Répondre et démarrer la conversation',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  const Color(0xFF25D366),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isSharingStatus
                                                  ? null
                                                  : _shareOnWhatsAppStatus,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Center(
                                                child: _isSharingStatus
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Image(
                                                            image: AssetImage(
                                                              'assets/icons/icons8-whatsapp-48.png',
                                                            ),
                                                            width: 20,
                                                            height: 20,
                                                            fit:
                                                                BoxFit.contain,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Répondre sur WhatsApp',
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF25D366,
                                                              ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Astuce: le lien du message est copie apres le partage.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: true,
                      child: RepaintBoundary(
                        key: _statusShareKey,
                        child: _buildStatusShareCard(context),
                      ),
                    ),
                  ],
                ),
              );
  }

  Widget _buildAvatar() {
    if (_message!.sender?.avatar != null &&
        _message!.sender!.avatar!.isNotEmpty) {
      return AvatarWidget(
        imageUrl: _message!.sender!.avatar,
        name: _message!.isIdentityRevealed ? _message!.sender!.fullName : null,
        size: 56,
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _message!.senderInitials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
