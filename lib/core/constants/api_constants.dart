class ApiConstants {
  // static const String baseUrl = 'https://weylo-adminpanel.space/api/v1'; // Production
  // static const String wsUrl = 'wss://weylo-adminpanel.space'; // Production
  //static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Local Development (Android Emulator)
  //static const String wsUrl = 'wss://10.0.2.2:8000'; // Local Development (Android Emulator)

  static const String baseUrl ='http://172.20.10.3:8000/api/v1'; // Local Development (Physical Device)
  static const String wsUrl ='ws://172.20.10.3:8080'; // Local Development (Physical Device)

  //static const String baseUrl ='http://192.168.1.177:8000/api/v1'; // Local Development (Physical Device)
  //static const String wsUrl ='ws://192.168.1.177:8080'; // Local Development (Physical Device)

  // Reverb/Pusher Configuration
  // static const String reverbHost = 'weylo-adminpanel.space'; // Production
  // static const int reverbPort = 443; // Production
  // static const String reverbAppKey = '1425cdd3ef7425fa6746d2895a233e52'; // Production
  // static const String reverbScheme = 'https';  // Production
  //static const String reverbHost = '10.0.2.2'; // Local Development (Android Emulator)
  static const String reverbAppId = 'Weylo-app'; // Local Development
  static const String reverbHost = '172.20.10.3'; // Local Development
  //static const String reverbHost = '192.168.1.177'; // Local Development
  static const int reverbPort = 6001; // Local Development
  static const String reverbAppKey = '1425cdd3ef7425fa6746d2895a233e52'; // Local Development
  static const String reverbAppSecret =
      '0684dbd3bef3b2550a2be1d8fea7e1d6464e19c8a3e925064f9fac17d4f60077'; // Local Development
  static const String reverbScheme = 'http'; // Local Development

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String me = '/auth/me';
  static const String verifyIdentity = '/auth/verify-identity';
  static const String resetPasswordByPhone = '/auth/reset-password-by-phone';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyPhone = '/auth/verify-phone';
  static const String updatePinDirect = '/auth/update-pin-direct';

  // Users
  static const String users = '/users';
  static const int usersMaxPerPage = 50;
  static const String userDashboard = '/users/dashboard';
  static const String userStats = '/users/stats';
  static const String userProfile = '/users/profile';
  static const String userSettings = '/users/settings';
  static const String userPassword = '/users/password';
  static const String userAvatar = '/users/avatar';
  static const String userCover = '/users/cover';
  static const String userRecommendationsFromContacts =
      '/users/recommendations/contacts';
  static const String userFcmToken = '/users/fcm-token';
  static const String userBlocked = '/users/blocked';
  static const String userByUsername = '/users/by-username';
  static const String userById = '/users/by-id';
  static const String userShareLink = '/users/share-link';

  // Follows
  static String userFollow(String username) => '/users/$username/follow';
  static String userFollowers(String username) => '/users/$username/followers';
  static String userFollowing(String username) => '/users/$username/following';
  static String userFollowStatus(String username) =>
      '/users/$username/follow-status';
  static String userReport(String username) => '/users/$username/report';
  static String userBlock(String username) => '/users/$username/block';

  // Messages
  static const String messages = '/messages';
  static const String messagesSent = '/messages/sent';
  static const String messagesStats = '/messages/stats';
  static const String messagesReadAll = '/messages/read-all';
  static String messageById(int id) => '/messages/$id'; // DJSTAR7
  static String messageDelete(int id) => '/messages/$id'; // DJSTAR7
  static String messageSend(String username) => '/messages/send/$username';
  static String messageReveal(int id) => '/messages/$id/reveal';
  static String messageStartConversation(int id) =>
      '/messages/$id/start-conversation';
  static String messageReport(int id) => '/messages/$id/report';

  // Confessions
  static const String confessions = '/confessions';
  static const String confessionsReceived = '/confessions/received';
  static const String confessionsSent = '/confessions/sent';
  static const String confessionsLiked =
      '/confessions/liked'; // DJSTAR7 - Liste des confessions aimées
  static const String confessionsStats = '/confessions/stats';
  static String confessionLike(int id) => '/confessions/$id/like';
  static String userConfessions(String username) =>
      '/users/$username/confessions'; // DJSTAR7 - Confessions d'un utilisateur par username
  static String confessionComments(int id) => '/confessions/$id/comments';
  static String confessionReveal(int id) => '/confessions/$id/reveal';
  static String confessionReport(int id) => '/confessions/$id/report';

  // Chat
  static const String chatConversations = '/chat/conversations';
  static const String chatPresence = '/chat/presence';
  static const String chatUserStatus = '/chat/user-status';
  static const String chatStats = '/chat/stats';
  static String chatConversation(int conversationId) =>
      '/chat/conversations/$conversationId'; // DJSTAR7
  static String chatMessages(int conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String chatRead(int conversationId) =>
      '/chat/conversations/$conversationId/read';
  static String chatReveal(int conversationId) =>
      '/chat/conversations/$conversationId/reveal';
  static String chatGift(int conversationId) =>
      '/chat/conversations/$conversationId/gift';
  static String chatDelete(int conversationId) =>
      '/chat/conversations/$conversationId'; // DJSTAR7
  static const String broadcastingAuth = '/broadcasting/auth';

  // Groups
  static const String groups = '/groups';
  static const String groupsDiscover = '/groups/discover';
  static const String groupsJoin = '/groups/join';
  static const String groupsStats = '/groups/stats';
  static String groupById(int groupId) => '/groups/$groupId'; // DJSTAR7
  static String groupUpdate(int groupId) => '/groups/$groupId'; // DJSTAR7
  static String groupDelete(int groupId) => '/groups/$groupId'; // DJSTAR7
  static String groupMessages(int groupId) => '/groups/$groupId/messages';
  static String groupMembers(int groupId) => '/groups/$groupId/members';
  static String groupRemoveMember(int groupId, int memberId) =>
      '/groups/$groupId/members/$memberId'; // DJSTAR7
  static String groupUpdateMemberRole(int groupId, int memberId) =>
      '/groups/$groupId/members/$memberId/role'; // DJSTAR7
  static String groupRegenerateInvite(int groupId) =>
      '/groups/$groupId/regenerate-invite'; // DJSTAR7
  static String groupLeave(int groupId) => '/groups/$groupId/leave';
  static String groupRead(int groupId) => '/groups/$groupId/read';

  // Gifts
  static const String gifts = '/gifts';
  static const String giftsReceived = '/gifts/received';
  static const String giftsSent = '/gifts/sent';
  static const String giftsStats = '/gifts/stats';
  static const String giftsSend = '/gifts/send';
  static const String giftCategories = '/gift-categories';
  static String giftsByCategory(int categoryId) =>
      '/gift-categories/$categoryId/gifts';

  // Premium
  static const String premium = '/premium';
  static const String premiumSubscriptions = '/premium/subscriptions';
  static const String premiumSubscriptionsActive =
      '/premium/subscriptions/active';
  static const String premiumPricing = '/premium/pricing';
  static const String premiumCheck = '/premium/check';
  static String premiumSubscribeMessage(int messageId) =>
      '/premium/subscribe/message/$messageId';
  static String premiumSubscribeConversation(int conversationId) =>
      '/premium/subscribe/conversation/$conversationId';
  static String premiumSubscribeStory(int storyId) =>
      '/premium/subscribe/story/$storyId';

  // Premium Pass
  static const String premiumPass = '/premium-pass';
  static const String premiumPassInfo = '/premium-pass/info';
  static const String premiumPassStatus = '/premium-pass/status';
  static const String premiumPassPurchase = '/premium-pass/purchase';
  static const String premiumPassRenew = '/premium-pass/renew';
  static const String premiumPassHistory = '/premium-pass/history';
  static String premiumPassCanViewIdentity(int userId) =>
      '/premium-pass/can-view-identity/$userId';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletStats = '/wallet/stats';
  static const String walletWithdrawalMethods = '/wallet/withdrawal-methods';
  static const String walletDeposit = '/wallet/deposit/initiate';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletWithdrawals = '/wallet/withdrawals';

  // Stories
  static const String stories = '/stories';
  static const String storiesMyStories = '/stories/my-stories';
  static const String storiesStats = '/stories/stats';
  static String storiesByUser(String username) => '/stories/user/$username';
  static String storiesByUserId(int userId) => '/stories/user-by-id/$userId';
  static String storyView(int storyId) => '/stories/$storyId/view';
  static String storyViewers(int storyId) => '/stories/$storyId/viewers';
  static String storyReplies(int storyId) => '/stories/$storyId/replies';

  // Post Promotions
  static const String promotionsPricing = '/promotions/pricing';
  static const String myPromotions = '/promotions/my-promotions';
  static const String promotionsBalance = '/promotions/balance';
  static const String promotionsTopup = '/promotions/topup';
  static String promoteConfession(int confessionId) => '/promotions/confessions/$confessionId';
  static String cancelPromotion(int promotionId) => '/promotions/$promotionId';
  static String promotionStats(int promotionId) =>
      '/promotions/$promotionId/stats';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';

  // Payments
  static const String cinetpayDeposit = '/cinetpay/deposit/initiate';
  static const String cinetpayCheckStatus = '/cinetpay/check-status';
  static const String paymentProviders = '/payment-providers/config';
  static const String paymentStatus = '/payments/status';

  // Reveal Identity
  static const String revealIdentityPrice = '/reveal-identity/price';
  static String revealIdentityInitiate(int messageId) =>
      '/reveal-identity/messages/$messageId/initiate';
  static String revealIdentityStatus(int messageId) =>
      '/reveal-identity/messages/$messageId/status';
  static String revealIdentityConversationInitiate(int conversationId) =>
      '/reveal-identity/conversations/$conversationId/initiate'; // DJSTAR7
  static String revealIdentityConversationStatus(int conversationId) =>
      '/reveal-identity/conversations/$conversationId/status'; // DJSTAR7

  // Settings
  static const String settingsPublic = '/settings/public';
  static const String settingsRevealPrice = '/settings/reveal-price';

  // Monetization
  static const String monetization = '/monetization';
  static const String monetizationOverview = '/monetization/overview';
  static const String monetizationPayouts = '/monetization/payouts';
  static const String monetizationSettings = '/monetization/settings';

  // Legal
  static const String legalPages = '/legal-pages';

  // Maintenance
  static const String maintenanceStatus = '/maintenance/status';
}
