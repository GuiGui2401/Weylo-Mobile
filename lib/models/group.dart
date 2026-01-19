import 'user.dart';

class Group {
  final int id;
  final String name;
  final String? description;
  final int creatorId;
  final String inviteCode;
  final bool isPublic;
  final bool onlyOwnerCanPost;
  final int maxMembers;
  final int membersCount;
  final String? avatarUrl;
  final User? creator;
  final List<GroupMember>? members;
  final GroupMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.inviteCode,
    this.isPublic = false,
    this.onlyOwnerCanPost = false,
    this.maxMembers = 50,
    this.membersCount = 0,
    this.avatarUrl,
    this.creator,
    this.members,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isFull => membersCount >= maxMembers;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      creatorId: json['creator_id'] ?? json['creatorId'] ?? 0,
      inviteCode: json['invite_code'] ?? json['inviteCode'] ?? '',
      isPublic: json['is_public'] ?? json['isPublic'] ?? false,
      onlyOwnerCanPost: json['only_owner_can_post'] ?? json['onlyOwnerCanPost'] ?? false,
      maxMembers: json['max_members'] ?? json['maxMembers'] ?? 50,
      membersCount: json['members_count'] ?? json['membersCount'] ?? 0,
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      members: json['members'] != null
          ? (json['members'] as List).map((m) => GroupMember.fromJson(m)).toList()
          : null,
      lastMessage: json['last_message'] != null
          ? GroupMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'invite_code': inviteCode,
      'is_public': isPublic,
      'only_owner_can_post': onlyOwnerCanPost,
      'max_members': maxMembers,
      'members_count': membersCount,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class GroupMember {
  final int id;
  final int groupId;
  final int userId;
  final String role;
  final User? user;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.user,
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin' || role == 'creator';
  bool get isCreator => role == 'creator';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? json['groupId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      role: json['role'] ?? 'member',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }
}

class GroupMessage {
  final int id;
  final int groupId;
  final int senderId;
  final String content;
  final String type;
  final String? mediaUrl;
  final String? voiceEffect;
  final int? replyToMessageId;
  final User? sender;
  final GroupMessage? replyToMessage;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.mediaUrl,
    this.voiceEffect,
    this.replyToMessageId,
    this.sender,
    this.replyToMessage,
    required this.createdAt,
  });

  bool get isSystem => type == 'system';
  bool get hasImage => type == 'image' && mediaUrl != null;
  bool get hasVoice => type == 'voice' && mediaUrl != null;
  bool get hasVideo => type == 'video' && mediaUrl != null;

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? json['groupId'] ?? 0,
      senderId: json['sender_id'] ?? json['senderId'] ?? 0,
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['media_full_url'] ?? json['media_url'] ?? json['mediaUrl'],
      voiceEffect: json['voice_effect'] ?? json['voiceEffect'],
      replyToMessageId: json['reply_to_message_id'] ?? json['replyToMessageId'],
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      replyToMessage: json['reply_to_message'] != null
          ? GroupMessage.fromJson(json['reply_to_message'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? replyTo;
    if (replyToMessage != null) {
      replyTo = {
        'id': replyToMessage!.id,
        'content': replyToMessage!.content,
        'type': replyToMessage!.type,
        'media_url': replyToMessage!.mediaUrl,
        'sender_id': replyToMessage!.senderId,
        if (replyToMessage!.sender != null) 'sender': replyToMessage!.sender!.toJson(),
      };
    }

    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'voice_effect': voiceEffect,
      'reply_to_message_id': replyToMessageId,
      if (sender != null) 'sender': sender!.toJson(),
      if (replyTo != null) 'reply_to_message': replyTo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroupStats {
  final int totalGroups;
  final int groupsCreated;
  final int totalMessages;

  GroupStats({
    this.totalGroups = 0,
    this.groupsCreated = 0,
    this.totalMessages = 0,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalGroups: json['total_groups'] ?? json['totalGroups'] ?? 0,
      groupsCreated: json['groups_created'] ?? json['groupsCreated'] ?? 0,
      totalMessages: json['total_messages'] ?? json['totalMessages'] ?? 0,
    );
  }
}
