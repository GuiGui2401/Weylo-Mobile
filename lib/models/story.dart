import 'user.dart';

enum StoryType { image, video, text }

enum StoryStatus { active, expired }

class Story {
  final int id;
  final int userId;
  final StoryType type;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? content;
  final int duration;
  final StoryStatus status;
  final int viewsCount;
  final String? backgroundColor;
  final DateTime expiresAt;
  final User? user;
  final List<StoryView>? viewers;
  final bool isViewed;
  final bool hasViewerSubscription;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    this.type = StoryType.text,
    this.mediaUrl,
    this.thumbnailUrl,
    this.content,
    this.duration = 5,
    this.status = StoryStatus.active,
    this.viewsCount = 0,
    this.backgroundColor,
    required this.expiresAt,
    this.user,
    this.viewers,
    this.isViewed = false,
    this.hasViewerSubscription = false,
    required this.createdAt,
  });

  bool get isExpired =>
      status == StoryStatus.expired || DateTime.now().isAfter(expiresAt);
  bool get isText => type == StoryType.text;
  bool get isImage => type == StoryType.image;
  bool get isVideo => type == StoryType.video;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      type: _parseType(json['type']),
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      content: json['content'],
      duration: json['duration'] ?? 5,
      status: json['status'] == 'expired'
          ? StoryStatus.expired
          : StoryStatus.active,
      viewsCount: json['views_count'] ?? json['viewsCount'] ?? 0,
      backgroundColor: json['background_color'] ?? json['backgroundColor'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      viewers: json['viewers'] != null && json['viewers'] is List
          ? (json['viewers'] as List).map((v) => StoryView.fromJson(v)).toList()
          : null,
      isViewed: json['is_viewed'] ?? json['isViewed'] ?? false,
      hasViewerSubscription:
          json['has_viewer_subscription'] ?? json['hasViewerSubscription'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  static StoryType _parseType(String? type) {
    switch (type) {
      case 'image':
        return StoryType.image;
      case 'video':
        return StoryType.video;
      default:
        return StoryType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content': content,
      'duration': duration,
      'status': status.name,
      'views_count': viewsCount,
      'background_color': backgroundColor,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StoryView {
  final int id;
  final int storyId;
  final int userId;
  final User? user;
  final DateTime viewedAt;

  StoryView({
    required this.id,
    required this.storyId,
    required this.userId,
    this.user,
    required this.viewedAt,
  });

  factory StoryView.fromJson(Map<String, dynamic> json) {
    final userPayload = json['user'] ??
        {
          'id': json['id'] ?? json['user_id'] ?? 0,
          'full_name': json['full_name'] ?? json['name'] ?? 'Anonyme',
          'username': json['username'] ?? '',
          'avatar_url': json['avatar_url'],
          'is_premium': json['is_premium'] ?? false,
        };
    return StoryView(
      id: json['id'] ?? 0,
      storyId: json['story_id'] ?? json['storyId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? json['id'] ?? 0,
      user: User.fromJson(userPayload),
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'])
          : DateTime.now(),
    );
  }
}

class StoryPreview {
  final String type;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? content;
  final String? backgroundColor;

  StoryPreview({
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    this.content,
    this.backgroundColor,
  });

  factory StoryPreview.fromJson(Map<String, dynamic> json) {
    return StoryPreview(
      type: json['type'] ?? 'text',
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      content: json['content'],
      backgroundColor: json['background_color'] ?? json['backgroundColor'],
    );
  }
}

class UserStories {
  final User user;
  final int realUserId; // L'ID réel de l'utilisateur (même si anonyme)
  final List<Story> stories;
  final bool hasUnviewed;
  final bool isAnonymous;
  final bool isIdentityRevealed;
  final int storiesCount;
  final DateTime? latestStoryAt;
  final StoryPreview? preview;

  UserStories({
    required this.user,
    required this.realUserId,
    required this.stories,
    this.hasUnviewed = false,
    this.isAnonymous = false,
    this.isIdentityRevealed = false,
    this.storiesCount = 0,
    this.latestStoryAt,
    this.preview,
  });

  factory UserStories.fromJson(Map<String, dynamic> json) {
    final storiesData = json['stories'];
    List<Story> stories = [];
    if (storiesData is List) {
      stories = storiesData.map((s) => Story.fromJson(s)).toList();
    }

    // Parse user data
    final userData = json['user'];
    User user;
    if (userData != null) {
      user = User.fromJson(userData);
    } else {
      // Créer un utilisateur par défaut si les données sont manquantes
      user = User(
        id: json['real_user_id'] ?? 0,
        firstName: 'Utilisateur',
        username: 'anonyme',
      );
    }

    // Utiliser real_user_id si disponible, sinon user.id
    final realUserId =
        json['real_user_id'] ?? json['realUserId'] ?? userData?['id'] ?? 0;

    // Parse preview
    StoryPreview? preview;
    if (json['preview'] != null) {
      preview = StoryPreview.fromJson(json['preview']);
    }

    return UserStories(
      user: user,
      realUserId: realUserId is int
          ? realUserId
          : int.tryParse(realUserId.toString()) ?? 0,
      stories: stories,
      hasUnviewed:
          json['has_new'] ??
          json['has_unviewed'] ??
          json['hasUnviewed'] ??
          !(json['all_viewed'] ?? true),
      isAnonymous: json['is_anonymous'] ?? json['isAnonymous'] ?? false,
      isIdentityRevealed:
          json['identity_revealed'] ??
          json['is_identity_revealed'] ??
          json['identityRevealed'] ??
          json['isIdentityRevealed'] ??
          false,
      storiesCount:
          json['stories_count'] ?? json['storiesCount'] ?? stories.length,
      latestStoryAt: json['latest_story_at'] != null
          ? DateTime.parse(json['latest_story_at'])
          : null,
      preview: preview,
    );
  }
}

class StoryStats {
  final int totalStories;
  final int totalViews;
  final int activeStories;

  StoryStats({
    this.totalStories = 0,
    this.totalViews = 0,
    this.activeStories = 0,
  });

  factory StoryStats.fromJson(Map<String, dynamic> json) {
    return StoryStats(
      totalStories: json['total_stories'] ?? json['totalStories'] ?? 0,
      totalViews: json['total_views'] ?? json['totalViews'] ?? 0,
      activeStories: json['active_stories'] ?? json['activeStories'] ?? 0,
    );
  }
}

class StoryComment {
  final int id;
  final String content;
  final int likesCount;
  final User? user;
  final List<StoryComment>? replies;
  final DateTime createdAt;

  StoryComment({
    required this.id,
    required this.content,
    this.likesCount = 0,
    this.user,
    this.replies,
    required this.createdAt,
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    return StoryComment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? json['likesCount'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      replies: json['replies'] != null && json['replies'] is List
          ? (json['replies'] as List)
                .map((r) => StoryComment.fromJson(r))
                .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
