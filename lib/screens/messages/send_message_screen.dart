import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user.dart';
import '../../models/conversation.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../services/chat_service.dart';
import '../../services/widgets/common/widgets.dart';
import '../../services/widgets/voice/voice_recorder_widget.dart';
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
  final ChatService _chatService = ChatService(debugLogs: true);

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
  
  Map<String, ConversationIndex> _conversationIndex = {};
  bool _isLoadingConversations = true;

  @override
  void initState() {
    super.initState();
    if (widget.recipientUsername.isNotEmpty) {
      _selectedRecipient = widget.recipientUsername;
    }
    _loadUsers();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _userService.searchUsers('', perPage: 1000);
      if (!mounted) return;
      setState(() {
        _defaultUsers = users;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    debugPrint('>>> [SendMessageScreen] Début du chargement des conversations...');
    setState(() {
      _isLoadingConversations = true;
    });

    try {
      debugPrint('>>> [SendMessageScreen] Appel à _chatService.getConversations()...');
      final conversations = await _chatService.getConversations();
      debugPrint('>>> [SendMessageScreen] Conversations reçues: ${conversations.length}');
      
      for (var conv in conversations) {
        debugPrint('>>> Conversation avec: ${conv.otherParticipant?.username} - isIdentityRevealed: ${conv.isIdentityRevealed}');
      }

      final conversationIndex = await _chatService.getConversationsIndexByUsername(
        conversations: conversations,
      );
      
      if (!mounted) return;
      setState(() {
        _conversationIndex = conversationIndex;
      });
    } catch (e) {
      debugPrint('>>> [ERROR] Error loading conversations: $e');
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
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }


  Widget _buildUsersPanel() {
    final hasQuery = _searchQuery.isNotEmpty;
    final isLoading = hasQuery ? _isSearching : _isLoadingUsers;
    final users = hasQuery ? _searchResults : _defaultUsers;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          hasQuery
              ? 'Aucun utilisateur trouvé'
              : 'Aucun utilisateur disponible pour le moment',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final sections = _buildUserSections(users);
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
          hasQuery
              ? 'Aucun utilisateur trouvé'
              : 'Aucun utilisateur disponible pour le moment',
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
    final index = _conversationIndex[user.username];
    final hasConversation = index?.hasConversation ?? false;
    final isIdentityRevealed = index?.isIdentityRevealed ?? false;

    final shouldHideInfo = !hasConversation || !isIdentityRevealed;

    final title = shouldHideInfo ? 'Anonyme' : user.fullName;
    final subtitle = shouldHideInfo ? 'Informations masquées' : '@${user.username}';
    final avatarName = shouldHideInfo 
        ? (user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
        : user.fullName;

    late String statusBadge;
    late Color statusColor;
    
    if (!hasConversation) {
      statusBadge = 'Nouveau';
      statusColor = Colors.blue;
    } else if (isIdentityRevealed) {
      statusBadge = 'Révélée';
      statusColor = Colors.green;
    } else {
      statusBadge = 'Anonyme';
      statusColor = Colors.orange;
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
              hasConversation
                  ? (isIdentityRevealed ? Icons.visibility : Icons.visibility_off)
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        setState(() {
          _selectedRecipient = user.username;
        });
      },
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (section.helper.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                section.helper,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_UserSection> _buildUserSections(List<User> users) {
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
          (a, b) => _userDisplayName(a)
              .toLowerCase()
              .compareTo(_userDisplayName(b).toLowerCase()),
        );

    sortByName(revealed);
    sortByName(anonymous);
    sortByName(withoutConversation);

    return [
      _UserSection(
        title: 'Conversations révélées',
        helper: 'Ils ont déjà dévoilé leur identité',
        accentColor: Colors.green,
        users: revealed,
      ),
      _UserSection(
        title: 'Conversations anonymes',
        helper: 'Identité masquée malgré un échange',
        accentColor: Colors.orange,
        users: anonymous,
      ),
      _UserSection(
        title: 'Sans conversation',
        helper: 'Pas encore échangé avec vous',
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
        voiceEffect: _selectedEffect != VoiceEffect.none
            ? _selectedEffect.name
            : null,
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
        title: Text('Nouveau message'),
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
                          _isAnonymous
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _isAnonymous ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAnonymous ? 'Mode anonyme' : 'Mode public',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isAnonymous
                                    ? 'Votre identité sera cachée'
                                    : 'Votre nom sera visible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
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
                    color: _selectedImage != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: _showVoiceRecorder || _voiceFile != null
                        ? AppColors.primary
                        : Colors.grey,
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
                              _selectedEffect == effect
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: _selectedEffect == effect
                                  ? AppColors.primary
                                  : Colors.grey,
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
