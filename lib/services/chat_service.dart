import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  /// Activez temporairement si vous voulez voir les payloads en console.
  /// Laissez à false en production.
  final bool debugLogs;

  ChatService({this.debugLogs = false});

  void _log(String message) {
    if (debugLogs) {
      debugPrint('[ChatService] $message');
    }
  }

  Future<List<Conversation>> getConversations() async {
    final response = await _apiClient.get(ApiConstants.chatConversations);

    // Log brut optionnel
    _log('getConversations RAW response: ${response.data}');

    final data = response.data['conversations'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => Conversation.fromJson(c)).toList();
  }

  /// Optionnel : construit un index par username pour gérer les doublons.
  /// Règle appliquée : si au moins une conversation avec ce user a isIdentityRevealed == true,
  /// alors revealed = true. Sinon false.
  Future<Map<String, ConversationIndex>> getConversationsIndexByUsername() async {
    final conversations = await getConversations();

    final Map<String, ConversationIndex> index = {};

    for (final conv in conversations) {
      final username = conv.otherParticipant?.username;
      if (username == null || username.isEmpty) continue;

      final existing = index[username];
      final isRevealed = conv.isIdentityRevealed == true;

      if (existing == null) {
        index[username] = ConversationIndex(
          username: username,
          hasConversation: true,
          isIdentityRevealed: isRevealed,
          sampleConversation: conv,
        );
      } else {
        // OR logique : si une seule est révélée, alors global = révélé
        index[username] = existing.copyWith(
          hasConversation: true,
          isIdentityRevealed: existing.isIdentityRevealed || isRevealed,
          // garder une conversation de référence (optionnel)
          sampleConversation: existing.sampleConversation ?? conv,
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
    final data = <String, dynamic>{
      'content': content,
    };
    if (replyToId != null) {
      data['reply_to_id'] = replyToId;
    }

    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/messages',
      data: data,
    );
    return ChatMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> markAsRead(int conversationId) async {
    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/read',
    );
    return response.data['success'] ?? true;
  }

  Future<Conversation> revealIdentity(
    int conversationId, {
    Conversation? currentConversation,
    int? currentUserId,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/reveal',
    );

    _log('revealIdentity RAW response: ${response.data}');

    Map<String, dynamic>? mapFrom(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final rawData = response.data;
    final responseData = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    // Cas 1: backend renvoie directement conversation
    final conversationPayload = mapFrom(responseData['conversation']);
    if (conversationPayload != null && conversationPayload.isNotEmpty) {
      return Conversation.fromJson(conversationPayload);
    }

    // Cas 2: backend renvoie data/conversation dans data
    final dataPayload = mapFrom(responseData['data']);
    final payload = dataPayload ?? responseData;

    // Certains backends renvoient 'sender' ou 'other_participant' mis à jour
    final otherParticipantPayload =
        mapFrom(payload['sender']) ?? mapFrom(payload['other_participant']);

    // Si on a l'autre participant + conversation courante, on force la mise à jour locale
    if (otherParticipantPayload != null && currentConversation != null) {
      final otherUser = User.fromJson(otherParticipantPayload);
      final isCurrentParticipantOne = currentUserId != null &&
          currentConversation.participantOneId == currentUserId;

      return currentConversation.copyWith(
        isIdentityRevealed: true,
        participantOne: isCurrentParticipantOne
            ? currentConversation.participantOne
            : otherUser,
        participantTwo: isCurrentParticipantOne
            ? otherUser
            : currentConversation.participantTwo,
        otherParticipant: otherUser,
      );
    }

    // Cas 3: backend renvoie un payload "conversation-like"
    if (payload.isNotEmpty) {
      return Conversation.fromJson(payload);
    }

    // Fallback: on garde la conversation courante mais revealed
    if (currentConversation != null) {
      return currentConversation.copyWith(isIdentityRevealed: true);
    }

    return Conversation.fromJson(responseData);
  }

  Future<ChatMessage> sendGift(
    int conversationId, {
    required int giftId,
    String? message,
  }) async {
    final data = <String, dynamic>{
      'gift_id': giftId,
    };
    if (message != null) {
      data['message'] = message;
    }

    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/gift',
      data: data,
    );
    return ChatMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> deleteConversation(int conversationId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.chatConversations}/$conversationId',
    );
    return response.data['success'] ?? true;
  }

  Future<ChatMessage> editMessage(
    int conversationId,
    int messageId, {
    required String content,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.chatConversations}/$conversationId/messages/$messageId',
      data: {'content': content},
    );
    return ChatMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> deleteMessage(int conversationId, int messageId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.chatConversations}/$conversationId/messages/$messageId',
    );
    return response.data['success'] ?? true;
  }

  Future<UserStatus> getUserStatus(String username) async {
    final response = await _apiClient.get('${ApiConstants.chatUserStatus}/$username');
    return UserStatus.fromJson(response.data);
  }

  Future<void> updatePresence({required bool isOnline}) async {
    await _apiClient.post(
      ApiConstants.chatPresence,
      data: {'is_online': isOnline},
    );
  }
}

/// Objet utilitaire côté UI : vous permet de décider masque/affichage.
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
  final int total;
  final bool hasMore;

  PaginatedChatMessages({
    required this.messages,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
  });

  factory PaginatedChatMessages.fromJson(Map<String, dynamic> json) {
    final data = json['messages'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedChatMessages(
      messages: (data as List).map((m) => ChatMessage.fromJson(m)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}

class UserStatus {
  final bool isOnline;
  final DateTime? lastSeenAt;

  UserStatus({
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }
}
