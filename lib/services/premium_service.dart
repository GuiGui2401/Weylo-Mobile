import '../core/constants/api_constants.dart';
import '../models/premium.dart';
import 'api_client.dart';

class PremiumService {
  final ApiClient _apiClient = ApiClient();

  // Premium Subscriptions (targeted)
  Future<List<PremiumSubscription>> getSubscriptions() async {
    final response = await _apiClient.get(ApiConstants.premiumSubscriptions);
    final data = response.data['subscriptions'] ?? response.data['data'] ?? [];
    return (data as List).map((s) => PremiumSubscription.fromJson(s)).toList();
  }

  Future<List<PremiumSubscription>> getActiveSubscriptions() async {
    final response = await _apiClient.get(
      ApiConstants.premiumSubscriptionsActive,
    );
    final data = response.data['subscriptions'] ?? response.data['data'] ?? [];
    return (data as List).map((s) => PremiumSubscription.fromJson(s)).toList();
  }

  Future<PremiumSubscription> subscribeToMessage(int messageId) async {
    final response = await _apiClient.post(
      '${ApiConstants.premium}/subscribe/message/$messageId',
    );
    return PremiumSubscription.fromJson(
      response.data['subscription'] ?? response.data,
    );
  }

  Future<PremiumSubscription> subscribeToConversation(
    int conversationId,
  ) async {
    final response = await _apiClient.post(
      '${ApiConstants.premium}/subscribe/conversation/$conversationId',
    );
    return PremiumSubscription.fromJson(
      response.data['subscription'] ?? response.data,
    );
  }

  Future<PremiumSubscription> subscribeToStory(int storyId) async {
    final response = await _apiClient.post(
      '${ApiConstants.premium}/subscribe/story/$storyId',
    );
    return PremiumSubscription.fromJson(
      response.data['subscription'] ?? response.data,
    );
  }

  Future<bool> cancelSubscription(int subscriptionId) async {
    final response = await _apiClient.post(
      '${ApiConstants.premium}/cancel/$subscriptionId',
    );
    return response.data['success'] ?? true;
  }

  Future<PremiumPricing> getPricing() async {
    final response = await _apiClient.get(ApiConstants.premiumPricing);
    return PremiumPricing.fromJson(response.data);
  }

  Future<bool> checkPremiumAccess(int targetUserId) async {
    final response = await _apiClient.get(ApiConstants.premiumCheck);
    return response.data['has_access'] ?? false;
  }

  // Premium Pass (global)
  Future<PremiumPassStatusResponse> getPassStatus() async {
    final response = await _apiClient.get(ApiConstants.premiumPassStatus);
    return PremiumPassStatusResponse.fromJson(response.data);
  }

  Future<PremiumPass> purchasePass({String? plan}) async {
    final data = <String, dynamic>{};
    if (plan != null && plan.isNotEmpty) {
      data['plan'] = plan;
    }
    final response = await _apiClient.post(
      ApiConstants.premiumPassPurchase,
      data: data.isEmpty ? null : data,
    );
    return PremiumPass.fromJson(response.data['pass'] ?? response.data);
  }

  Future<PremiumPass> renewPass() async {
    final response = await _apiClient.post(ApiConstants.premiumPassRenew);
    return PremiumPass.fromJson(response.data['pass'] ?? response.data);
  }

  Future<bool> enableAutoRenew() async {
    final response = await _apiClient.post(
      '${ApiConstants.premiumPass}/auto-renew/enable',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> disableAutoRenew() async {
    final response = await _apiClient.post(
      '${ApiConstants.premiumPass}/auto-renew/disable',
    );
    return response.data['success'] ?? true;
  }

  Future<List<PremiumPass>> getPassHistory() async {
    final response = await _apiClient.get(ApiConstants.premiumPassHistory);
    final data = response.data['passes'] ?? response.data['data'] ?? [];
    return (data as List).map((p) => PremiumPass.fromJson(p)).toList();
  }

  Future<bool> canViewIdentity(int userId) async {
    final response = await _apiClient.get(
      '${ApiConstants.premiumPass}/can-view-identity/$userId',
    );
    return response.data['can_view'] ?? false;
  }
}

class PremiumPassStatusResponse {
  final bool isActive;
  final PremiumPass? currentPass;
  final int daysRemaining;
  final bool autoRenew;

  PremiumPassStatusResponse({
    this.isActive = false,
    this.currentPass,
    this.daysRemaining = 0,
    this.autoRenew = false,
  });

  factory PremiumPassStatusResponse.fromJson(Map<String, dynamic> json) {
    return PremiumPassStatusResponse(
      isActive: json['is_active'] ?? json['isActive'] ?? false,
      currentPass: json['current_pass'] != null
          ? PremiumPass.fromJson(json['current_pass'])
          : null,
      daysRemaining: json['days_remaining'] ?? json['daysRemaining'] ?? 0,
      autoRenew: json['auto_renew'] ?? json['autoRenew'] ?? false,
    );
  }
}
