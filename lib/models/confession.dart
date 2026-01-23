import 'user.dart';

enum ConfessionType { private, public }

enum ConfessionStatus { pending, approved, rejected }

class Confession {
  final int id;
  final int authorId;
  final int? recipientId;
  final String content;
  final String? image;
  final String? imageUrl;
  final String? video;
  final String? videoUrl;
  final ConfessionType type;
  final ConfessionStatus status;
  final bool isIdentityRevealed;
  final bool isAnonymous;
  final int likesCount;
  final int viewsCount;
  final int sharesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSponsored;
  final int? promotionId;
  final String? promotionGoal;
  final String? promotionCtaLabel;
  final String? promotionWebsiteUrl;
  final User? author;
  final User? recipient;
  final List<ConfessionComment>? comments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Confession({
    required this.id,
    required this.authorId,
    this.recipientId,
    required this.content,
    this.image,
    this.imageUrl,
    this.video,
    this.videoUrl,
    this.type = ConfessionType.public,
    this.status = ConfessionStatus.pending,
    this.isIdentityRevealed = false,
    this.isAnonymous = false,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSponsored = false,
    this.promotionId,
    this.promotionGoal,
    this.promotionCtaLabel,
    this.promotionWebsiteUrl,
    this.author,
    this.recipient,
    this.comments,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasMedia => hasImage || hasVideo;

  bool get isPublic => type == ConfessionType.public;
  bool get isApproved => status == ConfessionStatus.approved;

  /// Détermine si l'auteur doit être affiché
  /// L'auteur est visible si: post public ET non anonyme, OU identité révélée
  bool get shouldShowAuthor => isPublic && !isAnonymous;

  String get authorInitials {
    if (author != null) {
      return author!.initials;
    }
    return '??';
  }

  factory Confession.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] ?? json['mediaType'];
    final mediaUrl = json['media_url'] ?? json['mediaUrl'];
    final mediaFullUrl = json['media_full_url'] ?? json['mediaFullUrl'];
    final isImageMedia = mediaType == 'image';
    final isVideoMedia = mediaType == 'video';

    return Confession(
      id: json['id'] ?? 0,
      authorId: json['author_id'] ?? json['authorId'] ?? 0,
      recipientId: json['recipient_id'] ?? json['recipientId'],
      content: json['content'] ?? '',
      image: json['image'],
      imageUrl:
          json['image_url'] ??
          json['imageUrl'] ??
          json['image_full_url'] ??
          json['imageFullUrl'] ??
          (isImageMedia ? (mediaFullUrl ?? mediaUrl) : null),
      video: json['video'],
      videoUrl:
          json['video_url'] ??
          json['videoUrl'] ??
          json['video_full_url'] ??
          json['videoFullUrl'] ??
          (isVideoMedia ? (mediaFullUrl ?? mediaUrl) : null),
      type: json['type'] == 'private'
          ? ConfessionType.private
          : ConfessionType.public,
      status: _parseStatus(json['status']),
      isIdentityRevealed:
          json['is_identity_revealed'] ?? json['isIdentityRevealed'] ?? false,
      isAnonymous: json['is_anonymous'] ?? json['isAnonymous'] ?? false,
      likesCount: json['likes_count'] ?? json['likesCount'] ?? 0,
      viewsCount: json['views_count'] ?? json['viewsCount'] ?? 0,
      sharesCount: json['shares_count'] ?? json['sharesCount'] ?? 0,
      commentsCount: json['comments_count'] ?? json['commentsCount'] ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      isSponsored: json['is_sponsored'] ?? json['isSponsored'] ?? false,
      promotionId: json['promotion_id'] ?? json['promotionId'],
      promotionGoal: json['promotion']?['goal'] ?? json['promotion_goal'],
      promotionCtaLabel: json['promotion']?['cta_label'] ?? json['promotion_cta_label'],
      promotionWebsiteUrl: json['promotion']?['website_url'] ?? json['promotion_website_url'],
      author: json['author'] != null ? User.fromJson(json['author']) : null,
      recipient: json['recipient'] != null
          ? User.fromJson(json['recipient'])
          : null,
      comments: json['comments'] != null && json['comments'] is List
          ? (json['comments'] as List)
                .map((c) => ConfessionComment.fromJson(c))
                .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static ConfessionStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return ConfessionStatus.approved;
      case 'rejected':
        return ConfessionStatus.rejected;
      default:
        return ConfessionStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'recipient_id': recipientId,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'video': video,
      'video_url': videoUrl,
      'type': type == ConfessionType.private ? 'private' : 'public',
      'status': status.name,
      'is_identity_revealed': isIdentityRevealed,
      'is_anonymous': isAnonymous,
      'likes_count': likesCount,
      'views_count': viewsCount,
      'shares_count': sharesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_sponsored': isSponsored,
      'promotion_id': promotionId,
      'promotion_goal': promotionGoal,
      'promotion_cta_label': promotionCtaLabel,
      'promotion_website_url': promotionWebsiteUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Confession copyWith({
    int? likesCount,
    bool? isLiked,
    bool? isSponsored,
    int? promotionId,
    String? promotionGoal,
    String? promotionCtaLabel,
    String? promotionWebsiteUrl,
    int? commentsCount,
    int? sharesCount,
    bool? isIdentityRevealed,
    String? imageUrl,
    String? videoUrl,
    User? author,
  }) {
    return Confession(
      id: id,
      authorId: authorId,
      recipientId: recipientId,
      content: content,
      image: image,
      imageUrl: imageUrl ?? this.imageUrl,
      video: video,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type,
      status: status,
      isIdentityRevealed: isIdentityRevealed ?? this.isIdentityRevealed,
      isAnonymous: isAnonymous,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSponsored: isSponsored ?? this.isSponsored,
      promotionId: promotionId ?? this.promotionId,
      promotionGoal: promotionGoal ?? this.promotionGoal,
      promotionCtaLabel: promotionCtaLabel ?? this.promotionCtaLabel,
      promotionWebsiteUrl: promotionWebsiteUrl ?? this.promotionWebsiteUrl,
      author: author ?? this.author,
      recipient: recipient,
      comments: comments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ConfessionComment {
  final int id;
  final int confessionId;
  final int userId;
  final int? parentId;
  final ConfessionCommentReply? parent;
  final String content;
  final String? mediaUrl;
  final String? mediaFullUrl;
  final String? mediaType;
  final User? user;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  ConfessionComment({
    required this.id,
    required this.confessionId,
    required this.userId,
    this.parentId,
    this.parent,
    required this.content,
    this.mediaUrl,
    this.mediaFullUrl,
    this.mediaType,
    this.user,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory ConfessionComment.fromJson(Map<String, dynamic> json) {
    User? parseCommentUser(dynamic author) {
      if (author is! Map<String, dynamic>) return null;
      if (author.containsKey('full_name') ||
          author.containsKey('fullName') ||
          author.containsKey('first_name') ||
          author.containsKey('firstName')) {
        return User.fromJson(author);
      }
      final name = author['name'] ?? author['username'] ?? '';
      return User.fromJson({
        'id': author['id'] ?? 0,
        'full_name': name,
        'username': author['username'] ?? '',
        'avatar_url': author['avatar_url'],
        'is_premium': author['is_premium'] ?? false,
        'is_verified': author['is_verified'] ?? false,
      });
    }

    return ConfessionComment(
      id: json['id'] ?? 0,
      confessionId: json['confession_id'] ?? json['confessionId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      parentId: json['parent_id'] ?? json['parentId'],
      parent: json['parent'] != null
          ? ConfessionCommentReply.fromJson(json['parent'])
          : null,
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      mediaFullUrl: json['media_full_url'] ?? json['mediaFullUrl'],
      mediaType: json['media_type'] ?? json['mediaType'],
      user: parseCommentUser(json['user'] ?? json['author']),
      likesCount: json['likes_count'] ?? json['likesCount'] ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  ConfessionComment copyWith({
    int? likesCount,
    bool? isLiked,
  }) {
    return ConfessionComment(
      id: id,
      confessionId: confessionId,
      userId: userId,
      parentId: parentId,
      parent: parent,
      content: content,
      mediaUrl: mediaUrl,
      mediaFullUrl: mediaFullUrl,
      mediaType: mediaType,
      user: user,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

class ConfessionCommentReply {
  final int id;
  final String content;
  final bool isAnonymous;
  final User? user;

  ConfessionCommentReply({
    required this.id,
    required this.content,
    required this.isAnonymous,
    this.user,
  });

  factory ConfessionCommentReply.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return ConfessionCommentReply(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      isAnonymous: json['is_anonymous'] ?? json['isAnonymous'] ?? false,
      user: author != null
          ? User.fromJson({
              'id': author['id'] ?? 0,
              'full_name': author['name'] ?? author['username'] ?? '',
              'username': author['username'] ?? '',
              'avatar_url': author['avatar_url'],
              'is_premium': author['is_premium'] ?? false,
              'is_verified': author['is_verified'] ?? false,
            })
          : null,
    );
  }
}

class ConfessionStats {
  final int totalWritten;
  final int totalReceived;
  final int totalLikes;
  final int totalViews;

  ConfessionStats({
    this.totalWritten = 0,
    this.totalReceived = 0,
    this.totalLikes = 0,
    this.totalViews = 0,
  });

  factory ConfessionStats.fromJson(Map<String, dynamic> json) {
    return ConfessionStats(
      totalWritten: json['total_written'] ?? json['totalWritten'] ?? 0,
      totalReceived: json['total_received'] ?? json['totalReceived'] ?? 0,
      totalLikes: json['total_likes'] ?? json['totalLikes'] ?? 0,
      totalViews: json['total_views'] ?? json['totalViews'] ?? 0,
    );
  }
}
