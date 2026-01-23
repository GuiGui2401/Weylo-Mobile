import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import '../../services/widgets/common/widgets.dart';
import '../../services/widgets/common/link_text.dart';
import '../../services/widgets/voice/voice_recorder_widget.dart';
import '../../services/voice_effects_service.dart';

enum MessageDeliveryStatus { sending, sent, read, failed }

class _ReplyPreviewData {
  final String title;
  final String content;

  const _ReplyPreviewData({required this.title, required this.content});
}

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String? initialReplyTitle;
  final String? initialReplyContent;
  final String? initialSentContent;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.initialReplyTitle,
    this.initialReplyContent,
    this.initialSentContent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocket = WebSocketService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  ChatMessage? _replyTo;
  _ReplyPreviewData? _pendingReplyPreview;
  final Map<int, MessageDeliveryStatus> _messageDeliveryStatus = {};
  String? _pendingMessageContent;
  final Map<int, _ReplyPreviewData> _localReplyPreview = {};
  bool _showVoiceRecorder = false;
  File? _selectedImage;
  File? _selectedVideo;
  File? _voiceFile;
  VoiceEffect? _selectedVoiceEffect;
  int? _playingMessageId;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReplyContent != null &&
        widget.initialReplyContent!.isNotEmpty &&
        widget.initialSentContent == null) {
      _pendingReplyPreview = _ReplyPreviewData(
        title: widget.initialReplyTitle ?? '',
        content: widget.initialReplyContent!,
      );
    }
    _loadData();
    _subscribeToChannel();
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
    _webSocket.unsubscribeFromConversation(widget.conversationId);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _subscribeToChannel() {
    _webSocket.subscribeToConversation(widget.conversationId);
    _webSocket.messages.listen((message) {
      debugPrint(
        '[ChatScreen] WebSocket event: ${message.event} / channel: ${message.channel} / data: ${message.data}',
      );
      if (message.isChatMessage &&
          message.channel?.contains('${widget.conversationId}') == true) {
        final chatMessage = ChatMessage.fromJson(message.data);
        debugPrint(
          '[ChatScreen] Incoming chat message -> id: ${chatMessage.id}, sender: ${chatMessage.senderId}, content: "${chatMessage.content}"',
        );
        _messageDeliveryStatus[chatMessage.id] = chatMessage.isRead
            ? MessageDeliveryStatus.read
            : MessageDeliveryStatus.sent;
        if (!mounted) return;
        setState(() {
          _messages.insert(0, chatMessage);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _chatService.getConversation(widget.conversationId),
        _chatService.getMessages(widget.conversationId),
      ]);

      setState(() {
        _conversation = results[0] as Conversation;
        _messages = (results[1] as PaginatedChatMessages).messages;
        _sortMessages();
        _isLoading = false;
      });

      final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
      for (final message in _messages) {
        if (message.senderId == currentUserId) {
          _messageDeliveryStatus[message.id] = message.isRead
              ? MessageDeliveryStatus.read
              : MessageDeliveryStatus.sent;
        }
      }

      if (widget.initialReplyContent != null &&
          widget.initialSentContent != null &&
          widget.initialReplyContent!.isNotEmpty &&
          widget.initialSentContent!.isNotEmpty) {
        final l10n = AppLocalizations.of(context)!;
        final match = _messages.firstWhere(
          (message) =>
              message.senderId == currentUserId &&
              message.content == widget.initialSentContent,
          orElse: () => ChatMessage(
            id: -1,
            conversationId: widget.conversationId,
            senderId: currentUserId,
            content: '',
            createdAt: DateTime.now(),
          ),
        );
        if (match.id != -1) {
          setState(() {
            _localReplyPreview[match.id] = _ReplyPreviewData(
              title: widget.initialReplyTitle ?? l10n.anonymousMessage,
              content: widget.initialReplyContent!,
            );
          });
        }
      }

      _chatService.markAsRead(widget.conversationId);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  bool _shouldShowDateSeparator(int index) {
    if (index < 0 || index >= _messages.length) return false;
    final current = _messages[index];
    final next = index + 1 < _messages.length ? _messages[index + 1] : null;
    if (next == null) return true;
    return !_isSameDay(current.createdAt, next.createdAt);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
      debugPrint('[ChatScreen] Play voice -> id=$messageId url=$mediaUrl');
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.audioPlaybackError(e.toString()))),
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
    debugPrint('[ChatScreen] Open video -> url=$mediaUrl');
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(mediaUrl),
      httpHeaders: const {'Accept': '*/*', 'Range': 'bytes=0-'},
    );
    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.videoPlaybackError(e.toString()))),
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

  void _showEmojiPicker() {
    final emojis = [
      '😀',
      '😁',
      '😂',
      '🤣',
      '😅',
      '😊',
      '😍',
      '😘',
      '😎',
      '😢',
      '😭',
      '😡',
      '😮',
      '👍',
      '👎',
      '🙏',
      '🔥',
      '❤️',
      '🎉',
      '😴',
    ];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            final emoji = emojis[index];
            return InkWell(
              onTap: () {
                final text = _messageController.text;
                final selection = _messageController.selection;
                final insertAt = selection.isValid
                    ? selection.start
                    : text.length;
                final newText = text.replaceRange(insertAt, insertAt, emoji);
                _messageController.text = newText;
                _messageController.selection = TextSelection.collapsed(
                  offset: insertAt + emoji.length,
                );
                Navigator.pop(sheetContext);
              },
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(AppLocalizations.of(sheetContext)!.attachmentImage),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(AppLocalizations.of(sheetContext)!.attachmentVideo),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasMedia =
        _selectedImage != null || _selectedVideo != null || _voiceFile != null;
    if ((content.isEmpty && !hasMedia) || _isSending) return;

    debugPrint(
      '[ChatScreen] Sending message -> content: "$content", replyTo: ${_replyTo?.id}',
    );
    _pendingMessageContent = content;
    setState(() {
      _isSending = true;
    });

    try {
      final replyToId = _replyTo?.id;
      final pendingReply = _replyTo == null ? _pendingReplyPreview : null;
      final message = await _chatService.sendMessage(
        widget.conversationId,
        content: content.isEmpty ? null : content,
        replyToId: replyToId,
        image: _selectedImage,
        video: _selectedVideo,
        voice: _voiceFile,
        voiceEffect: _selectedVoiceEffect != null
            ? VoiceEffectsService.effectToString(_selectedVoiceEffect!)
            : null,
      );

      debugPrint(
        '[ChatScreen] Message sent -> id: ${message.id}, data: ${message.content}',
      );
      _messageDeliveryStatus[message.id] = MessageDeliveryStatus.sent;

      setState(() {
        _messages.insert(0, message);
        _replyTo = null;
        _pendingReplyPreview = null;
        _selectedImage = null;
        _selectedVideo = null;
        _voiceFile = null;
        _selectedVoiceEffect = null;
        _showVoiceRecorder = false;
      });

      _messageController.clear();
      _pendingMessageContent = null;
      if (pendingReply != null) {
        _localReplyPreview[message.id] = pendingReply;
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('[ChatScreen] Message send failed -> error: $e');
      Helpers.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.chatSendError,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final otherUser = _conversation?.getOtherParticipant(currentUserId);
    final statusText = _buildOnlineStatusText(context, otherUser);
    final flameCount = _conversation?.streakCount ?? 0;
    final flameColor = Helpers.getFlameColor(
      _conversation?.flameLevel.name ?? 'none',
    );
    final effectiveFlameColor = flameColor == Colors.transparent
        ? AppColors.flameOrange
        : flameColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.pushReplacement('/');
            }
          },
        ),
        title: _isLoading
            ? null
            : Row(
                children: [
                  AvatarWidget(
                    imageUrl:
                        otherUser?.avatar ??
                        'https://i.pravatar.cc/150?img=${(_conversation?.id ?? 1) % 70 + 1}',
                    name: otherUser?.fullName,
                    size: 36,
                    showOnlineIndicator: otherUser?.isOnline == true,
                    isOnline: otherUser?.isOnline == true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _conversation?.getDisplayName(currentUserId) ??
                                    l10n.userFallback,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (flameCount > 0) ...[
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                              Text(
                                '$flameCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: effectiveFlameColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (statusText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (!(_conversation?.isIdentityRevealed ?? true))
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _showRevealDialog(),
              tooltip: l10n.revealIdentityTitle,
            ),
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () =>
                context.push('/send-gift/${widget.conversationId}'),
            tooltip: l10n.sendGift,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fond.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(child: Text(l10n.chatEmpty))
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe =
                                  message.senderId == currentUserId ||
                                  (message.sender?.id == currentUserId &&
                                      currentUserId != 0);
                              final mediaUrl = _resolveMediaUrl(
                                message.mediaUrl,
                              );
                              final localReply = _localReplyPreview[message.id];
                              final showDateSeparator =
                                  _shouldShowDateSeparator(index);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDateSeparator)
                                    _MessageDateSeparator(
                                      date: message.createdAt,
                                    ),
                                  Dismissible(
                                    key: ValueKey(
                                      'chat_message_${message.id}_${message.createdAt.millisecondsSinceEpoch}',
                                    ),
                                    direction: DismissDirection.startToEnd,
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 16),
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      child: const Icon(
                                        Icons.reply,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    confirmDismiss: (_) async {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _replyTo = message;
                                        _pendingReplyPreview = null;
                                      });
                                      return false;
                                    },
                                    child: _MessageBubble(
                                      message: message,
                                      isMe: isMe,
                                      statusLabel: _getMessageStatusLabel(
                                        message,
                                        isMe,
                                      ),
                                      mediaUrl: mediaUrl,
                                      localReply: localReply,
                                      isAudioLoading: _isAudioLoading,
                                      playingMessageId: _playingMessageId,
                                      onPlayVoice: () => _toggleVoicePlayback(
                                        message.id,
                                        mediaUrl,
                                        message.voiceEffect,
                                      ),
                                      onOpenVideo: () =>
                                          _openVideoPlayer(mediaUrl),
                                      onReply: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _replyTo = message;
                                          _pendingReplyPreview = null;
                                        });
                                      },
                                      onDelete: isMe
                                      ? () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) => AlertDialog(
                                              title: Text(
                                                AppLocalizations.of(dialogContext)!.deleteMessageTitle,
                                              ),
                                              content: Text(
                                                AppLocalizations.of(dialogContext)!.deleteMessageConfirm,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, false),
                                                  child: Text(AppLocalizations.of(dialogContext)!.cancel),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: Text(AppLocalizations.of(dialogContext)!.deleteAction),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;
                                          try {
                                            await _chatService.deleteMessage(
                                              widget.conversationId,
                                              message.id,
                                            );
                                            setState(() {
                                              _messages.removeWhere((item) => item.id == message.id);
                                            });
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.messageDeleted,
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
                                      : null,
                                ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
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
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
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
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVideo = null;
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
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_voiceFile != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.voiceMessageRecorded,
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                    ),
                  if (_showVoiceRecorder)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: VoiceRecorderWidget(
                          onRecordingComplete: _onVoiceRecorded,
                          showEffectSelector: true,
                        ),
                      ),
                    ),
                  if (_replyTo != null || _pendingReplyPreview != null)
                    _buildReplyPreview(),
                  _buildInputArea(),
                ],
              ),
            ),
    );
  }

  String? _buildOnlineStatusText(BuildContext context, User? user) {
    if (user == null) return null;
    if (user.isOnline) {
      return Localizations.localeOf(context).languageCode == 'fr'
          ? 'En ligne'
          : 'Online';
    }
    final lastSeen = user.lastSeenAt;
    if (lastSeen == null) return null;

    final now = DateTime.now();
    final isToday =
        now.year == lastSeen.year &&
        now.month == lastSeen.month &&
        now.day == lastSeen.day;
    final timeText = Helpers.formatTime(lastSeen);

    if (Localizations.localeOf(context).languageCode == 'fr') {
      if (isToday) {
        return "En ligne aujourd'hui a $timeText";
      }
      final dateText = Helpers.formatDate(lastSeen);
      return 'En ligne le $dateText a $timeText';
    }

    if (isToday) {
      return 'Online today at $timeText';
    }
    final dateText = Helpers.formatDate(lastSeen);
    return 'Online on $dateText at $timeText';
  }

  Widget _buildReplyPreview() {
    final l10n = AppLocalizations.of(context)!;
    final preview = _pendingReplyPreview;
    final isChatReply = _replyTo != null;
    final title = isChatReply
        ? l10n.replyTo
        : (preview?.title.isNotEmpty == true
              ? preview!.title
              : l10n.anonymousMessage);
    final content = isChatReply ? _replyTo!.content : (preview?.content ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: AppColors.divider)),
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
                  title,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyTo = null;
                _pendingReplyPreview = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: _showEmojiPicker,
              ),
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: (_selectedImage != null || _selectedVideo != null)
                      ? AppColors.primary
                      : Colors.grey,
                ),
                onPressed: _showAttachmentSheet,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.messageHintShort,
                    prefixIcon: IconButton(
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: _onMessageChanged,
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessageStatusLabel(ChatMessage message, bool isMe) {
    final l10n = AppLocalizations.of(context)!;
    if (!isMe) return '';
    if (_isSending &&
        _pendingMessageContent != null &&
        message.content == _pendingMessageContent) {
      return l10n.statusSending;
    }

    final status = _messageDeliveryStatus[message.id];
    if (status != null) {
      return _statusText(status);
    }
    return message.isRead ? l10n.statusRead : l10n.statusUnread;
  }

  String _statusText(MessageDeliveryStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case MessageDeliveryStatus.sending:
        return l10n.statusSending;
      case MessageDeliveryStatus.sent:
        return l10n.statusSent;
      case MessageDeliveryStatus.read:
        return l10n.statusRead;
      case MessageDeliveryStatus.failed:
        return l10n.statusFailed;
    }
  }

  void _showRevealDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.revealIdentityTitle),
        content: Text(l10n.revealIdentityPrompt('450')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
              try {
                final updated = await _chatService.revealIdentity(
                  widget.conversationId,
                  currentConversation: _conversation,
                  currentUserId: currentUserId,
                );
                Conversation resolvedConversation = updated;
                if (resolvedConversation.getOtherParticipant(currentUserId) ==
                    null) {
                  resolvedConversation = await _chatService.getConversation(
                    widget.conversationId,
                  );
                }

                if (mounted) {
                  setState(() {
                    _conversation = resolvedConversation;
                  });
                  await context.read<AuthProvider>().refreshUser();
                  Helpers.showSuccessSnackBar(
                    context,
                    l10n.revealIdentitySuccess,
                  );
                }
              } catch (e) {
                if (mounted) {
                  final message = Helpers.parseErrorMessage(e);
                  if (e is AppException && e.statusCode == 402) {
                    final requiredAmount = Helpers.extractRequiredAmount(e.data);
                    Helpers.showErrorSnackBar(
                      context,
                      Helpers.insufficientBalanceMessage(
                        requiredAmount: requiredAmount,
                      ),
                    );
                    context.push('/wallet');
                  } else {
                    Helpers.showErrorSnackBar(context, message);
                  }
                }
              }
            },
            child: Text(l10n.revealIdentityAction),
          ),
        ],
      ),
    );
  }

  void _onMessageChanged(String value) {
    debugPrint('[ChatScreen] Input changed -> "$value"');
  }

  void _showOptions() {
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final otherUser = _conversation?.getOtherParticipant(currentUserId);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: Text(AppLocalizations.of(sheetContext)!.sendGift),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/send-gift/${widget.conversationId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(AppLocalizations.of(sheetContext)!.blockUser),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBlockDialog(otherUser?.username ?? '');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                AppLocalizations.of(sheetContext)!.deleteConversation,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConversationDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(String username) {
    if (username.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.blockUserTitle),
        content: Text(AppLocalizations.of(dialogContext)!.blockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // TODO: Implémenter le blocage via UserService
              if (mounted) {
                Helpers.showSuccessSnackBar(
                  context,
                  AppLocalizations.of(context)!.userBlocked,
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.pushReplacement('/');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(dialogContext)!.blockUser),
          ),
        ],
      ),
    );
  }

  void _showDeleteConversationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.deleteConversation),
        content: Text(
          AppLocalizations.of(dialogContext)!.deleteConversationConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _chatService.deleteConversation(widget.conversationId);
                if (mounted) {
                  Helpers.showSuccessSnackBar(
                    context,
                    AppLocalizations.of(context)!.conversationDeleted,
                  );
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.pushReplacement('/');
                  }
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showErrorSnackBar(
                    context,
                    AppLocalizations.of(context)!.conversationDeleteError,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(dialogContext)!.deleteAction),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  static final Map<String, Future<Uint8List?>> _videoThumbCache = {};
  
  final ChatMessage message;
  final bool isMe;
  final String statusLabel;
  final String? mediaUrl;
  final _ReplyPreviewData? localReply;
  final bool isAudioLoading;
  final int? playingMessageId;
  final VoidCallback? onReply;
  final VoidCallback? onPlayVoice;
  final VoidCallback? onOpenVideo;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.statusLabel,
    required this.mediaUrl,
    required this.localReply,
    required this.isAudioLoading,
    required this.playingMessageId,
    this.onReply,
    this.onPlayVoice,
    this.onOpenVideo,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDecoratedMedia = message.isGift || message.hasVoice;
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: isDecoratedMedia
                ? Colors.transparent
                : (isMe ? AppColors.primary : AppColors.messageReceived),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: isDecoratedMedia
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.replyTo != null || localReply != null)
                  _buildReplyPreview(context),

              if (message.isGift)
                _buildGiftPreview(context),
                if (message.hasImage && (mediaUrl ?? '').isNotEmpty)
                  _buildImagePreview(),
                
                if (message.hasVideo && (mediaUrl ?? '').isNotEmpty)
                  _buildVideoPreview(context, mediaUrl!),

                if (message.hasVoice && (mediaUrl ?? '').isNotEmpty)
                  _buildAudioPlayer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      LinkText(
                        text: message.content, 
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        linkStyle: TextStyle(
                          color: isMe ? Colors.white : AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Helpers.formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe 
                                  ? Colors.white.withOpacity(0.7) 
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: isMe ? Colors.white70 : AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localReply?.title ?? (isMe ? l10n.youLabel : l10n.contactLabel),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isMe ? Colors.white : AppColors.primary),
          ),
          Text(
            message.replyTo?.content ?? localReply?.content ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: isMe ? Colors.white.withOpacity(0.9) : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: mediaUrl!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context, String url) {
    final future = _videoThumbCache.putIfAbsent(url, () => 
      VideoThumbnail.thumbnailData(video: url, imageFormat: ImageFormat.JPEG, quality: 70)
    );
    return GestureDetector(
      onTap: onOpenVideo,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List?>(
              future: future,
              builder: (context, snap) => snap.hasData 
                ? Image.memory(snap.data!, height: 200, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 200, color: Colors.black12),
            ),
            const Icon(Icons.play_circle_filled, size: 50, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final isPlaying = playingMessageId == message.id;
    final barColor = isMe ? Colors.white : AppColors.primary;
    final bgColor = isMe ? Colors.white.withOpacity(0.12) : Colors.white;
    final borderColor = barColor.withOpacity(isMe ? 0.35 : 0.22);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onPlayVoice,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (isAudioLoading && isPlaying)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: barColor,
                  ),
                )
              else
                Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: barColor,
                  size: 24,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel.isNotEmpty
                    ? statusLabel
                    : Helpers.formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: barColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftPreview(BuildContext context) {
    final gift = message.gift;
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final rawIcon = gift?.icon ?? '';
    final isEmojiIcon = _isEmojiIcon(rawIcon);
    final shouldAnimateEmoji =
        isEmojiIcon &&
        DateTime.now().difference(message.createdAt).inSeconds <= 8;

    String resolveGiftUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      final cleaned = url.replaceAll('\\', '/');
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
      if (cleaned.startsWith('/storage/')) return Uri.encodeFull('$base$cleaned');
      if (cleaned.startsWith('storage/')) return Uri.encodeFull('$base/$cleaned');
      return Uri.encodeFull('$base/storage/$cleaned');
    }

    final animationUrl = resolveGiftUrl(gift?.animation);
    final iconUrl = isEmojiIcon ? '' : resolveGiftUrl(gift?.icon);

    Widget media;
    if (animationUrl.isNotEmpty) {
      final lower = animationUrl.toLowerCase();
      if (lower.endsWith('.json')) {
        media = Lottie.network(
          animationUrl,
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.card_giftcard,
            size: 48,
          ),
        );
      } else {
        media = CachedNetworkImage(
          imageUrl: animationUrl,
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.card_giftcard, size: 48),
        );
      }
    } else if (iconUrl.isNotEmpty) {
      media = CachedNetworkImage(
        imageUrl: iconUrl,
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => const Icon(Icons.card_giftcard, size: 48),
      );
    } else if (isEmojiIcon) {
      media = _buildGiftEmoji(rawIcon, animate: shouldAnimateEmoji);
    } else {
      media = const Icon(Icons.card_giftcard, size: 48);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          media,
          const SizedBox(width: 12),
          if (gift != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${gift.price.toInt()} FCFA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
        ],
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

  Widget _buildGiftEmoji(String emoji, {required bool animate}) {
    final text = Text(
      emoji,
      style: const TextStyle(fontSize: 56),
    );
    if (!animate) return text;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: text,
    );
  }

  Widget _buildStatusIcon() {
    return Icon(
      message.isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: message.isRead ? Colors.blueAccent : Colors.white.withOpacity(0.7),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(l10n.replyAction),
                onTap: () { Navigator.pop(ctx); onReply?.call(); },
              ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    l10n.deleteAction,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.copyAction),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageDateSeparator extends StatelessWidget {
  const _MessageDateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = _formatDateLabel(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) return l10n.todayLabel;
    if (diff == 1) return l10n.yesterdayLabel;

    if (diff > 1 && diff < 7) {
      return DateFormat('EEEE', Intl.getCurrentLocale()).format(date);
    }

    return DateFormat('dd/MM/yyyy', Intl.getCurrentLocale()).format(date);
  }
}
