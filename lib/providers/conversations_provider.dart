import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';

class ConversationsProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocket = WebSocketService();
  StreamSubscription<WebSocketMessage>? _messageSubscription;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentUserId = 0;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  void init(int currentUserId) {
    _currentUserId = currentUserId;
    _subscribeToWebSocket();
    loadConversations();
  }

  void _subscribeToWebSocket() {
    _messageSubscription?.cancel();
    _webSocket.connect();
    _messageSubscription = _webSocket.messages.listen(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    if (!message.isChatMessage && !message.isNewMessage) return;
    final chatMessage = ChatMessage.fromJson(message.data);
    _applyIncomingMessage(chatMessage);
  }

  Future<void> _applyIncomingMessage(ChatMessage chatMessage) async {
    final conversationId = chatMessage.conversationId;
    if (conversationId == 0) return;

    final existingIndex = _conversations.indexWhere(
      (conv) => conv.id == conversationId,
    );

    if (existingIndex == -1) {
      try {
        final conversation =
            await _chatService.getConversation(conversationId);
        _conversations.insert(0, conversation);
        _sortConversations();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print(
            '[ConversationsProvider] Failed to fetch conversation $conversationId: $e',
          );
        }
      }
      return;
    }

    final existing = _conversations[existingIndex];
    final updated = existing.copyWith(
      lastMessage: chatMessage,
      lastMessageAt: chatMessage.createdAt,
      messageCount: existing.messageCount + 1,
      unreadCount: chatMessage.senderId != _currentUserId
          ? existing.unreadCount + 1
          : existing.unreadCount,
    );
    _conversations.removeAt(existingIndex);
    _conversations.insert(0, updated);
    _sortConversations();
    notifyListeners();
  }

  Future<void> loadConversations() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
      _sortConversations();
    } catch (e) {
      _hasError = true;
      if (kDebugMode) print('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      if (a.streakCount != b.streakCount) {
        return b.streakCount.compareTo(a.streakCount);
      }
      final aTime = a.lastMessageAt ?? a.updatedAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.updatedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> refresh() async {
    await loadConversations();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    super.dispose();
  }
}
