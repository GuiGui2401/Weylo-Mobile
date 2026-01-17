import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../models/conversation.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/voice/voice_recorder_widget.dart';
import '../../services/voice_effects_service.dart';

class SendMessageScreen extends StatefulWidget {
  final String recipientUsername;

  const SendMessageScreen({super.key, required this.recipientUsername});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();
  final UserService _userService = UserService();

  /// Conseil: passez ChatService(debugLogs:true) si vous avez intégré la version
  /// précédente que je vous ai donnée. Sinon laissez ChatService().
  final ChatService _chatService = ChatService();

  // Activez/désactivez les logs de debug de cet écran
  final bool _debugLogs = true;

  bool _isAnonymous = true;
  bool _isSending = false;
  bool _showVoiceRecorder = false;
  File? _selectedImage;
  File? _voiceFile;
  VoiceEffect _selectedEffect = VoiceEffect.none;

  String? _selectedRecipient;

  bool _isSearching = false;
  List<User> _searchResults = [];
  List<User> _defaultUsers = [];
  bool _isLoadingUsers = true;
  String _searchQuery = '';

  List<Conversation> _conversations = [];
  bool _isLoadingConversations = true;

  /// Index robustes pour gérer:
  /// - "pas de conversation" => masqué
  /// - "conversation(s) existent" => revealed = OR(logique) sur les doublons
  final Map<String, bool> _hasConversationByUsername = {};
  final Map<String, bool> _revealedByUsername = {};

  void _log(String message) {
    if (_debugLogs) {
      debugPrint('[SendMessageScreen] $message');
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.recipientUsername.isNotEmpty) {
      _selectedRecipient = widget.recipientUsername;
    }

    // IMPORTANT: charger conversations d'abord, puis users,
    // sinon le tri/masquage se fait avant d'avoir les conversations.
    _initData();
  }

  Future<void> _initData() async {
    await _loadConversations();
    await _loadUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _hasConversationWithUser(String username) =>
      _hasConversationByUsername[username] ?? false;

  bool _isIdentityRevealedForUser(String username) =>
      _revealedByUsername[username] ?? false;

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _userService.searchUsers('', perPage: 1000);
      if (!mounted) return;

      final sorted = _sortUsers(users);

      setState(() {
        _defaultUsers = sorted;
      });

      _log('Users chargés: ${users.length} (defaultUsers affichés: ${_defaultUsers.length})');
    } catch (e) {
      _log('Error loading users: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoadingConversations = true;
    });

    try {
      final conversations = await _chatService.getConversations();
      if (!mounted) return;

      _conversations = conversations;

      // Rebuild index
      _hasConversationByUsername.clear();
      _revealedByUsername.clear();

      for (final conv in conversations) {
        final username = conv.otherParticipant?.username;
        if (username == null || username.isEmpty) continue;

        _hasConversationByUsername[username] = true;

        final previous = _revealedByUsername[username] ?? false;
        final current = conv.isIdentityRevealed == true;

        // OR logique : si une seule conv est révélée => global = true
        _revealedByUsername[username] = previous || current;
      }

      setState(() {
        // retrier si users déjà chargés
        _defaultUsers = _sortUsers(_defaultUsers);
        _searchResults = _sortUsers(_searchResults);
      });

      // DEBUG
      _log('Conversations chargées: ${conversations.length}');
      if (_debugLogs) {
        for (final conv in conversations) {
          _log('Conv: ${conv.otherParticipant?.username} - isIdentityRevealed: ${conv.isIdentityRevealed}');
        }

        _log('Index hasConversation: ${_hasConversationByUsername.length} users');
        _log('Index revealed: ${_revealedByUsername.entries.where((e) => e.value).length} users revealed');
      }
    } catch (e) {
      _log('Error loading conversations: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    try {
      final users = await _userService.searchUsers(query, perPage: 100);
      if (!mounted) return;

      final sorted = _sortUsers(users);

      setState(() {
        _searchResults = sorted;
        _isSearching = false;
      });

      _log('Recherche "$query" => ${users.length} résultats');
    } catch (e) {
      _log('Error searching users: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  /// Tri:
  /// 1) Identité révélée (infos visibles)
  /// 2) Le reste (masqué), trié par username
  List<User> _sortUsers(List<User> users) {
    final revealed = users
        .where((u) => _isIdentityRevealedForUser(u.username))
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    final masked = users
        .where((u) => !_isIdentityRevealedForUser(u.username))
        .toList()
      ..sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    return [...revealed, ...masked];
  }

  Widget _buildUsersPanel() {
    final hasQuery = _searchQuery.isNotEmpty;
    final isLoading = hasQuery ? _isSearching : (_isLoadingUsers || _isLoadingConversations);

    final users = hasQuery ? _searchResults : _defaultUsers;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          hasQuery ? 'Aucun utilisateur trouvé' : 'Aucun utilisateur disponible pour le moment',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) => _buildUserTile(users[index]),
    );
  }

  Widget _buildUserTile(User user) {
    final username = user.username;

    final hasConversation = _hasConversationWithUser(username);
    final isIdentityRevealed = _isIdentityRevealedForUser(username);

    /// RÈGLE MÉTIER:
    /// - Si identityRevealed == true => infos visibles
    /// - Sinon => infos masquées (même si pas de conversation)
    final shouldHideInfo = !isIdentityRevealed;

    final title = shouldHideInfo ? 'Anonyme' : user.fullName;
    final subtitle = shouldHideInfo ? 'Informations masquées' : '@${user.username}';
    final avatarName = shouldHideInfo
        ? (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
        : user.fullName;

    late String statusBadge;
    late Color statusColor;

    if (isIdentityRevealed) {
      statusBadge = 'Révélée';
      statusColor = Colors.green;
    } else if (hasConversation) {
      statusBadge = 'Anonyme';
      statusColor = Colors.orange;
    } else {
      statusBadge = 'Masqué';
      statusColor = Colors.grey;
    }

    if (_debugLogs) {
      _log('Tile @$username => hasConv=$hasConversation, revealed=$isIdentityRevealed, hide=$shouldHideInfo');
    }

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
              isIdentityRevealed
                  ? Icons.visibility
                  : (hasConversation ? Icons.visibility_off : Icons.person_outline),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        setState(() {
          _selectedRecipient = user.username;
        });
      },
    );
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

  void _onVoiceRecorded(File file, VoiceEffect effect) {
    setState(() {
      _voiceFile = file;
      _selectedEffect = effect;
      _showVoiceRecorder = false;
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un destinataire')),
      );
      return;
    }

    if (message.isEmpty && _selectedImage == null && _voiceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un message')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendAnonymousMessage(
        recipientUsername: _selectedRecipient!,
        content: message,
        isAnonymous: _isAnonymous,
        image: _selectedImage,
        voice: _voiceFile,
        voiceEffect: _selectedEffect != VoiceEffect.none ? _selectedEffect.name : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Envoyer un message')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
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
            Expanded(child: _buildUsersPanel()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau message'),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendMessage,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Envoyer'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnonymous ? Icons.visibility_off : Icons.visibility,
                          color: _isAnonymous ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAnonymous ? 'Mode anonyme' : 'Mode public',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isAnonymous ? 'Votre identité sera cachée' : 'Votre nom sera visible',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_voiceFile != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Message vocal enregistré',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_selectedEffect != VoiceEffect.none)
                                  Text(
                                    'Effet: ${VoiceEffectsService.getEffectName(_selectedEffect)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _voiceFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_showVoiceRecorder)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: VoiceRecorderWidget(
                        onRecordingComplete: _onVoiceRecorded,
                        showEffectSelector: true,
                        selectedEffect: _selectedEffect,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    color: _selectedImage != null ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: _showVoiceRecorder || _voiceFile != null ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showVoiceRecorder = !_showVoiceRecorder;
                    });
                  },
                ),
                const Spacer(),
                if (_showVoiceRecorder)
                  PopupMenuButton<VoiceEffect>(
                    icon: const Icon(Icons.tune),
                    onSelected: (effect) {
                      setState(() {
                        _selectedEffect = effect;
                      });
                    },
                    itemBuilder: (context) => VoiceEffect.values.map((effect) {
                      return PopupMenuItem(
                        value: effect,
                        child: Row(
                          children: [
                            Icon(
                              _selectedEffect == effect ? Icons.check_circle : Icons.circle_outlined,
                              color: _selectedEffect == effect ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(VoiceEffectsService.getEffectName(effect)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
