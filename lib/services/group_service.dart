import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/group.dart';
import 'api_client.dart';

class GroupService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Group>> getMyGroups() async {
    final response = await _apiClient.get(ApiConstants.groups);
    final data = response.data['groups'] ?? response.data['data'] ?? [];
    return (data as List).map((g) => Group.fromJson(g)).toList();
  }

  Future<List<Group>> discoverGroups({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.groupsDiscover,
      queryParameters: {'page': page},
    );
    final data = response.data['groups'] ?? response.data['data'] ?? [];
    return (data as List).map((g) => Group.fromJson(g)).toList();
  }

  Future<Group> getGroup(int id) async {
    final response = await _apiClient.get('${ApiConstants.groups}/$id');
    return Group.fromJson(response.data['group'] ?? response.data);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    int maxMembers = AppConstants.maxGroupMembers,
    File? avatar,
  }) async {
    if (avatar != null) {
      // Utiliser FormData si on a une image
      final formData = FormData.fromMap({
        'name': name,
        if (description != null) 'description': description,
        'is_public': isPublic ? '1' : '0',
        'max_members': maxMembers.toString(),
        'avatar': await MultipartFile.fromFile(
          avatar.path,
          filename: 'avatar.jpg',
        ),
      });
      final response = await _apiClient.post(
        ApiConstants.groups,
        data: formData,
      );
      return Group.fromJson(response.data['group'] ?? response.data);
    }

    final response = await _apiClient.post(
      ApiConstants.groups,
      data: {
        'name': name,
        'description': description,
        'is_public': isPublic,
        'max_members': maxMembers,
      },
    );
    return Group.fromJson(response.data['group'] ?? response.data);
  }

  Future<Group> updateGroup(
    int groupId, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isPublic != null) data['is_public'] = isPublic;

    final response = await _apiClient.put(
      '${ApiConstants.groups}/$groupId',
      data: data,
    );
    return Group.fromJson(response.data['group'] ?? response.data);
  }

  Future<bool> deleteGroup(int groupId) async {
    final response = await _apiClient.delete('${ApiConstants.groups}/$groupId');
    return response.data['success'] ?? true;
  }

  Future<Group> joinGroup(String inviteCode) async {
    final response = await _apiClient.post(
      ApiConstants.groupsJoin,
      data: {'invite_code': inviteCode},
    );
    return Group.fromJson(response.data['group'] ?? response.data);
  }

  Future<bool> leaveGroup(int groupId) async {
    final response = await _apiClient.post('${ApiConstants.groups}/$groupId/leave');
    return response.data['success'] ?? true;
  }

  Future<PaginatedGroupMessages> getMessages(
    int groupId, {
    int page = 1,
    int perPage = AppConstants.messagesPageSize,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.groups}/$groupId/messages',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return PaginatedGroupMessages.fromJson(response.data);
  }

  Future<GroupMessage> sendMessage({
    required int groupId,
    String? content,
    int? replyToId,
    dynamic image,
    dynamic voice,
  }) async {
    // If there's media, use multipart form data
    if (image != null || voice != null) {
      final formData = <String, dynamic>{};
      if (content != null && content.isNotEmpty) {
        formData['content'] = content;
      }
      if (replyToId != null) {
        formData['reply_to_message_id'] = replyToId;
      }
      if (image != null) {
        formData['image'] = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
      }
      if (voice != null) {
        final filename = voice.path.split('/').last;
        final extension = filename.split('.').last.toLowerCase();
        String contentType = 'audio/m4a';

        // Determine content type based on file extension
        switch (extension) {
          case 'mp3':
            contentType = 'audio/mpeg';
            break;
          case 'm4a':
          case 'aac':
            contentType = 'audio/aac';
            break;
          case 'wav':
            contentType = 'audio/wav';
            break;
          case 'ogg':
            contentType = 'audio/ogg';
            break;
          case 'webm':
            contentType = 'audio/webm';
            break;
        }

        formData['voice'] = await MultipartFile.fromFile(
          voice.path,
          filename: filename,
          contentType: http_parser.MediaType.parse(contentType),
        );
      }

      final response = await _apiClient.uploadFile(
        '${ApiConstants.groups}/$groupId/messages',
        data: FormData.fromMap(formData),
      );
      return GroupMessage.fromJson(response.data['message'] ?? response.data);
    }

    // No media, use regular JSON
    final data = <String, dynamic>{};
    if (content != null && content.isNotEmpty) {
      data['content'] = content;
    }
    if (replyToId != null) {
      data['reply_to_message_id'] = replyToId;
    }

    final response = await _apiClient.post(
      '${ApiConstants.groups}/$groupId/messages',
      data: data,
    );
    return GroupMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> markAsRead(int groupId) async {
    final response = await _apiClient.post('${ApiConstants.groups}/$groupId/read');
    return response.data['success'] ?? true;
  }

  Future<GroupMessage> editMessage(
    int groupId,
    int messageId, {
    required String content,
  }) async {
    final response = await _apiClient.put(
      '${ApiConstants.groups}/$groupId/messages/$messageId',
      data: {'content': content},
    );
    return GroupMessage.fromJson(response.data['message'] ?? response.data);
  }

  Future<bool> deleteMessage(int groupId, int messageId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.groups}/$groupId/messages/$messageId',
    );
    return response.data['success'] ?? true;
  }

  Future<List<GroupMember>> getMembers(int groupId) async {
    final response = await _apiClient.get('${ApiConstants.groups}/$groupId/members');
    final data = response.data['members'] ?? response.data['data'] ?? [];
    return (data as List).map((m) => GroupMember.fromJson(m)).toList();
  }

  Future<bool> removeMember(int groupId, int memberId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.groups}/$groupId/members/$memberId',
    );
    return response.data['success'] ?? true;
  }

  Future<GroupMember> updateMemberRole(int groupId, int memberId, String role) async {
    final response = await _apiClient.put(
      '${ApiConstants.groups}/$groupId/members/$memberId/role',
      data: {'role': role},
    );
    return GroupMember.fromJson(response.data['member'] ?? response.data);
  }

  Future<String> regenerateInviteCode(int groupId) async {
    final response = await _apiClient.post(
      '${ApiConstants.groups}/$groupId/regenerate-invite',
    );
    return response.data['invite_code'] ?? response.data['inviteCode'];
  }

  Future<GroupStats> getStats() async {
    final response = await _apiClient.get(ApiConstants.groupsStats);
    return GroupStats.fromJson(response.data);
  }
}

class PaginatedGroupMessages {
  final List<GroupMessage> messages;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  PaginatedGroupMessages({
    required this.messages,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.hasMore = false,
  });

  factory PaginatedGroupMessages.fromJson(Map<String, dynamic> json) {
    final data = json['messages'] ?? json['data'] ?? [];
    final meta = json['meta'] ?? json;

    return PaginatedGroupMessages(
      messages: (data as List).map((m) => GroupMessage.fromJson(m)).toList(),
      currentPage: meta['current_page'] ?? 1,
      lastPage: meta['last_page'] ?? 1,
      total: meta['total'] ?? 0,
      hasMore: (meta['current_page'] ?? 1) < (meta['last_page'] ?? 1),
    );
  }
}
