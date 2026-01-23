import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<User> getProfile() async {
    final response = await _apiClient.get(ApiConstants.me);
    final user = User.fromJson(response.data['user'] ?? response.data);
    await _storage.saveUser(user);
    return user;
  }

  Future<User> getUserByUsername(String username) async {
    final response = await _apiClient.get(
      '${ApiConstants.userByUsername}/$username',
    );
    return User.fromJson(response.data['user'] ?? response.data);
  }

  Future<User> getUserById(int id) async {
    final response = await _apiClient.get('${ApiConstants.userById}/$id');
    return User.fromJson(response.data['user'] ?? response.data);
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (bio != null) data['bio'] = bio;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;

    final response = await _apiClient.put(ApiConstants.userProfile, data: data);

    final user = User.fromJson(response.data['user'] ?? response.data);
    await _storage.saveUser(user);
    return user;
  }

  Future<User> updateSettings(UserSettings settings) async {
    final response = await _apiClient.put(
      ApiConstants.userSettings,
      data: settings.toJson(),
    );

    final data = response.data;
    final payload = data is Map<String, dynamic>
        ? (data['user'] ?? data['data'] ?? data['settings'])
        : data;

    if (payload is Map<String, dynamic> && payload.containsKey('id')) {
      final user = User.fromJson(payload);
      await _storage.saveUser(user);
      return user;
    }

    final currentUser = await _storage.getUser();
    if (payload is Map<String, dynamic> && currentUser != null) {
      final updatedSettings = UserSettings.fromJson(payload);
      final user = currentUser.copyWith(settings: updatedSettings);
      await _storage.saveUser(user);
      return user;
    }

    if (currentUser != null) {
      final user = currentUser.copyWith(settings: settings);
      await _storage.saveUser(user);
      return user;
    }

    final fallback = User.fromJson(payload is Map<String, dynamic> ? payload : {});
    await _storage.saveUser(fallback);
    return fallback;
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.userPassword,
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response.data['success'] ?? true;
  }

  Future<User> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.uploadFile(
      ApiConstants.userAvatar,
      data: formData,
    );
    final avatarUrl =
        response.data['avatar_url'] ?? response.data['avatar'] ?? null;
    final currentUser = await _storage.getUser();
    if (currentUser != null && avatarUrl is String) {
      final updatedUser = currentUser.copyWith(avatar: avatarUrl);
      await _storage.saveUser(updatedUser);
      return updatedUser;
    }

    final user = User.fromJson(response.data['user'] ?? response.data);
    await _storage.saveUser(user);
    return user;
  }

  Future<User> uploadCover(String filePath) async {
    final formData = FormData.fromMap({
      'cover_image': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.uploadFile(
      ApiConstants.userCover,
      data: formData,
    );
    final coverUrl =
        response.data['cover_url'] ?? response.data['cover'] ?? null;
    final currentUser = await _storage.getUser();
    if (currentUser != null && coverUrl is String) {
      final updatedUser = currentUser.copyWith(coverUrl: coverUrl);
      await _storage.saveUser(updatedUser);
      return updatedUser;
    }

    final user = User.fromJson(response.data['user'] ?? response.data);
    await _storage.saveUser(user);
    return user;
  }

  Future<bool> deleteAvatar() async {
    final response = await _apiClient.delete(ApiConstants.userAvatar);
    final currentUser = await _storage.getUser();
    if (currentUser != null) {
      await _storage.saveUser(currentUser.copyWith(avatar: null));
    }
    return response.data['success'] ?? true;
  }

  Future<bool> deleteCover() async {
    final response = await _apiClient.delete(ApiConstants.userCover);
    final currentUser = await _storage.getUser();
    if (currentUser != null) {
      await _storage.saveUser(currentUser.copyWith(coverUrl: null));
    }
    return response.data['success'] ?? true;
  }

  Future<DashboardStats> getDashboardStats() async {
    final response = await _apiClient.get(ApiConstants.userDashboard);
    return DashboardStats.fromJson(response.data);
  }

  Future<List<User>> getBlockedUsers() async {
    final response = await _apiClient.get(ApiConstants.userBlocked);
    final data = response.data['users'] ?? response.data['data'] ?? [];
    return (data as List).map((u) => User.fromJson(u)).toList();
  }

  Future<bool> blockUser(String username) async {
    final response = await _apiClient.post(
      '${ApiConstants.users}/$username/block',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> reportUser(
    String username, {
    required String reason,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.userReport(username),
      data: {
        'reason': reason.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
    return response.data['success'] ?? true;
  }

  Future<bool> unblockUser(String username) async {
    final response = await _apiClient.delete(
      '${ApiConstants.users}/$username/block',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> deleteAccount() async {
    final response = await _apiClient.delete('${ApiConstants.users}/account');
    if (response.data['success'] ?? true) {
      await _storage.clearAll();
    }
    return true;
  }

  Future<List<User>> searchUsers(
    String query, {
    int page = 1,
    int perPage = 20,
  }) async {
    final perPageValue = perPage.clamp(1, ApiConstants.usersMaxPerPage).toInt();
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPageValue,
    };
    if (query.isNotEmpty) {
      queryParameters['search'] = query;
    }

    final response = await _apiClient.get(
      ApiConstants.users,
      queryParameters: queryParameters,
    );
    final data = response.data['users'] ?? response.data['data'] ?? [];
    print("Fetched users: " + data.toString()); // Debug print
    return (data as List).map((u) => User.fromJson(u)).toList();
  }

  Future<List<User>> getRecommendationsFromContacts(
    List<String> phones,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.userRecommendationsFromContacts,
      data: {'phones': phones},
    );
    final data = response.data['users'] ?? response.data['data'] ?? [];
    return (data as List).map((u) => User.fromJson(u)).toList();
  }
}

class DashboardStats {
  final int messagesReceived;
  final int messagesSent;
  final int unreadMessages;
  final int confessionsReceived;
  final int confessionsSent;
  final int conversationsCount;
  final int groupsCount;
  final int storiesCount;
  final double walletBalance;

  DashboardStats({
    this.messagesReceived = 0,
    this.messagesSent = 0,
    this.unreadMessages = 0,
    this.confessionsReceived = 0,
    this.confessionsSent = 0,
    this.conversationsCount = 0,
    this.groupsCount = 0,
    this.storiesCount = 0,
    this.walletBalance = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      messagesReceived:
          json['messages_received'] ?? json['messagesReceived'] ?? 0,
      messagesSent: json['messages_sent'] ?? json['messagesSent'] ?? 0,
      unreadMessages: json['unread_messages'] ?? json['unreadMessages'] ?? 0,
      confessionsReceived:
          json['confessions_received'] ?? json['confessionsReceived'] ?? 0,
      confessionsSent: json['confessions_sent'] ?? json['confessionsSent'] ?? 0,
      conversationsCount:
          json['conversations_count'] ?? json['conversationsCount'] ?? 0,
      groupsCount: json['groups_count'] ?? json['groupsCount'] ?? 0,
      storiesCount: json['stories_count'] ?? json['storiesCount'] ?? 0,
      walletBalance: (json['wallet_balance'] ?? json['walletBalance'] ?? 0)
          .toDouble(),
    );
  }
}
