import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/common/widgets.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocket = WebSocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  ChatMessage? _replyTo;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToChannel();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _webSocket.unsubscribeFromConversation(widget.conversationId);
    super.dispose();
  }

  void _subscribeToChannel() {
    _webSocket.subscribeToConversation(widget.conversationId);
    _webSocket.messages.listen((message) {
      if (message.isChatMessage && message.channel?.contains('${widget.conversationId}') == true) {
        final chatMessage = ChatMessage.fromJson(message.data);
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
        _isLoading = false;
      });

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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _chatService.sendMessage(
        widget.conversationId,
        content: content,
        replyToId: _replyTo?.id,
      );

      setState(() {
        _messages.insert(0, message);
        _replyTo = null;
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      Helpers.showErrorSnackBar(context, 'Erreur lors de l\'envoi du message');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final otherUser = _conversation?.getOtherParticipant(currentUserId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: _isLoading
            ? null
            : Row(
                children: [
                  AvatarWidget(
                    imageUrl: otherUser?.avatar,
                    name: otherUser?.fullName,
                    size: 36,
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
                                _conversation?.isIdentityRevealed == true
                                    ? otherUser?.fullName ?? 'Utilisateur'
                                    : 'Anonyme',
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_conversation?.getFlameEmoji().isNotEmpty == true) ...[
                              const SizedBox(width: 4),
                              Text(
                                _conversation!.getFlameEmoji(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        if (_conversation?.streakCount != null && _conversation!.streakCount > 0)
                          Text(
                            '${_conversation!.streakCount} jours de streak',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
              tooltip: 'Révéler l\'identité',
            ),
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () => context.push('/send-gift/${widget.conversationId}'),
            tooltip: 'Envoyer un cadeau',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text('Aucun message. Commencez la conversation !'),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == currentUserId;
                            return _MessageBubble(
                              message: message,
                              isMe: isMe,
                              onReply: () {
                                setState(() {
                                  _replyTo = message;
                                });
                              },
                            );
                          },
                        ),
                ),
                if (_replyTo != null) _buildReplyPreview(),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: AppColors.divider),
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
                  'Répondre à',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyTo!.content,
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
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
            onPressed: () {
              // Show emoji picker
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showRevealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révéler l\'identité'),
        content: const Text(
          'Voulez-vous payer pour révéler l\'identité de cette personne ? '
          'Cette action coûte 450 FCFA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updated = await _chatService.revealIdentity(widget.conversationId);
                setState(() {
                  _conversation = updated;
                });
                Helpers.showSuccessSnackBar(context, 'Identité révélée !');
              } catch (e) {
                Helpers.showErrorSnackBar(context, 'Erreur lors de la révélation');
              }
            },
            child: const Text('Révéler'),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Envoyer un cadeau'),
              onTap: () {
                Navigator.pop(context);
                context.push('/send-gift/${widget.conversationId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquer'),
              onTap: () {
                Navigator.pop(context);
                // Handle block
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer la conversation', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.deleteConversation(widget.conversationId);
                if (mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.replyTo!.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.primaryGradient : null,
                  color: isMe ? null : AppColors.messageReceived,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Helpers.formatTime(message.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    if (isMe && message.isRead) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
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
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard
              },
            ),
          ],
        ),
      ),
    );
  }
}
