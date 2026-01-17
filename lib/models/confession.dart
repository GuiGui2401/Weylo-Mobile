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
  final int commentsCount;
  final bool isLiked;
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
    this.commentsCount = 0,
    this.isLiked = false,
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
  bool get shouldShowAuthor => (isPublic && !isAnonymous) || isIdentityRevealed;

  String get authorInitials {
    if (author != null) {
      return author!.initials;
    }
    return '??';
  }

  factory Confession.fromJson(Map<String, dynamic> json) {
    return Confession(
      id: json['id'] ?? 0,
      authorId: json['author_id'] ?? json['authorId'] ?? 0,
      recipientId: json['recipient_id'] ?? json['recipientId'],
      content: json['content'] ?? '',
      image: json['image'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      video: json['video'],
      videoUrl: json['video_url'] ?? json['videoUrl'],
      type: json['type'] == 'private' ? ConfessionType.private : ConfessionType.public,
      status: _parseStatus(json['status']),
      isIdentityRevealed: json['is_identity_revealed'] ?? json['isIdentityRevealed'] ?? false,
      isAnonymous: json['is_anonymous'] ?? json['isAnonymous'] ?? false,
      likesCount: json['likes_count'] ?? json['likesCount'] ?? 0,
      viewsCount: json['views_count'] ?? json['viewsCount'] ?? 0,
      commentsCount: json['comments_count'] ?? json['commentsCount'] ?? 0,
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      author: json['author'] != null ? User.fromJson(json['author']) : null,
      recipient: json['recipient'] != null ? User.fromJson(json['recipient']) : null,
      comments: json['comments'] != null && json['comments'] is List
          ? (json['comments'] as List).map((c) => ConfessionComment.fromJson(c)).toList()
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
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Confession copyWith({
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
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
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
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
  final String content;
  final User? user;
  final DateTime createdAt;

  ConfessionComment({
    required this.id,
    required this.confessionId,
    required this.userId,
    required this.content,
    this.user,
    required this.createdAt,
  });

  factory ConfessionComment.fromJson(Map<String, dynamic> json) {
    return ConfessionComment(
      id: json['id'] ?? 0,
      confessionId: json['confession_id'] ?? json['confessionId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      content: json['content'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
