import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/conversation.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();
  final bool debugLogs;

  ChatService({this.debugLogs = false});

  void _log(String message) {
    if (debugLogs) {
      debugPrint('[ChatService] $message');
    }
  }

  /// Récupère toutes les conversations brutes
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiClient.get(ApiConstants.chatConversations);
      _log('getConversations RAW response: ${response.data}');

      final data = response.data['conversations'] ?? response.data['data'] ?? [];
      return (data as List).map((c) => Conversation.fromJson(c)).toList();
    } catch (e) {
      _log('Error fetching conversations: $e');
      return [];
    }
  }

  /// CRITIQUE : Construit un index par nom d'utilisateur.
  /// Règle : Si AU MOINS une conversation avec cet utilisateur a [is_identity_revealed] à true,
  /// alors l'utilisateur est considéré comme dévoilé dans l'interface.
  Future<Map<String, ConversationIndex>> getConversationsIndexByUsername({
    List<Conversation>? conversations,
  }) async {
    final source = conversations ?? await getConversations();
    final Map<String, ConversationIndex> index = {};

    for (final conv in source) {
      final username = conv.otherParticipant?.username;
      if (username == null || username.isEmpty) continue;

      final existing = index[username];
      final bool isRevealed = conv.isIdentityRevealed == true;

      if (existing == null) {
        index[username] = ConversationIndex(
          username: username,
          hasConversation: true,
          isIdentityRevealed: isRevealed,
          sampleConversation: conv,
        );
      } else {
        index[username] = existing.copyWith(
          isIdentityRevealed: existing.isIdentityRevealed || isRevealed,
          sampleConversation: isRevealed ? conv : existing.sampleConversation,
        );
      }
    }
    return index;
  }

  Future<Conversation> getConversation(int id) async {
    final response = await _apiClient.get('${ApiConstants.chatConversations}/$id');
    return Conversation.fromJson(response.data['conversation'] ?? response.data);
  }

  Future<Conversation> startConversation(String username) async {
    final response = await _apiClient.post(
      ApiConstants.chatConversations,
      data: {'username': username},
    );
    return Conversation.fromJson(response.data['conversation'] ?? response.data);
  }

  Future<PaginatedChatMessages> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = AppConstants.messagesPageSize,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.chatConversations}/$conversationId/messages',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedChatMessages.fromJson(response.data);
  }

  Future<ChatMessage> sendMessage(
    int conversationId, {
    required String content,
    int? replyToId,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (replyToId != null) data['reply_to_id'] = replyToId;

    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/messages',
      data: data,
    );
    return ChatMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> markAsRead(int conversationId) async {
    final response = await _apiClient.post('${ApiConstants.chatConversations}/$conversationId/read');
    return response.data['success'] ?? true;
  }

  Future<Conversation> revealIdentity(
    int conversationId, {
    Conversation? currentConversation,
    int? currentUserId,
  }) async {
    final response = await _apiClient.post('${ApiConstants.chatConversations}/$conversationId/reveal');
    
    final responseData = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
    final convData = responseData['conversation'] ?? responseData['data'] ?? responseData;

    // Si on a l'objet complet, on le retourne
    if (convData is Map && convData.isNotEmpty) {
      return Conversation.fromJson(Map<String, dynamic>.from(convData));
    }

    // Fallback : On met à jour l'instance locale si fournie
    if (currentConversation != null) {
      return currentConversation.copyWith(isIdentityRevealed: true);
    }
    
    return Conversation.fromJson(responseData);
  }

  Future<bool> deleteConversation(int conversationId) async {
    final response = await _apiClient.delete('${ApiConstants.chatConversations}/$conversationId');
    return response.data['success'] ?? true;
  }

  Future<UserStatus> getUserStatus(String username) async {
    final response = await _apiClient.get('${ApiConstants.chatUserStatus}/$username');
    return UserStatus.fromJson(response.data);
  }

  Future<void> updatePresence({required bool isOnline}) async {
    await _apiClient.post(ApiConstants.chatPresence, data: {'is_online': isOnline});
  }
}

/// --- CLASSES UTILITAIRES ---

class ConversationIndex {
  final String username;
  final bool hasConversation;
  final bool isIdentityRevealed;
  final Conversation? sampleConversation;

  const ConversationIndex({
    required this.username,
    required this.hasConversation,
    required this.isIdentityRevealed,
    this.sampleConversation,
  });

  ConversationIndex copyWith({
    bool? hasConversation,
    bool? isIdentityRevealed,
    Conversation? sampleConversation,
  }) {
    return ConversationIndex(
      username: username,
      hasConversation: hasConversation ?? this.hasConversation,
      isIdentityRevealed: isIdentityRevealed ?? this.isIdentityRevealed,
      sampleConversation: sampleConversation ?? this.sampleConversation,
    );
  }
}

class PaginatedChatMessages {
  final List<ChatMessage> messages;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  PaginatedChatMessages({
    required this.messages,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
  });

  factory PaginatedChatMessages.fromJson(Map<String, dynamic> json) {
    final data = json['messages'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedChatMessages(
      messages: (data as List).map((m) => ChatMessage.fromJson(m)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}

class UserStatus {
  final bool isOnline;
  final DateTime? lastSeenAt;

  UserStatus({this.isOnline = false, this.lastSeenAt});

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      isOnline: json['is_online'] ?? false,
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at']) : null,
    );
  }
}
