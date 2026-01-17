import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/confession.dart';
import 'api_client.dart';

class ConfessionService {
  final ApiClient _apiClient = ApiClient();

  // Alias for feed provider
  Future<PaginatedConfessions> getConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    return getPublicConfessions(page: page, perPage: perPage);
  }

  Future<PaginatedConfessions> getPublicConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessions,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  /// Get confessions by user ID (fetches username first then calls API)
  Future<PaginatedConfessions> getUserConfessions(
    int userId, {
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    try {
      // First try to get user info to obtain username
      final userResponse = await _apiClient.get('${ApiConstants.userById}/$userId');
      final username = userResponse.data['user']?['username'] ?? userResponse.data['username'];

      if (username != null) {
        return getUserConfessionsByUsername(username, page: page, perPage: perPage);
      }

      // Fallback: return empty list if user not found
      return PaginatedConfessions(confessions: []);
    } catch (e) {
      // If user lookup fails, return empty list
      return PaginatedConfessions(confessions: []);
    }
  }

  /// Get confessions by username (preferred method)
  Future<PaginatedConfessions> getUserConfessionsByUsername(
    String username, {
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.userConfessions(username),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getReceivedConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessionsReceived,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getSentConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.confessionsSent,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedConfessions.fromJson(response.data);
  }

  Future<PaginatedConfessions> getLikedConfessions({
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.confessionsLiked,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return PaginatedConfessions.fromJson(response.data);
    } catch (e) {
      // Return empty list if endpoint fails (e.g., 404 due to route conflict)
      return PaginatedConfessions(confessions: []);
    }
  }

  Future<Confession> getConfession(int id) async {
    final response = await _apiClient.get('${ApiConstants.confessions}/$id');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> createConfession({
    String? content,
    String type = 'public',
    String? recipientUsername,
    File? image,
    File? video,
    bool isAnonymous = false,
  }) async {
    // If there's media, use multipart form data
    if (image != null || video != null) {
      final Map<String, dynamic> formDataMap = {};

      if (content != null && content.isNotEmpty) {
        formDataMap['content'] = content;
      }
      formDataMap['type'] = type;
      formDataMap['is_anonymous'] = isAnonymous ? '1' : '0';

      if (recipientUsername != null) {
        formDataMap['recipient_username'] = recipientUsername;
      }

      if (image != null) {
        final filename = image.path.split('/').last;
        final extension = filename.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';

        switch (extension) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
        }

        formDataMap['image'] = await MultipartFile.fromFile(
          image.path,
          filename: filename,
          contentType: http_parser.MediaType.parse(contentType),
        );
      }

      if (video != null) {
        final filename = video.path.split('/').last;
        final extension = filename.split('.').last.toLowerCase();
        String contentType = 'video/mp4';

        switch (extension) {
          case 'mp4':
            contentType = 'video/mp4';
            break;
          case 'mov':
            contentType = 'video/quicktime';
            break;
          case 'avi':
            contentType = 'video/x-msvideo';
            break;
          case 'mkv':
            contentType = 'video/x-matroska';
            break;
          case 'webm':
            contentType = 'video/webm';
            break;
        }

        formDataMap['video'] = await MultipartFile.fromFile(
          video.path,
          filename: filename,
          contentType: http_parser.MediaType.parse(contentType),
        );
      }

      final formData = FormData.fromMap(formDataMap);
      final response = await _apiClient.uploadFile(
        ApiConstants.confessions,
        data: formData,
      );
      return Confession.fromJson(response.data['confession'] ?? response.data);
    }

    // No media, use regular JSON
    final data = <String, dynamic>{
      'type': type,
      'is_anonymous': isAnonymous,
    };

    if (content != null && content.isNotEmpty) {
      data['content'] = content;
    }

    if (recipientUsername != null) {
      data['recipient_username'] = recipientUsername;
    }

    final response = await _apiClient.post(
      ApiConstants.confessions,
      data: data,
    );
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> likeConfession(int confessionId) async {
    final response = await _apiClient.post('${ApiConstants.confessions}/$confessionId/like');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> unlikeConfession(int confessionId) async {
    final response = await _apiClient.delete('${ApiConstants.confessions}/$confessionId/like');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<Confession> revealIdentity(int confessionId) async {
    final response = await _apiClient.post('${ApiConstants.confessions}/$confessionId/reveal');
    return Confession.fromJson(response.data['confession'] ?? response.data);
  }

  Future<bool> reportConfession(int confessionId, {String? reason}) async {
    final response = await _apiClient.post(
      '${ApiConstants.confessions}/$confessionId/report',
      data: reason != null ? {'reason': reason} : null,
    );
    return response.data['success'] ?? true;
  }

  Future<List<ConfessionComment>> getComments(int confessionId) async {
    final response = await _apiClient.get('${ApiConstants.confessions}/$confessionId/comments');
    final data = response.data['comments'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => ConfessionComment.fromJson(c)).toList();
  }

  Future<ConfessionComment> addComment(int confessionId, String content) async {
    final response = await _apiClient.post(
      '${ApiConstants.confessions}/$confessionId/comments',
      data: {'content': content},
    );
    return ConfessionComment.fromJson(response.data['comment'] ?? response.data);
  }

  Future<bool> deleteComment(int confessionId, int commentId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.confessions}/$confessionId/comments/$commentId',
    );
    return response.data['success'] ?? true;
  }

  Future<bool> deleteConfession(int confessionId) async {
    final response = await _apiClient.delete('${ApiConstants.confessions}/$confessionId');
    return response.data['success'] ?? true;
  }

  Future<ConfessionStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.confessionsStats);
    return ConfessionStats.fromJson(response.data);
  }

  Future<List<Confession>> searchConfessions(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.confessions}/search',
        queryParameters: {'q': query},
      );
      final data = response.data['confessions'] ?? response.data['data'] ?? [];
      return (data as List).map((c) => Confession.fromJson(c)).toList();
    } catch (e) {
      // If search endpoint doesn't exist, return empty list
      return [];
    }
  }
}

class PaginatedConfessions {
  final List<Confession> confessions;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  PaginatedConfessions({
    required this.confessions,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
  });

  factory PaginatedConfessions.fromJson(Map<String, dynamic> json) {
    final data = json['confessions'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedConfessions(
      confessions: (data as List).map((c) => Confession.fromJson(c)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}
