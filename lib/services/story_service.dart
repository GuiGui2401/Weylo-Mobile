import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../core/constants/api_constants.dart';
import '../models/story.dart';
import 'api_client.dart';

class StoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UserStories>> getFeed() async {
    final response = await _apiClient.get(ApiConstants.stories);
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => UserStories.fromJson(s)).toList();
  }

  Future<List<Story>> getMyStories() async {
    final response = await _apiClient.get(ApiConstants.storiesMyStories);
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => Story.fromJson(s)).toList();
  }

  Future<List<Story>> getUserStories(String username) async {
    final response = await _apiClient.get('${ApiConstants.stories}/user/$username');
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => Story.fromJson(s)).toList();
  }

  Future<List<Story>> getUserStoriesById(int userId) async {
    final response = await _apiClient.get(ApiConstants.storiesByUserId(userId));
    final data = response.data['stories'] ?? response.data['data'] ?? response.data;

    // Handle case where data is a Map instead of List
    if (data is Map) {
      return [];
    }
    if (data is! List) {
      return [];
    }
    return data.map((s) => Story.fromJson(s)).toList();
  }

  Future<Story> getStory(int id) async {
    final response = await _apiClient.get('${ApiConstants.stories}/$id');
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  Future<Story> createTextStory({
    required String content,
    String? backgroundColor,
    int duration = 5,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.stories,
      data: {
        'type': 'text',
        'content': content,
        'background_color': backgroundColor,
        'duration': duration,
      },
    );
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  Future<Story> createMediaStory({
    required String filePath,
    required String type,
    String? content,
    int duration = 5,
  }) async {
    final filename = filePath.split('/').last;
    final extension = filename.split('.').last.toLowerCase();
    String contentType;

    if (type == 'image') {
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
        default:
          contentType = 'image/jpeg';
          break;
      }
    } else {
      // video
      switch (extension) {
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
        case 'mp4':
        default:
          contentType = 'video/mp4';
          break;
      }
    }

    // Debug logging for story creation
    debugPrint('=== Creating Story ===');
    debugPrint('Type: $type');
    debugPrint('File path: $filePath');
    debugPrint('Filename: $filename');
    debugPrint('Extension: $extension');
    debugPrint('Content-Type: $contentType');
    debugPrint('Has content text: ${content != null && content.isNotEmpty}');
    debugPrint('Duration: $duration');
    debugPrint('=====================');

    final Map<String, dynamic> formDataMap = {
      'type': type,
      'media': await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: http_parser.MediaType.parse(contentType),
      ),
      'duration': duration,
    };

    if (content != null && content.isNotEmpty) {
      formDataMap['content'] = content;
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await _apiClient.uploadFile(
      ApiConstants.stories,
      data: formData,
    );
    return Story.fromJson(response.data['story'] ?? response.data);
  }

  // Unified method for creating stories
  Future<Story> createStory({
    File? media,
    String? text,
    String? backgroundColor,
    String type = 'text',
    int duration = 5,
  }) async {
    if (media != null) {
      return createMediaStory(
        filePath: media.path,
        type: type,
        content: text,
        duration: duration,
      );
    } else {
      return createTextStory(
        content: text ?? '',
        backgroundColor: backgroundColor,
        duration: duration,
      );
    }
  }

  Future<bool> viewStory(int storyId) async {
    final response = await _apiClient.post('${ApiConstants.stories}/$storyId/view');
    return response.data['success'] ?? true;
  }

  // Alias for story viewer
  Future<bool> markAsViewed(int storyId) async {
    return viewStory(storyId);
  }

  Future<List<StoryView>> getViewers(int storyId) async {
    final response = await _apiClient.get('${ApiConstants.stories}/$storyId/viewers');
    final data = response.data['viewers'] ?? response.data['data'] ?? [];
    return (data as List).map((v) => StoryView.fromJson(v)).toList();
  }

  Future<bool> deleteStory(int storyId) async {
    final response = await _apiClient.delete('${ApiConstants.stories}/$storyId');
    return response.data['success'] ?? true;
  }

  Future<StoryStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.storiesStats);
    return StoryStats.fromJson(response.data);
  }

  // ==================== COMMENTS ====================

  Future<List<StoryComment>> getComments(int storyId) async {
    final response = await _apiClient.get('${ApiConstants.stories}/$storyId/comments');
    final data = response.data['comments'] ?? response.data['data'] ?? [];
    return (data as List).map((c) => StoryComment.fromJson(c)).toList();
  }

  Future<StoryComment> addComment(int storyId, String content, {int? parentId}) async {
    final response = await _apiClient.post(
      '${ApiConstants.stories}/$storyId/comments',
      data: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      },
    );
    return StoryComment.fromJson(response.data['comment'] ?? response.data);
  }

  Future<bool> deleteComment(int storyId, int commentId) async {
    final response = await _apiClient.delete('${ApiConstants.stories}/$storyId/comments/$commentId');
    return response.data['success'] ?? true;
  }
}
