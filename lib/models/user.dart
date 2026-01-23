/// Parse une valeur en double, qu'elle soit String, int, double ou null
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class User {
  final int id;
  final String firstName;
  final String? lastName;
  final String username;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? coverUrl;
  final String? bio;
  final double walletBalance;
  final bool isPremium;
  final bool isVerified;
  final DateTime? premiumExpiresAt;
  final bool isBanned;
  final String role;
  final String? fcmToken;
  final UserSettings? settings;
  final bool isIdentityRevealed;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int followersCount;
  final int followingCount;
  final bool? isFollowing;
  final bool? isFollowedBy;
  final int? confessionsCount;
  final int? messagesReceivedCount;
  final String? fullNameOverride;

  User({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.username,
    this.email,
    this.phone,
    this.avatar,
    this.coverUrl,
    this.bio,
    this.walletBalance = 0.0,
    this.isPremium = false,
    this.isVerified = false,
    this.premiumExpiresAt,
    this.isBanned = false,
    this.role = 'user',
    this.fcmToken,
    this.settings,
    this.isIdentityRevealed = false,
    this.isOnline = false,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing,
    this.isFollowedBy,
    this.confessionsCount,
    this.messagesReceivedCount,
    this.fullNameOverride,
  });

  String get fullName {
    if (fullNameOverride != null && fullNameOverride!.isNotEmpty) {
      return fullNameOverride!;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (firstName.isNotEmpty) {
      return firstName;
    }
    return username;
  }

  String get initials {
    String result = '';
    if (firstName.isNotEmpty) result += firstName[0].toUpperCase();
    if (lastName != null && lastName!.isNotEmpty) {
      result += lastName![0].toUpperCase();
    }
    return result.isEmpty ? '?' : result;
  }

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isModerator => role == 'moderator' || isAdmin;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName:
          json['first_name'] ??
          json['firstName'] ??
          json['full_name'] ??
          json['fullName'] ??
          '',
      lastName: json['last_name'] ?? json['lastName'],
      username: json['username'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'] ?? json['avatar_url'],
      coverUrl: json['cover_url'] ?? json['cover'],
      bio: json['bio'],
      walletBalance: _parseDouble(
        json['wallet_balance'] ?? json['walletBalance'],
      ),
      isPremium: json['is_premium'] ?? json['isPremium'] ?? false,
      isVerified:
          json['is_verified'] ??
          json['isVerified'] ??
          json['is_premium'] ??
          json['isPremium'] ??
          false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'])
          : null,
      isBanned: json['is_banned'] ?? json['isBanned'] ?? false,
      role: json['role'] ?? 'user',
      fcmToken: json['fcm_token'] ?? json['fcmToken'],
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'])
          : null,
      isIdentityRevealed:
          json['is_identity_revealed'] ?? json['isIdentityRevealed'] ?? false,
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      followersCount: json['followers_count'] ?? json['followersCount'] ?? 0,
      followingCount: json['following_count'] ?? json['followingCount'] ?? 0,
      isFollowing: json['is_following'] ?? json['isFollowing'],
      isFollowedBy: json['is_followed_by'] ?? json['isFollowedBy'],
      confessionsCount: json['confessions_count'] ?? json['confessionsCount'],
      messagesReceivedCount:
          json['messages_received_count'] ?? json['messagesReceivedCount'],
      fullNameOverride: json['full_name'] ?? json['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'cover_url': coverUrl,
      'bio': bio,
      'wallet_balance': walletBalance,
      'is_premium': isPremium,
      'is_verified': isVerified,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'is_banned': isBanned,
      'role': role,
      'fcm_token': fcmToken,
      'settings': settings?.toJson(),
      'is_identity_revealed': isIdentityRevealed,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
      'is_followed_by': isFollowedBy,
      'confessions_count': confessionsCount,
      'messages_received_count': messagesReceivedCount,
      'full_name': fullNameOverride,
    };
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? avatar,
    String? coverUrl,
    String? bio,
    double? walletBalance,
    bool? isPremium,
    bool? isVerified,
    DateTime? premiumExpiresAt,
    bool? isBanned,
    String? role,
    String? fcmToken,
    UserSettings? settings,
    bool? isIdentityRevealed,
    bool? isOnline,
    DateTime? lastSeenAt,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    bool? isFollowedBy,
    int? confessionsCount,
    int? messagesReceivedCount,
    String? fullNameOverride,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      walletBalance: walletBalance ?? this.walletBalance,
      isPremium: isPremium ?? this.isPremium,
      isVerified: isVerified ?? this.isVerified,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      isBanned: isBanned ?? this.isBanned,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      settings: settings ?? this.settings,
      isIdentityRevealed: isIdentityRevealed ?? this.isIdentityRevealed,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      confessionsCount: confessionsCount ?? this.confessionsCount,
      messagesReceivedCount:
          messagesReceivedCount ?? this.messagesReceivedCount,
      fullNameOverride: fullNameOverride ?? this.fullNameOverride,
    );
  }
}

class UserSettings {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool showOnlineStatus;
  final bool allowAnonymousMessages;
  final bool showNameOnPosts;
  final bool showPhotoOnPosts;
  final String language;
  final String theme;

  UserSettings({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.showOnlineStatus = true,
    this.allowAnonymousMessages = false,
    this.showNameOnPosts = true,
    this.showPhotoOnPosts = true,
    this.language = 'fr',
    this.theme = 'system',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      showOnlineStatus: json['show_online_status'] ?? true,
      allowAnonymousMessages: json['allow_anonymous_messages'] ?? false,
      showNameOnPosts: json['show_name_on_posts'] ?? true,
      showPhotoOnPosts: json['show_photo_on_posts'] ?? true,
      language: json['language'] ?? 'fr',
      theme: json['theme'] ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'show_online_status': showOnlineStatus,
      'allow_anonymous_messages': allowAnonymousMessages,
      'show_name_on_posts': showNameOnPosts,
      'show_photo_on_posts': showPhotoOnPosts,
      'language': language,
      'theme': theme,
    };
  }
}
