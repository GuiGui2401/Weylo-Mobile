import '../core/constants/api_constants.dart';
import '../models/gift.dart';
import 'api_client.dart';

class GiftService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Gift>> getAllGifts() async {
    final response = await _apiClient.get(ApiConstants.gifts);
    final data = response.data['gifts'] ?? response.data['data'] ?? [];
    return (data as List).map((g) => Gift.fromJson(g)).toList();
  }

  Future<List<GiftCategory>> getCategories() async {
    final response = await _apiClient.get(ApiConstants.giftCategories);
    final data = response.data['categories'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => GiftCategory.fromJson(c)).toList();
  }

  Future<List<Gift>> getGiftsByCategory(int categoryId) async {
    final response = await _apiClient.get(
      '${ApiConstants.giftCategories}/$categoryId/gifts',
    );
    final data = response.data['gifts'] ?? response.data['data'] ?? [];
    return (data as List).map((g) => Gift.fromJson(g)).toList();
  }

  Future<List<GiftTransaction>> getReceivedGifts({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.giftsReceived,
        queryParameters: {'page': page},
      );
      final data = response.data['gifts'] ?? response.data['data'] ?? [];
      return (data as List).map((g) => GiftTransaction.fromJson(g)).toList();
    } catch (e) {
      // Return empty list if endpoint fails (e.g., 404 due to route conflict)
      return [];
    }
  }

  Future<List<GiftTransaction>> getSentGifts({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.giftsSent,
        queryParameters: {'page': page},
      );
      final data = response.data['gifts'] ?? response.data['data'] ?? [];
      return (data as List).map((g) => GiftTransaction.fromJson(g)).toList();
    } catch (e) {
      // Return empty list if endpoint fails
      return [];
    }
  }

  Future<GiftTransaction> sendGift({
    required int giftId,
    required String recipientUsername,
    String? message,
    bool isAnonymous = false,
  }) async {
    final data = <String, dynamic>{
      'gift_id': giftId,
      'recipient_username': recipientUsername,
      'is_anonymous': isAnonymous,
    };
    if (message != null) {
      data['message'] = message;
    }

    final response = await _apiClient.post(
      ApiConstants.giftsSend,
      data: data,
    );
    return GiftTransaction.fromJson(response.data['transaction'] ?? response.data);
  }

  Future<GiftTransaction> sendGiftInConversation({
    required int conversationId,
    required int giftId,
    bool isAnonymous = false,
    String? message,
  }) async {
    final data = <String, dynamic>{
      'gift_id': giftId,
      'conversation_id': conversationId,
      'is_anonymous': isAnonymous,
    };
    if (message != null) {
      data['message'] = message;
    }

    final response = await _apiClient.post(
      ApiConstants.chatGift(conversationId),
      data: data,
    );
    return GiftTransaction.fromJson(response.data['transaction'] ?? response.data);
  }

  Future<GiftStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.giftsStats);
    return GiftStats.fromJson(response.data);
  }
}
