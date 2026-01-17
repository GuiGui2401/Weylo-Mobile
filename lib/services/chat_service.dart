import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/conversation.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Conversation>> getConversations() async {
    final response = await _apiClient.get(ApiConstants.chatConversations);
    final data = response.data['conversations'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => Conversation.fromJson(c)).toList();
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

  Future<Conversation> revealIdentity(int conversationId) async {
    final response = await _apiClient.post(
      '${ApiConstants.chatConversations}/$conversationId/reveal',
    );
    return Conversation.fromJson(response.data['conversation'] ?? response.data);
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
