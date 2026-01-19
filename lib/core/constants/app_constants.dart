class AppConstants {
  static const String appName = 'Weylo';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'weylo_token';
  static const String userKey = 'weylo_user';
  static const String themeKey = 'weylo_theme';
  static const String languageKey = 'weylo_language';
  static const String anonymousModeKey = 'weylo_anonymous_mode';
  static const String fcmTokenKey = 'weylo_fcm_token';
  static const String onboardingKey = 'weylo_onboarding_completed';

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagesPageSize = 50;

  // Limits
  static const int maxMessageLength = 1000;
  static const int maxConfessionLength = 2000;
  static const int maxBioLength = 150;
  static const int maxGroupMembers = 50;
  static const int maxGroupMembersPremium = 200;

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Story
  static const int storyDurationHours = 24;
  static const int defaultStoryViewDuration = 5;

  // Premium Pricing (FCFA)
  static const int premiumPassPrice = 5000;
  static const int premiumSubscriptionPrice = 450;
  static const int minWithdrawalAmount = 1000;
  static const double platformFeePercent = 5.0;

  // Flame Levels
  static const int yellowFlameThreshold = 2;
  static const int orangeFlameThreshold = 7;
  static const int purpleFlameThreshold = 30;

  // Rate Limits
  static const int messagesRateLimit = 10;
  static const int confessionsRateLimit = 5;
}
