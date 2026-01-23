import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/helpers.dart';
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

class _SendMessageScreenState extends State<SendMessageScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  final ImagePicker _imagePicker = ImagePicker();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService(debugLogs: true);

  bool _isAnonymous = false;
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
  bool _isLoadingRevealPrice = false;
  int? _revealIdentityPrice;
  final Set<String> _revealingUsers = {};
  late final AnimationController _shimmerController;

  Map<String, ConversationIndex> _conversationIndex = {};
  bool _isLoadingConversations = true;

  @override
  void initState() {
    super.initState();
    if (widget.recipientUsername.isNotEmpty) {
      _selectedRecipient = widget.recipientUsername;
    }
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadUsers();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _shimmerController.dispose();
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
    debugPrint(
      '>>> [SendMessageScreen] Début du chargement des conversations...',
    );
    setState(() {
      _isLoadingConversations = true;
    });

    try {
      debugPrint(
        '>>> [SendMessageScreen] Appel à _chatService.getConversations()...',
      );
      final conversations = await _chatService.getConversations();
      debugPrint(
        '>>> [SendMessageScreen] Conversations reçues: ${conversations.length}',
      );

      for (var conv in conversations) {
        debugPrint(
          '>>> Conversation avec: ${conv.otherParticipant?.username} - isIdentityRevealed: ${conv.isIdentityRevealed}',
        );
      }

      final conversationIndex = await _chatService
          .getConversationsIndexByUsername(conversations: conversations);

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

  Future<int?> _ensureRevealIdentityPrice() async {
    if (_revealIdentityPrice != null) return _revealIdentityPrice;
    if (_isLoadingRevealPrice) return _revealIdentityPrice;
    setState(() {
      _isLoadingRevealPrice = true;
    });

    try {
      final price = await _chatService.getRevealIdentityPrice();
      if (!mounted) return _revealIdentityPrice;
      setState(() {
        _revealIdentityPrice = price;
      });
      return price;
    } catch (_) {
      return _revealIdentityPrice;
    } finally {
      if (!mounted) return _revealIdentityPrice;
      setState(() {
        _isLoadingRevealPrice = false;
      });
    }
  }

  Widget _buildRevealIdentityPromptSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerBar(width: double.infinity, height: 12),
        const SizedBox(height: 8),
        _buildShimmerBar(width: 180, height: 12),
      ],
    );
  }

  Widget _buildShimmerBar({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + progress * 2.0, 0),
              end: Alignment(1.0 + progress * 2.0, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
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

  Future<void> _promptRevealIdentity(User user) async {
    final l10n = AppLocalizations.of(context)!;
    final index = _conversationIndex[user.username];
    final conversationId = index?.sampleConversation?.id;

    if (conversationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurredTitle)),
      );
      return;
    }

    final priceFuture = _ensureRevealIdentityPrice();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return FutureBuilder<int?>(
          future: priceFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final amountLabel = snapshot.data != null
                ? '${snapshot.data} FCFA'
                : '...';
            return AlertDialog(
              title: Text(l10n.revealIdentityTitle),
              content: isLoading
                  ? _buildRevealIdentityPromptSkeleton()
                  : Text(l10n.revealIdentityPrompt(amountLabel)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context, true),
                  child: Text(l10n.revealIdentityAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _revealingUsers.add(user.username);
      });
      final conversation = await _chatService.revealIdentity(conversationId);
      if (!mounted) return;
      setState(() {
        _conversationIndex[user.username] =
            (_conversationIndex[user.username] ??
                    ConversationIndex(
                      username: user.username,
                      hasConversation: true,
                      isIdentityRevealed: true,
                      sampleConversation: conversation,
                    ))
                .copyWith(
                  isIdentityRevealed: true,
                  sampleConversation: conversation,
                );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.revealIdentitySuccessWithName(
              conversation.otherParticipant?.fullName ?? user.fullName,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is AppException && e.statusCode == 402) {
        final requiredAmount = Helpers.extractRequiredAmount(e.data);
        Helpers.showErrorSnackBar(
          context,
          Helpers.insufficientBalanceMessage(requiredAmount: requiredAmount),
        );
        context.push('/wallet');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _revealingUsers.remove(user.username);
      });
    }
  }

  Widget _buildUsersPanel() {
    final l10n = AppLocalizations.of(context)!;
    final hasQuery = _searchQuery.isNotEmpty;
    final isLoading = hasQuery ? _isSearching : _isLoadingUsers;
    final users = hasQuery ? _searchResults : _defaultUsers;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          hasQuery ? l10n.noUsersFound : l10n.noUsersAvailable,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final sections = _buildUserSections(l10n, users);
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
          hasQuery ? l10n.noUsersFound : l10n.noUsersAvailable,
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
    final isRevealing = _revealingUsers.contains(user.username);

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
      trailing: hasConversation && !isIdentityRevealed
          ? TextButton(
              onPressed: isRevealing ? null : () => _promptRevealIdentity(user),
              child: isRevealing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.revealIdentityAction),
            )
          : null,
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
    final l10n = AppLocalizations.of(context)!;
    final message = _messageController.text.trim();

    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectRecipientError)));
      return;
    }

    if (message.isEmpty && _selectedImage == null && _voiceFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterMessageError)));
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
          SnackBar(
            content: Text(l10n.messageSentSuccess),
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
          content: Text(l10n.errorMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRecipient == null || _selectedRecipient!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sendMessageTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
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
            Expanded(child: _buildUsersPanel()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newMessageTitle),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendMessage,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.sendAction),
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
                  TextField(
                    controller: _messageController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: l10n.messageHint,
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
                                Text(
                                  l10n.voiceMessageRecorded,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedEffect != VoiceEffect.none)
                                  Text(
                                    l10n.voiceEffectLabel(
                                      VoiceEffectsService.getEffectName(
                                        _selectedEffect,
                                      ),
                                    ),
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
