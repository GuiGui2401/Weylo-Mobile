import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:story_view/story_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/story_service.dart';
import '../services/user_service.dart';
import '../services/confession_service.dart';
import '../services/follow_service.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../services/group_service.dart';
import '../services/message_service.dart';
import '../models/story.dart' hide StoryView;
import '../models/user.dart';
import '../models/notification.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/helpers.dart';
import '../widgets/common/avatar_widget.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main/main_navigation_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/my_profile_screen.dart';
import '../screens/messages/send_message_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/stories/create_story_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/monetization/earnings_screen.dart';
import '../screens/premium/subscriptions_screen.dart';
import '../screens/premium/premium_settings_screen.dart';
import '../screens/confessions/confession_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../widgets/voice/voice_recorder_widget.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';

        // Allow deep links for public profiles and anonymous messages
        if (state.matchedLocation.startsWith('/u/') ||
            state.matchedLocation.startsWith('/send-anonymous/')) {
          return null;
        }

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        // Auth Routes
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
        GoRoute(
          path: '/home',
          redirect: (_, __) => '/',
        ),

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
            return ChatScreen(conversationId: id);
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

        // Payment WebView
        GoRoute(
          path: '/payment',
          name: 'payment',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'] ?? '';
            if (url.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Paiement')),
                body: const Center(child: Text('URL de paiement invalide')),
              );
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('Paiement'),
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
            return _AnonymousMessageDetailScreen(messageId: int.tryParse(id) ?? 0);
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
            return const _LegalScreen(title: 'Conditions d\'utilisation', type: 'terms');
          },
        ),

        // Privacy Policy
        GoRoute(
          path: '/privacy-policy',
          name: 'privacy-policy',
          builder: (context, state) {
            return const _LegalScreen(title: 'Politique de confidentialité', type: 'privacy');
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
              Text('Page non trouvée: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l\'accueil'),
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
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userService = UserService();
      final users = await userService.searchUsers(query);
      setState(() {
        _searchResults = users.map((user) => {
          'id': user.id,
          'username': user.username,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'avatar': user.avatar,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Recherchez un utilisateur pour\ncommencer une conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Screen for creating a new confession/post
class _CreateConfessionScreen extends StatefulWidget {
  const _CreateConfessionScreen();

  @override
  State<_CreateConfessionScreen> createState() => _CreateConfessionScreenState();
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
        const SnackBar(content: Text('Veuillez ajouter du contenu ou un média')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final confessionService = ConfessionService();
      await confessionService.createConfession(
        content: content.isNotEmpty ? content : null,
        type: _isPublic ? 'public' : 'private',
        isAnonymous: _isAnonymous,
        image: _selectedImage,
        video: _selectedVideo,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication créée avec succès!')),
        );
      }
    } catch (e) {
      debugPrint('Error creating confession: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publish,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Qu\'avez-vous à confesser? (optionnel avec média)',
                border: OutlineInputBorder(),
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
                                  Icon(Icons.video_library, size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vidéo sélectionnée',
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
                  label: const Text('Image'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Vidéo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Photo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publication anonyme'),
              subtitle: const Text('Votre identité sera cachée'),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
            SwitchListTile(
              title: const Text('Publication publique'),
              subtitle: const Text('Visible par tous les utilisateurs'),
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
  bool _showOnlineStatus = true;
  bool _allowMessages = true;
  bool _showNameOnPosts = true;
  bool _showPhotoOnPosts = true;
  bool _isLoading = true;
  bool _isSaving = false;
  List<User> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user?.settings != null) {
        setState(() {
          _showOnlineStatus = user!.settings!.showOnlineStatus;
          _allowMessages = user.settings!.allowAnonymousMessages;
          _showNameOnPosts = user.settings!.showNameOnPosts;
          _showPhotoOnPosts = user.settings!.showPhotoOnPosts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
      _loadBlockedUsers();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final users = await _userService.getBlockedUsers();
      setState(() => _blockedUsers = users);
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _updateSetting(String setting, bool value) async {
    setState(() => _isSaving = true);

    try {
      final currentSettings = context.read<AuthProvider>().user?.settings;

      // Create new settings object with the updated value
      final newSettings = UserSettings(
        notificationsEnabled: currentSettings?.notificationsEnabled ?? true,
        emailNotifications: currentSettings?.emailNotifications ?? true,
        pushNotifications: currentSettings?.pushNotifications ?? true,
        showOnlineStatus: setting == 'showOnlineStatus' ? value : (currentSettings?.showOnlineStatus ?? true),
        allowAnonymousMessages: setting == 'allowMessages' ? value : (currentSettings?.allowAnonymousMessages ?? true),
        showNameOnPosts: setting == 'showNameOnPosts' ? value : (currentSettings?.showNameOnPosts ?? true),
        showPhotoOnPosts: setting == 'showPhotoOnPosts' ? value : (currentSettings?.showPhotoOnPosts ?? true),
        language: currentSettings?.language ?? 'fr',
        theme: currentSettings?.theme ?? 'system',
      );

      final updatedUser = await _userService.updateSettings(newSettings);
      if (mounted) {
        // Update the auth provider with the new user data
        context.read<AuthProvider>().updateUser(updatedUser);

        // Update local state to reflect changes immediately
        setState(() {
          if (updatedUser.settings != null) {
            _showOnlineStatus = updatedUser.settings!.showOnlineStatus;
            _allowMessages = updatedUser.settings!.allowAnonymousMessages;
            _showNameOnPosts = updatedUser.settings!.showNameOnPosts;
            _showPhotoOnPosts = updatedUser.settings!.showPhotoOnPosts;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres mis à jour')),
        );
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
      if (mounted) {
        // Revert the local state if update failed
        await _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _unblockUser(User user) async {
    try {
      await _userService.unblockUser(user.username);
      setState(() => _blockedUsers.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('@${user.username} a été débloqué')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
                    'Utilisateurs bloqués (${_blockedUsers.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _blockedUsers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucun utilisateur bloqué'),
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
                            child: const Text('Débloquer'),
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
        appBar: AppBar(title: const Text('Confidentialité')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: Stack(
        children: [
          ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'VISIBILITE DU PROFIL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Afficher mon nom sur mes publications'),
                subtitle: const Text('Votre nom sera visible sur vos posts publics'),
                value: _showNameOnPosts,
                onChanged: (value) {
                  setState(() => _showNameOnPosts = value);
                  _updateSetting('showNameOnPosts', value);
                },
              ),
              SwitchListTile(
                title: const Text('Afficher ma photo sur mes publications'),
                subtitle: const Text('Votre photo de profil sera visible'),
                value: _showPhotoOnPosts,
                onChanged: (value) {
                  setState(() => _showPhotoOnPosts = value);
                  _updateSetting('showPhotoOnPosts', value);
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'ACTIVITE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Afficher le statut en ligne'),
                subtitle: const Text('Les autres peuvent voir quand vous etes en ligne'),
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() => _showOnlineStatus = value);
                  _updateSetting('showOnlineStatus', value);
                },
              ),
              SwitchListTile(
                title: const Text('Autoriser les messages anonymes'),
                subtitle: const Text('Recevoir des messages anonymes'),
                value: _allowMessages,
                onChanged: (value) {
                  setState(() => _allowMessages = value);
                  _updateSetting('allowMessages', value);
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'GESTION DU COMPTE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Utilisateurs bloques'),
                subtitle: Text('${_blockedUsers.length} utilisateur(s)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBlockedUsersSheet,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Supprimer mon compte',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Cette action est irreversible'),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte? '
          'Toutes vos données seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernière mise à jour: 1er Janvier 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'En utilisant Weylo, vous acceptez les conditions suivantes...',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '1. Utilisation du service\n\nWeylo est une plateforme de messagerie anonyme. '
              'En utilisant ce service, vous vous engagez à respecter les autres utilisateurs '
              'et à ne pas publier de contenu illégal ou offensant.\n\n'
              '2. Confidentialité\n\nNous respectons votre vie privée. Vos messages anonymes '
              'ne révèlent pas votre identité sauf si vous choisissez de la révéler.\n\n'
              '3. Responsabilité\n\nVous êtes responsable du contenu que vous publiez. '
              'Weylo se réserve le droit de supprimer tout contenu inapproprié.',
              style: TextStyle(fontSize: 14, height: 1.5),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Questions fréquentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Comment envoyer un message anonyme?',
            'Allez sur le profil d\'un utilisateur et tapez sur "Envoyer un message". '
            'Votre identité restera cachée à moins que vous ne choisissiez de la révéler.',
          ),
          _buildFAQItem(
            'Comment voir qui m\'a envoyé un message?',
            'Par défaut, les messages sont anonymes. Vous pouvez demander la révélation '
            'd\'identité moyennant des pièces ou un abonnement Premium.',
          ),
          _buildFAQItem(
            'Comment partager mon lien?',
            'Allez dans votre profil et tapez sur "Partager le profil". '
            'Vous pouvez partager votre lien sur les réseaux sociaux.',
          ),
          _buildFAQItem(
            'Comment contacter le support?',
            'Envoyez un email à support@weylo.app pour toute question ou problème.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@weylo.app',
                queryParameters: {
                  'subject': 'Support - Weylo',
                },
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible d\'ouvrir le client email'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text('Contacter le support'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
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
              const Text(
                'Weylo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              const Text(
                'La plateforme de messagerie anonyme\nqui connecte les gens en toute sécurité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 Weylo. Tous droits réservés.',
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
  String? _avatarUrl;

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
              title: const Text('Prendre une photo'),
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
              title: const Text('Choisir dans la galerie'),
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
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
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
          const SnackBar(content: Text('Photo de profil mise à jour!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
          const SnackBar(content: Text('Photo de profil supprimée!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      if (mounted) {
        // Update user in auth provider
        context.read<AuthProvider>().updateUser(updatedUser);

        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
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
                child: const Text('Changer la photo de profil'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Parlez de vous...',
                border: OutlineInputBorder(),
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

  Future<void> _purchasePremium() async {
    setState(() => _isPurchasing = true);

    try {
      await _premiumService.purchasePass();
      await _loadPremiumStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement Premium activé!')),
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
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
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
                  ? 'Renouvellement automatique activé'
                  : 'Renouvellement automatique désactivé',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPremium = user?.isPremium ?? false;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weylo Premium')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weylo Premium')),
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
                    const Text(
                      'Vous êtes Premium!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_passStatus?.daysRemaining != null && _passStatus!.daysRemaining > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_passStatus!.daysRemaining} jours restants',
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
                  title: const Text('Renouvellement automatique'),
                  subtitle: const Text('Renouveler automatiquement votre abonnement'),
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
                child: const Column(
                  children: [
                    Icon(Icons.star, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Weylo Premium',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Débloquez toutes les fonctionnalités',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Features
            _buildFeature(Icons.visibility, 'Voir l\'identité', 'Révélez qui vous envoie des messages'),
            _buildFeature(Icons.verified, 'Badge Premium', 'Montrez votre statut Premium'),
            _buildFeature(Icons.block, 'Sans publicités', 'Profitez d\'une expérience sans pub'),
            _buildFeature(Icons.analytics, 'Statistiques avancées', 'Analysez vos interactions'),
            const SizedBox(height: 24),
            // Pricing (only for non-premium users)
            if (!isPremium && _passStatus?.isActive != true) ...[
              Card(
                child: ListTile(
                  title: const Text('Mensuel'),
                  subtitle: const Text('2 500 FCFA/mois'),
                  trailing: ElevatedButton(
                    onPressed: _isPurchasing ? null : _purchasePremium,
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('S\'abonner'),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Annuel'),
                  subtitle: const Text('20 000 FCFA/an (économisez 33%)'),
                  trailing: ElevatedButton(
                    onPressed: _isPurchasing ? null : _purchasePremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('S\'abonner'),
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
          const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune notification'),
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
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
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
  final StoryController _storyController = StoryController();
  final StoryService _storyService = StoryService();
  List<StoryItem> _storyItems = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  String? _error;
  User? _storyUser;

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
          _error = 'ID utilisateur invalide';
          _isLoading = false;
        });
        return;
      }
      final stories = await _storyService.getUserStoriesById(userId);

      if (stories.isEmpty) {
        setState(() {
          _error = 'Aucune story disponible';
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
          _error = 'Utilisateur non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Convert to StoryItems
      final items = <StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            StoryItem.text(
              title: story.content ?? '',
              backgroundColor: _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            StoryItem.pageImage(
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
            StoryItem.pageVideo(
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
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
            _error ?? 'Aucune story disponible',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.of(context).pop();
              }
            },
            progressPosition: ProgressPosition.top,
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
  final StoryController _storyController = StoryController();
  final StoryService _storyService = StoryService();
  List<StoryItem> _storyItems = [];
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
          _error = 'Vous n\'avez pas de story active';
          _isLoading = false;
        });
        return;
      }

      _stories = stories;

      // Convert to StoryItems
      final items = <StoryItem>[];
      for (final story in stories) {
        if (story.isText) {
          items.add(
            StoryItem.text(
              title: story.content ?? '',
              backgroundColor: _parseColor(story.backgroundColor) ?? const Color(0xFF6366F1),
              duration: Duration(seconds: story.duration),
            ),
          );
        } else if (story.isImage && story.mediaUrl != null) {
          items.add(
            StoryItem.pageImage(
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
            StoryItem.pageVideo(
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
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
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
        title: const Text('Supprimer la story?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
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
          const SnackBar(content: Text('Story supprimée')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
                _error ?? 'Aucune story',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/create-story');
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une story'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: () => Navigator.of(context).pop(),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
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
            progressPosition: ProgressPosition.top,
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
                      const Text(
                        'Ma story',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_stories.isNotEmpty && _currentIndex < _stories.length)
                        Text(
                          '${_stories[_currentIndex].viewsCount} vues',
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
                  icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
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

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
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
                  '${story.viewsCount} vues',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (story.viewers != null && story.viewers!.isNotEmpty)
              ...story.viewers!.map((viewer) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: viewer.user?.avatar != null
                      ? CachedNetworkImageProvider(viewer.user!.avatar!)
                      : null,
                  child: viewer.user?.avatar == null
                      ? Text(viewer.user?.initials ?? '?')
                      : null,
                ),
                title: Text(viewer.user?.fullName ?? 'Utilisateur'),
                subtitle: Text('@${viewer.user?.username ?? ''}'),
              ))
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Les vues seront affichées ici'),
                ),
              ),
          ],
        ),
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

      final List<dynamic> data = response['data']['data'] ?? response['data'] ?? [];
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
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnés')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun abonné', style: TextStyle(color: Colors.grey)),
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: user.avatar != null
            ? CachedNetworkImageProvider(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(user.initials, style: const TextStyle(color: AppColors.primary))
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text('@${user.username}'),
      trailing: isCurrentUser
          ? null
          : OutlinedButton(
              onPressed: () => _toggleFollow(user),
              style: OutlinedButton.styleFrom(
                backgroundColor: user.isFollowing == true ? null : AppColors.primary,
                foregroundColor: user.isFollowing == true ? AppColors.primary : Colors.white,
              ),
              child: Text(user.isFollowing == true ? 'Abonné' : 'Suivre'),
            ),
      onTap: () => context.push('/u/${user.username}'),
    );
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

      final List<dynamic> data = response['data']['data'] ?? response['data'] ?? [];
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
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnements')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _following.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun abonnement', style: TextStyle(color: Colors.grey)),
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: user.avatar != null
            ? CachedNetworkImageProvider(user.avatar!)
            : null,
        child: user.avatar == null
            ? Text(user.initials, style: const TextStyle(color: AppColors.primary))
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text('@${user.username}'),
      trailing: isCurrentUser
          ? null
          : OutlinedButton(
              onPressed: () => _toggleFollow(user),
              style: OutlinedButton.styleFrom(
                backgroundColor: user.isFollowing == true ? null : AppColors.primary,
                foregroundColor: user.isFollowing == true ? AppColors.primary : Colors.white,
              ),
              child: Text(user.isFollowing == true ? 'Abonné' : 'Suivre'),
            ),
      onTap: () => context.push('/u/${user.username}'),
    );
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

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showVoiceRecorder = false;
  File? _selectedImage;
  File? _voiceFile;
  String? _groupName;
  Group? _group;
  int? _currentUserId;
  Map<String, dynamic>? _replyToMessage;
  int? _editingMessageId;

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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    try {
      final group = await _groupService.getGroup(int.tryParse(widget.groupId) ?? 0);
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

  Future<void> _loadMessages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      final result = await _groupService.getMessages(int.tryParse(widget.groupId) ?? 0);
      setState(() {
        _messages = result.messages.map((m) {
          final json = m.toJson();
          // Add is_mine field for message bubbles
          json['is_mine'] = json['sender_id'] == currentUserId || json['user_id'] == currentUserId;
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
      });
    }
  }

  void _onVoiceRecorded(File file, dynamic effect) {
    setState(() {
      _voiceFile = file;
      _showVoiceRecorder = false;
    });
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();

    if (content.isEmpty && _selectedImage == null && _voiceFile == null) {
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
          const SnackBar(content: Text('Message modifié')),
        );
        _loadMessages();
        return;
      }

      // Handle reply
      final replyToId = _replyToMessage?['id'];

      await _groupService.sendMessage(
        groupId: int.tryParse(widget.groupId) ?? 0,
        content: content,
        image: _selectedImage,
        voice: _voiceFile,
        replyToId: replyToId,
      );

      _messageController.clear();
      setState(() {
        _selectedImage = null;
        _voiceFile = null;
        _replyToMessage = null;
        _isSending = false;
      });

      _loadMessages();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName ?? 'Groupe'),
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
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun message',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Envoyez un message pour demarrer la conversation',
                              style: TextStyle(color: Colors.grey),
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
                          return _buildMessageBubble(message);
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
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: VoiceRecorderWidget(
                onRecordingComplete: _onVoiceRecorded,
                showEffectSelector: true,
              ),
            ),

          // Reply preview
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
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
                          'Répondre à ${_replyToMessage!['sender']?['full_name'] ?? 'Utilisateur'}',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: Colors.amber[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modification du message',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.amber),
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

          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                      color: _selectedImage != null ? AppColors.primary : Colors.grey,
                    ),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: _showVoiceRecorder ? AppColors.primary : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showVoiceRecorder = !_showVoiceRecorder;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null
                            ? 'Modifier le message...'
                            : 'Ecrire un message...',
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary),
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['is_mine'] == true;
    final mediaUrl = message['media_full_url'] ?? message['media_url'];
    final messageType = message['type'] ?? 'text';
    final hasImage = messageType == 'image' && mediaUrl != null;
    final hasVoice = messageType == 'voice' && mediaUrl != null;
    final senderId = message['sender_id'] ?? message['sender']?['id'] ?? 0;
    final senderColor = isMe ? AppColors.primary : _getUserColor(senderId);
    final replyTo = message['reply_to_message'];

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && message['sender'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message['sender']['full_name'] ?? 'Utilisateur',
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
                    color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white70 : senderColor,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    replyTo['content'] ?? '',
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
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasVoice)
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      color: isMe ? Colors.white : senderColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white30 : Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              if (message['content'] != null && message['content'].isNotEmpty)
                Text(
                  message['content'],
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                  ),
              ),
          ],
        ),
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
              title: const Text('Répondre'),
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
                title: const Text('Modifier'),
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
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  _showDeleteMessageDialog(message['id']);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message['content'] ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copié')),
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
        title: const Text('Supprimer le message'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
                  const SnackBar(content: Text('Message supprimé')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
          isAdmin: _group != null && _currentUserId != null && _group!.creatorId == _currentUserId,
          onMemberRemoved: () => _loadGroup(),
        ),
      ),
    );
  }

  void _showOptions() {
    final isAdmin = _group != null && _currentUserId != null && _group!.creatorId == _currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Invite code
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('Code d\'invitation'),
              subtitle: Text(_group?.inviteCode ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (_group?.inviteCode != null) {
                    Clipboard.setData(ClipboardData(text: _group!.inviteCode));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
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
                title: const Text('Modifier le groupe'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditGroupDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Infos du groupe'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfoDialog();
              },
            ),
            // Regenerate invite code (admin only)
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Régénérer le code d\'invitation'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final newCode = await _groupService.regenerateInviteCode(
                      int.tryParse(widget.groupId) ?? 0,
                    );
                    await _loadGroup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nouveau code: $newCode')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de la régénération')),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Quitter le groupe', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                _showLeaveGroupDialog();
              },
            ),
            // Option supprimer le groupe (créateur uniquement)
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer le groupe', style: TextStyle(color: Colors.red)),
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
        title: const Text('Supprimer le groupe'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce groupe ?\n\n'
          'Cette action est irréversible. Tous les messages et les membres seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _groupService.deleteGroup(int.tryParse(widget.groupId) ?? 0);
                Navigator.pop(context);
                context.go('/groups');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Groupe supprimé')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
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
        title: const Text('Code d\'invitation'),
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
            const Text(
              'Partagez ce code pour inviter des personnes à rejoindre le groupe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _group!.inviteCode));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copié !')),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_group?.name ?? 'Groupe')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_group?.description != null && _group!.description!.isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_group!.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_group?.membersCount ?? 0}/${_group?.maxMembers ?? 50} membres'),
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
                Text(_group?.isPublic == true ? 'Groupe public' : 'Groupe privé'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog() {
    final nameController = TextEditingController(text: _group?.name ?? '');
    final descriptionController = TextEditingController(text: _group?.description ?? '');
    bool isPublic = _group?.isPublic ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le groupe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Groupe public'),
                  subtitle: const Text('Visible dans la découverte'),
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
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _groupService.updateGroup(
                    int.tryParse(widget.groupId) ?? 0,
                    name: nameController.text,
                    description: descriptionController.text,
                    isPublic: isPublic,
                  );
                  Navigator.pop(context);
                  _loadGroup();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Groupe modifié !')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              child: const Text('Enregistrer'),
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
        title: const Text('Quitter le groupe'),
        content: const Text('Êtes-vous sûr de vouloir quitter ce groupe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _groupService.leaveGroup(int.tryParse(widget.groupId) ?? 0);
                Navigator.pop(context);
                context.go('/groups');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vous avez quitté le groupe')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
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
                const Text(
                  'Membres du groupe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_members.length} membres',
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
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Erreur: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMembers,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _members.isEmpty
                        ? const Center(child: Text('Aucun membre'))
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
    final displayName = member.user?.fullName ?? 'Anonyme';
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
                member.role == 'creator' ? 'Créateur' : 'Admin',
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
                      title: const Text('Retirer le membre'),
                      content: Text('Voulez-vous retirer $displayName du groupe ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Retirer'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await widget.groupService.removeMember(widget.groupId, member.id);
                      _loadMembers();
                      widget.onMemberRemoved();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Membre retiré')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Retirer', style: TextStyle(color: Colors.red)),
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
  State<_AnonymousMessageDetailScreen> createState() => _AnonymousMessageDetailScreenState();
}

class _AnonymousMessageDetailScreenState extends State<_AnonymousMessageDetailScreen> {
  final MessageService _messageService = MessageService();
  AnonymousMessage? _message;
  bool _isLoading = true;
  bool _isRevealing = false;
  bool _isReplying = false;
  final TextEditingController _replyController = TextEditingController();

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
          SnackBar(content: Text('Erreur: ${e.toString()}')),
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
        title: const Text('Révéler l\'identité'),
        content: const Text(
          'Voulez-vous dépenser des crédits pour découvrir qui a envoyé ce message?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Révéler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isRevealing = true;
    });

    try {
      final revealedMessage = await _messageService.revealIdentity(widget.messageId);
      setState(() {
        _message = revealedMessage;
        _isRevealing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identité révélée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRevealing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _replyOnce() async {
    if (_message == null || _replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un message')),
      );
      return;
    }

    setState(() {
      _isReplying = true;
    });

    try {
      // Start conversation by replying to the message
      final result = await _messageService.startConversation(widget.messageId);

      setState(() {
        _isReplying = false;
      });

      if (mounted) {
        // Navigate to the chat conversation
        final conversationId = result['conversation_id'] ?? result['conversationId'];
        if (conversationId != null) {
          context.go('/chat/$conversationId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation démarrée! Vous pouvez maintenant discuter.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Réponse envoyée!')),
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
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message anonyme'),
        actions: [
          if (_message != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Signaler'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'report') {
                  await _messageService.reportMessage(widget.messageId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message signalé')),
                    );
                  }
                } else if (value == 'delete') {
                  await _messageService.deleteMessage(widget.messageId);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message supprimé')),
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
              ? const Center(child: Text('Message introuvable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_message!.isIdentityRevealed && _message!.sender != null)
                                      Text(
                                        _message!.sender!.fullName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.person_off, size: 18, color: AppColors.textSecondary),
                                          SizedBox(width: 8),
                                          Text(
                                            'Expéditeur anonyme',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Helpers.getTimeAgo(_message!.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Message',
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

                      // Reveal identity button
                      if (!_message!.isIdentityRevealed)
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isRevealing ? null : _revealIdentity,
                            icon: _isRevealing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.visibility, color: Colors.white),
                            label: Text(
                              _isRevealing ? 'Révélation...' : 'Payer pour découvrir l\'identité',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Identité révélée',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Envoyé par ${_message!.sender?.fullName ?? 'Utilisateur'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              if (_message!.sender != null)
                                IconButton(
                                  icon: const Icon(Icons.person),
                                  onPressed: () {
                                    context.push('/u/${_message!.sender!.username}');
                                  },
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Reply section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.reply, size: 20, color: AppColors.primary),
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
                                  hintText: 'Écrivez votre réponse...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isReplying ? null : _replyOnce,
                                  icon: _isReplying
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send),
                                  label: Text(_isReplying ? 'Envoi...' : 'Répondre et démarrer la conversation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
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

  Widget _buildAvatar() {
    if (_message!.isIdentityRevealed && _message!.sender != null) {
      return AvatarWidget(
        imageUrl: _message!.sender!.avatar,
        name: _message!.sender!.fullName,
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
