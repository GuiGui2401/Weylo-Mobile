// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String appVersion(Object version) {
    return 'Weylo v$version';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get accountInfo => 'Account information';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get wallet => 'Wallet';

  @override
  String get privacy => 'Privacy';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get premiumSection => 'Premium';

  @override
  String get weyloPremium => 'Weylo Premium';

  @override
  String get premiumSubtitle => 'Unlock exclusive features';

  @override
  String get upgrade => 'UPGRADE';

  @override
  String get mySubscriptions => 'My subscriptions';

  @override
  String get subscriptionsSubtitle => 'Premium pass and targeted subscriptions';

  @override
  String get premiumSettings => 'Premium settings';

  @override
  String get earnings => 'Earnings';

  @override
  String get earningsSubtitle => 'Creator Fund and ad revenue';

  @override
  String get supportSection => 'Support';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get logout => 'Log out';

  @override
  String get logoutTitle => 'Log out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get logoutButton => 'Log out';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get cancel => 'Cancel';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChangedToFrench => 'Language changed to French';

  @override
  String get languageChangedToEnglish => 'Language changed to English';

  @override
  String get accountInfoTitle => 'Account information';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get bio => 'Bio';

  @override
  String get notProvided => 'Not provided';

  @override
  String get signupDate => 'Sign-up date';

  @override
  String errorMessage(Object details) {
    return 'Error: $details';
  }

  @override
  String get profilePostsTab => 'Posts';

  @override
  String get profileLikesTab => 'Likes';

  @override
  String get profileGiftsTab => 'Gifts';

  @override
  String get profileFollowers => 'Followers';

  @override
  String get profileFollowing => 'Following';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileShareProfile => 'Share profile';

  @override
  String get profileNoPostsTitle => 'No posts yet';

  @override
  String get profileNoPostsSubtitle => 'Share your first post!';

  @override
  String get profilePromote => 'Promote';

  @override
  String get profilePromoteSubtitle => 'Increase the visibility of this post';

  @override
  String get profileShare => 'Share';

  @override
  String profileSharePostMessage(Object url) {
    return 'Check out this post on Weylo: $url';
  }

  @override
  String get profileSharePostSubject => 'Weylo post';

  @override
  String get profileDelete => 'Delete';

  @override
  String get profileDeletePostTitle => 'Delete post';

  @override
  String get profileDeletePostConfirm =>
      'Are you sure you want to delete this post? This action cannot be undone.';

  @override
  String get profileDeletePostSuccess => 'Post deleted';

  @override
  String get profileNoLikesTitle => 'No likes';

  @override
  String get profileNoLikesSubtitle => 'Posts you like will appear here';

  @override
  String get profileNoGiftsTitle => 'No gifts received';

  @override
  String get profileNoGiftsSubtitle => 'Gifts you receive will appear here';

  @override
  String get giftDefaultName => 'Gift';

  @override
  String giftFromUser(Object username) {
    return 'From @$username';
  }

  @override
  String get giftAnonymous => 'Anonymous gift';

  @override
  String timeAgoMinutes(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeAgoHours(Object hours) {
    return '${hours}h ago';
  }

  @override
  String timeAgoDays(Object days) {
    return '${days}d ago';
  }

  @override
  String get shareProfileTitle => 'Share your anonymous link';

  @override
  String get shareProfileSubtitle => 'Choose how you want to share your link';

  @override
  String get shareQrCodeTitle => 'Show QR code';

  @override
  String get shareQrCodeSubtitle => 'Great for local testing';

  @override
  String get shareWebLinkTitle => 'Share web link';

  @override
  String shareWebLinkMessage(Object url) {
    return 'Send me an anonymous message on Weylo! $url';
  }

  @override
  String get shareWebLinkSubject => 'My Weylo profile';

  @override
  String get shareAppLinkTitle => 'Copy app link';

  @override
  String get copyToClipboardSuccess => 'Link copied to clipboard';

  @override
  String get scanQrTitle => 'Scan this QR code';

  @override
  String get close => 'Close';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileWalletTitle => 'My wallet';

  @override
  String get profileStatsMessages => 'Messages';

  @override
  String get profileStatsConfessions => 'Confessions';

  @override
  String get profileStatsConversations => 'Conversations';

  @override
  String get profileUpgradeTitle => 'Upgrade to Premium';

  @override
  String get profileUpgradeSubtitle =>
      'See all identities for 5,000 FCFA/month';

  @override
  String get profileMenuEditProfile => 'Edit profile';

  @override
  String get profileMenuMyGifts => 'My gifts';

  @override
  String get profileMenuBlockedUsers => 'Blocked users';

  @override
  String get profileMenuHelpSupport => 'Help & Support';

  @override
  String get profileMenuAbout => 'About';

  @override
  String get profileShareLinkCopied => 'Link copied!';

  @override
  String get userNotFound => 'User not found';

  @override
  String get retry => 'Retry';

  @override
  String get block => 'Block';

  @override
  String get report => 'Report';

  @override
  String get userAnonymous => 'Anonymous';

  @override
  String get profileSubscriptions => 'Following';

  @override
  String get followed => 'Following';

  @override
  String get follow => 'Follow';

  @override
  String get message => 'Message';

  @override
  String get blockUserTitle => 'Block this user';

  @override
  String get blockUserConfirm =>
      'Do you really want to block this user? You will no longer receive messages from them.';

  @override
  String get userBlocked => 'User blocked';

  @override
  String get reportUserTitle => 'Report this user';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportDetailsHint => 'Details (optional)';

  @override
  String get reportSent => 'Report sent';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportHarassment => 'Harassment';

  @override
  String get reportInappropriate => 'Inappropriate';

  @override
  String get reportOther => 'Other';

  @override
  String get giftsPrivate => 'Gifts are private';

  @override
  String get giftsLoadError => 'Error while loading';

  @override
  String giftFromUserLower(Object username) {
    return 'from $username';
  }

  @override
  String identityRevealed(Object name) {
    return 'Identity revealed: $name';
  }

  @override
  String get anonymousUser => 'Anonymous';

  @override
  String toRecipient(Object name) {
    return 'To $name';
  }

  @override
  String get userFallback => 'User';

  @override
  String get messagesTitle => 'Anonymous messages';

  @override
  String get shareLinkSubject => 'My Weylo link';

  @override
  String get inboxTabReceived => 'Received';

  @override
  String get inboxTabSent => 'Sent';

  @override
  String get emptyInboxTitle => 'No messages received';

  @override
  String get emptyInboxSubtitle =>
      'Share your link to receive anonymous messages';

  @override
  String get emptyInboxButton => 'Share my link';

  @override
  String get emptySentTitle => 'No messages sent';

  @override
  String get emptySentSubtitle => 'Send your first anonymous message';

  @override
  String get emptySentButton => 'Send a message';

  @override
  String get sendMessageTitle => 'Send a message';

  @override
  String get newMessageTitle => 'New message';

  @override
  String get searchUserHint => 'Search for a user...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get noUsersAvailable => 'No users available at the moment';

  @override
  String get maskedInfo => 'Information hidden';

  @override
  String get statusNew => 'New';

  @override
  String get statusRevealed => 'Revealed';

  @override
  String get statusAnonymous => 'Anonymous';

  @override
  String get revealedConversations => 'Revealed conversations';

  @override
  String get revealedConversationsHelper =>
      'They have already revealed their identity';

  @override
  String get anonymousConversations => 'Anonymous conversations';

  @override
  String get anonymousConversationsHelper =>
      'Identity hidden despite a conversation';

  @override
  String get noConversation => 'No conversation';

  @override
  String get noConversationHelper => 'No interaction yet';

  @override
  String get selectRecipientError => 'Please select a recipient';

  @override
  String get enterMessageError => 'Please enter a message';

  @override
  String get messageSentSuccess => 'Message sent successfully!';

  @override
  String get anonymousMode => 'Anonymous mode';

  @override
  String get publicMode => 'Public mode';

  @override
  String get anonymousModeSubtitle => 'Your identity will be hidden';

  @override
  String get publicModeSubtitle => 'Your name will be visible';

  @override
  String get messageHint => 'Write your message...';

  @override
  String get voiceMessageRecorded => 'Voice message recorded';

  @override
  String voiceEffectLabel(Object effect) {
    return 'Effect: $effect';
  }

  @override
  String get sendAction => 'Send';

  @override
  String get conversationsTitle => 'Conversations';

  @override
  String get emptyConversationsTitle => 'No conversations';

  @override
  String get emptyConversationsSubtitle => 'Start a conversation with someone';

  @override
  String get searchConversationsHint => 'Search conversations...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get anonymousConversation => 'Anonymous';

  @override
  String get newConversationFab => 'Start a new chat';

  @override
  String get anonymousMessage => 'Anonymous message';

  @override
  String get youLabel => 'You';

  @override
  String get contactLabel => 'Contact';

  @override
  String get replyTo => 'Reply to';

  @override
  String get reply => 'Reply';

  @override
  String audioPlaybackError(Object details) {
    return 'Audio playback error: $details';
  }

  @override
  String videoPlaybackError(Object details) {
    return 'Video playback error: $details';
  }

  @override
  String get attachmentImage => 'Image';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get chatSendError => 'Error sending message';

  @override
  String get chatEmpty => 'No messages. Start the conversation!';

  @override
  String get videoSelected => 'Video selected';

  @override
  String get messageHintShort => 'Message...';

  @override
  String get statusSending => 'Sending';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusRead => 'Read';

  @override
  String get statusUnread => 'Unread';

  @override
  String get statusFailed => 'Error';

  @override
  String get revealIdentityTitle => 'Reveal identity';

  @override
  String revealIdentityPrompt(Object amount) {
    return 'Do you want to pay to reveal this person\'s identity? This costs $amount FCFA.';
  }

  @override
  String get revealIdentitySuccess => 'Identity revealed!';

  @override
  String get revealIdentityAction => 'Reveal';

  @override
  String get sendGift => 'Send a gift';

  @override
  String get blockUser => 'Block';

  @override
  String get deleteConversation => 'Delete conversation';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String get conversationDeleteError => 'Error while deleting';

  @override
  String get messageCopied => 'Message copied';

  @override
  String streakDays(Object days) {
    return '$days day streak';
  }

  @override
  String streakExpiresIn(Object hours, Object minutes) {
    return 'Expires in ${hours}h ${minutes}m';
  }

  @override
  String get streakExpired => 'Streak ended';

  @override
  String get copyAction => 'Copy';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteConversationConfirm =>
      'Are you sure you want to delete this conversation? This action cannot be undone.';

  @override
  String get giftRecipientUnknown => 'Unable to determine the recipient';

  @override
  String get loading => 'Loading...';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get invalidPaymentUrl => 'Invalid payment URL';

  @override
  String pageNotFound(Object uri) {
    return 'Page not found: $uri';
  }

  @override
  String get backToHome => 'Back to home';

  @override
  String get newChatTitle => 'New conversation';

  @override
  String get startAction => 'Start';

  @override
  String get startConversationError => 'Unable to start the conversation';

  @override
  String get addContentOrMediaError => 'Please add content or media';

  @override
  String get postCreatedSuccess => 'Post created successfully!';

  @override
  String postCreateError(Object details) {
    return 'Error while creating: $details';
  }

  @override
  String get createPostTitle => 'New post';

  @override
  String get publishAction => 'Publish';

  @override
  String get confessionHint =>
      'What do you want to confess? (optional with media)';

  @override
  String get photoAction => 'Photo';

  @override
  String get postAnonymousTitle => 'Anonymous post';

  @override
  String get postAnonymousSubtitle => 'Your identity will be hidden';

  @override
  String get postPublicTitle => 'Public post';

  @override
  String get postPublicSubtitle => 'Visible to all users';

  @override
  String get settingsUpdated => 'Settings updated';

  @override
  String blockedUsersWithCount(Object count) {
    return 'Blocked users ($count)';
  }

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get unblockAction => 'Unblock';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String blockedUsersCount(Object count) {
    return '$count user(s)';
  }

  @override
  String get profileVisibilityHeader => 'PROFILE VISIBILITY';

  @override
  String get showNameOnPostsTitle => 'Show my name on my posts';

  @override
  String get showNameOnPostsSubtitle =>
      'Your name will be visible on public posts';

  @override
  String get showPhotoOnPostsTitle => 'Show my photo on my posts';

  @override
  String get showPhotoOnPostsSubtitle => 'Your profile photo will be visible';

  @override
  String get activityHeader => 'ACTIVITY';

  @override
  String get showOnlineStatusTitle => 'Show online status';

  @override
  String get showOnlineStatusSubtitle => 'Others can see when you are online';

  @override
  String get allowAnonymousMessagesTitle => 'Allow anonymous messages';

  @override
  String get allowAnonymousMessagesSubtitle => 'Receive anonymous messages';

  @override
  String get accountManagementHeader => 'ACCOUNT MANAGEMENT';

  @override
  String get deleteAccountTitle => 'Delete my account';

  @override
  String get deleteAccountSubtitle => 'This action cannot be undone';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? All your data will be permanently deleted.';

  @override
  String userUnblocked(Object username) {
    return '@$username has been unblocked';
  }

  @override
  String get legalLastUpdated => 'Last updated: January 1, 2026';

  @override
  String get legalIntro =>
      'By using Weylo, you agree to the following terms...';

  @override
  String get legalBody =>
      '1. Use of the service\n\nWeylo is an anonymous messaging platform. By using this service, you agree to respect other users and not post illegal or offensive content.\n\n2. Privacy\n\nWe respect your privacy. Anonymous messages do not reveal your identity unless you choose to reveal it.\n\n3. Responsibility\n\nYou are responsible for the content you post. Weylo reserves the right to remove any inappropriate content.';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get faqSendAnonymousQuestion => 'How do I send an anonymous message?';

  @override
  String get faqSendAnonymousAnswer =>
      'Go to a user\'s profile and tap \"Send a message\". Your identity will stay hidden unless you choose to reveal it.';

  @override
  String get faqRevealIdentityQuestion =>
      'How can I see who sent me a message?';

  @override
  String get faqRevealIdentityAnswer =>
      'By default, messages are anonymous. You can request identity reveal using credits or a Premium subscription.';

  @override
  String get faqShareLinkQuestion => 'How do I share my link?';

  @override
  String get faqShareLinkAnswer =>
      'Go to your profile and tap \"Share profile\". You can share your link on social networks.';

  @override
  String get faqContactSupportQuestion => 'How do I contact support?';

  @override
  String get faqContactSupportAnswer =>
      'Send an email to support@weylo.app for any question or issue.';

  @override
  String get emailClientError => 'Unable to open the email client';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get appName => 'Weylo';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutTagline =>
      'The anonymous messaging platform\nthat connects people safely.';

  @override
  String get copyrightNotice => '© 2026 Weylo. All rights reserved.';

  @override
  String get takePhotoAction => 'Take a photo';

  @override
  String get chooseFromGalleryAction => 'Choose from gallery';

  @override
  String get deletePhotoAction => 'Delete photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated!';

  @override
  String get profilePhotoDeleted => 'Profile photo deleted!';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get saveAction => 'Save';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get firstNameRequired => 'Please enter your first name';

  @override
  String get bioHint => 'Tell us about yourself...';

  @override
  String get premiumActiveTitle => 'You\'re Premium!';

  @override
  String premiumDaysRemaining(Object days) {
    return '$days days remaining';
  }

  @override
  String get autoRenewTitle => 'Auto-renewal';

  @override
  String get autoRenewSubtitle => 'Automatically renew your subscription';

  @override
  String get premiumUnlockTitle => 'Unlock all features';

  @override
  String get featureRevealTitle => 'See identity';

  @override
  String get featureRevealSubtitle => 'Reveal who sends you messages';

  @override
  String get featureBadgeTitle => 'Premium badge';

  @override
  String get featureBadgeSubtitle => 'Show your Premium status';

  @override
  String get featureNoAdsTitle => 'No ads';

  @override
  String get featureNoAdsSubtitle => 'Enjoy an ad-free experience';

  @override
  String get featureStatsTitle => 'Advanced stats';

  @override
  String get featureStatsSubtitle => 'Analyze your interactions';

  @override
  String get monthlyPlanTitle => 'Monthly';

  @override
  String get monthlyPlanPrice => '2,500 FCFA/month';

  @override
  String get yearlyPlanTitle => 'Yearly';

  @override
  String get yearlyPlanPrice => '20,000 FCFA/year (save 33%)';

  @override
  String get subscribeAction => 'Subscribe';

  @override
  String get premiumActivated => 'Premium subscription activated!';

  @override
  String get autoRenewEnabled => 'Auto-renewal enabled';

  @override
  String get autoRenewDisabled => 'Auto-renewal disabled';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get notificationsMarkedRead => 'All notifications marked as read';

  @override
  String timeAgoMinutesShort(Object minutes) {
    return '${minutes}m';
  }

  @override
  String timeAgoHoursShort(Object hours) {
    return '${hours}h';
  }

  @override
  String timeAgoDaysShort(Object days) {
    return '${days}d';
  }

  @override
  String get storyInvalidUserId => 'Invalid user ID';

  @override
  String get storyNoAvailable => 'No story available';

  @override
  String storyLoadError(Object details) {
    return 'Loading error: $details';
  }

  @override
  String get storyReplySent => 'Reply sent';

  @override
  String get storyReplyError => 'Error sending reply';

  @override
  String get storyNoActive => 'You don\'t have an active story';

  @override
  String get deleteStoryTitle => 'Delete story?';

  @override
  String get deleteStoryConfirm => 'This action cannot be undone.';

  @override
  String get storyDeleted => 'Story deleted';

  @override
  String get storyNoneTitle => 'No story';

  @override
  String get createStoryAction => 'Create a story';

  @override
  String viewsCount(Object count) {
    return '$count views';
  }

  @override
  String get storyViewsEmpty => 'Views will appear here';

  @override
  String get myStoryTitle => 'My story';

  @override
  String get followersTitle => 'Followers';

  @override
  String get followingTitle => 'Following';

  @override
  String get noFollowers => 'No followers';

  @override
  String get noFollowing => 'No following';

  @override
  String get groupTitleFallback => 'Group';

  @override
  String membersCount(Object count) {
    return '$count members';
  }

  @override
  String membersCountWithMax(Object count, Object max) {
    return '$count/$max members';
  }

  @override
  String get groupEmptyTitle => 'No messages';

  @override
  String get groupEmptySubtitle => 'Send a message to start the conversation';

  @override
  String replyToUser(Object name) {
    return 'Reply to $name';
  }

  @override
  String get messageEditMode => 'Editing message';

  @override
  String get editMessageHint => 'Edit message...';

  @override
  String get messageInputHint => 'Write a message...';

  @override
  String get voiceMessageLabel => 'Voice message';

  @override
  String get messageLabel => 'Message';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteMessageTitle => 'Delete message';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get inviteCodeTitle => 'Invite code';

  @override
  String get inviteCodeCopied => 'Code copied!';

  @override
  String get editGroup => 'Edit group';

  @override
  String get groupInfo => 'Group info';

  @override
  String get regenerateInviteCode => 'Regenerate invite code';

  @override
  String newInviteCode(Object code) {
    return 'New code: $code';
  }

  @override
  String get regenerateInviteError => 'Error while regenerating';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteGroupConfirm =>
      'Are you sure you want to delete this group? This action is irreversible. All messages and members will be removed.';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String get inviteCodeShareHint =>
      'Share this code to invite people to join the group.';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get publicGroup => 'Public group';

  @override
  String get privateGroup => 'Private group';

  @override
  String get changeGroupLogo => 'Change logo';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get maxMembersLabel => 'Maximum members';

  @override
  String get publicGroupSubtitle => 'Visible in discovery';

  @override
  String get groupUpdated => 'Group updated!';

  @override
  String get leaveGroupConfirm => 'Are you sure you want to leave this group?';

  @override
  String get leftGroupSuccess => 'You left the group';

  @override
  String get groupMembersTitle => 'Group members';

  @override
  String get noMembers => 'No members';

  @override
  String get roleCreator => 'Creator';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get removeMemberTitle => 'Remove member';

  @override
  String removeMemberConfirm(Object name) {
    return 'Do you want to remove $name from the group?';
  }

  @override
  String get removeAction => 'Remove';

  @override
  String get memberRemoved => 'Member removed';

  @override
  String errorWithDebug(Object error, Object debug) {
    return '$error (debug: $debug)';
  }

  @override
  String get messageEdited => 'Message edited';

  @override
  String get anonymousSender => 'Anonymous sender';

  @override
  String get messageReported => 'Message reported';

  @override
  String get messageNotFound => 'Message not found';

  @override
  String get identityRevealedTitle => 'Identity revealed';

  @override
  String sentByUser(Object name) {
    return 'Sent by $name';
  }

  @override
  String get replyOnceTitle => 'Reply once';

  @override
  String get replyOnceSubtitle =>
      'Reply to this message to start a conversation in the chat.';

  @override
  String get replyPlaceholder => 'Write your reply...';

  @override
  String get replyAndStartConversation => 'Reply and start the conversation';

  @override
  String get sendingLabel => 'Sending...';

  @override
  String get conversationStarted => 'Conversation started! You can now chat.';

  @override
  String get replySent => 'Reply sent';

  @override
  String get revealIdentityCreditsPrompt =>
      'Do you want to spend credits to discover who sent this message? This action is irreversible.';

  @override
  String get supportEmailSubject => 'Support - Weylo';

  @override
  String get loginWelcome => 'Welcome back!';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginIdentifierLabel => 'Username, email, or phone';

  @override
  String get loginIdentifierHint => 'Enter your identifier';

  @override
  String get loginIdentifierRequired => 'Please enter your identifier';

  @override
  String get loginPinLabel => 'PIN';

  @override
  String get loginPinHint => 'Enter your 4-digit PIN';

  @override
  String get loginPinRequired => 'Please enter your PIN';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get loginAction => 'Sign in';

  @override
  String get orSeparator => 'or';

  @override
  String get createAccount => 'Create an account';

  @override
  String get registerTitle => 'Sign up';

  @override
  String registerStepLabel(Object step, Object total) {
    return 'Step $step of $total';
  }

  @override
  String get registerPersonalInfoTitle => 'Personal information';

  @override
  String get registerAccountInfoTitle => 'Your account';

  @override
  String get registerSecurityTitle => 'Security';

  @override
  String get registerNameQuestion => 'What\'s your name?';

  @override
  String get registerNameSubtitle =>
      'Enter your first and last name to personalize your profile';

  @override
  String get firstNameLabelRequired => 'First name *';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get firstNameTooShort => 'First name must be at least 2 characters';

  @override
  String get lastNameLabelOptional => 'Last name (optional)';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get continueAction => 'Continue';

  @override
  String get registerIdentityTitle => 'Create your identity';

  @override
  String get registerIdentitySubtitle =>
      'Choose a unique username and add your contact details';

  @override
  String get usernameLabelRequired => 'Username *';

  @override
  String get usernameHint => 'Choose a unique username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameInvalid => 'Use 3–20 characters (letters, numbers, _)';

  @override
  String get emailLabelOptional => 'Email (optional)';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get phoneLabelOptional => 'Phone (optional)';

  @override
  String get phoneHint => '6XXXXXXXX';

  @override
  String get phoneInvalid => 'Invalid phone number';

  @override
  String get registerSecureTitle => 'Secure your account';

  @override
  String get registerSecureSubtitle =>
      'Create a 4-digit PIN to protect your account';

  @override
  String get pinLabelRequired => 'PIN *';

  @override
  String get pinCreateHint => 'Create a 4-digit PIN';

  @override
  String get pinRequired => 'PIN is required';

  @override
  String get pinInvalid => 'PIN must be exactly 4 digits';

  @override
  String get pinConfirmLabelRequired => 'Confirm PIN *';

  @override
  String get pinConfirmHint => 'Confirm your PIN';

  @override
  String get pinConfirmRequired => 'Please confirm your PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get acceptTermsError => 'Please accept the terms of use';

  @override
  String get acceptTermsPrefix => 'I accept the ';

  @override
  String get acceptTermsLink => 'terms of use';

  @override
  String get acceptPrivacyMiddle => ' and the ';

  @override
  String get acceptPrivacyLink => 'privacy policy';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginLink => 'Sign in';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get verifyIdentityTitle => 'Identity verification';

  @override
  String get verifyIdentitySubtitle =>
      'Enter your phone number and first name to verify your identity';

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get newPasswordSubtitle => 'Create your new password';

  @override
  String get verifyIdentityError => 'Unable to verify your identity';

  @override
  String get resetPasswordError => 'Unable to reset password';

  @override
  String get passwordResetSuccess => 'Password updated successfully';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get firstNameRequiredSimple => 'First name is required';

  @override
  String get verifyIdentityAction => 'Verify my identity';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get newPasswordHint => 'Create a new password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get resetPasswordAction => 'Reset password';

  @override
  String get navMessages => 'Messages';

  @override
  String get navConfessions => 'Confessions';

  @override
  String get navChat => 'Chat';

  @override
  String get navGroups => 'Groups';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchAction => 'Search';

  @override
  String get loadingErrorTitle => 'Loading error';

  @override
  String get feedEmptyTitle => 'No posts yet';

  @override
  String get feedEmptySubtitle => 'Be the first to post!';

  @override
  String sharePostMessage(Object url) {
    return 'Check out this post on Weylo! $url';
  }

  @override
  String get sharePostSubject => 'Weylo post';

  @override
  String get feedPostHint => 'Share what\'s on your mind...';

  @override
  String get videoSelectedLabel => 'Selected video';

  @override
  String get addImageAction => 'Add an image';

  @override
  String get addGifAction => 'Add a GIF';

  @override
  String get addVideoAction => 'Add a video';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityAnonymous => 'Anonymous';

  @override
  String get storyContentRequired => 'Add content to your story.';

  @override
  String get storyPublishedSuccess => 'Story published!';

  @override
  String get storyPublishError => 'Error while publishing';

  @override
  String get connectionError =>
      'Connection error. Check your internet connection.';

  @override
  String get unsupportedFileFormat => 'Unsupported file format';

  @override
  String get fileTooLarge => 'File is too large';

  @override
  String get storyWriteHint => 'Write something...';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get videoLabel => 'Video';

  @override
  String get textLabel => 'Text';

  @override
  String get commentAddError => 'Unable to add the comment';

  @override
  String get viewCommentsAction => 'View comments';

  @override
  String viewCommentsCount(Object count) {
    return 'View $count comment(s)';
  }

  @override
  String get storyReplySendError => 'Error while sending';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get noCommentsTitle => 'No comments';

  @override
  String get noCommentsSubtitle => 'Be the first to comment!';

  @override
  String get commentHint => 'Add a comment...';

  @override
  String get earningsTitle => 'Earnings';

  @override
  String get earningsHistoryTitle => 'Payment history';

  @override
  String get earningsTotalsLabel => 'Total earnings';

  @override
  String get creatorFundLabel => 'Creator Fund';

  @override
  String get adRevenueLabel => 'Ad revenue';

  @override
  String get adsLabel => 'Ads';

  @override
  String get viewsLabel => 'Views';

  @override
  String get likesLabel => 'Likes';

  @override
  String get scoreLabel => 'Score';

  @override
  String poolLabel(Object amount) {
    return 'Pool: $amount';
  }

  @override
  String get noPayoutsTitle => 'No payouts';

  @override
  String get noPayoutsSubtitle => 'Payouts will appear here';

  @override
  String get searchHint => 'Search for people or posts...';

  @override
  String peopleTabCount(Object count) {
    return 'People ($count)';
  }

  @override
  String postsTabCount(Object count) {
    return 'Posts ($count)';
  }

  @override
  String get searchEmptyTitle => 'Search on Weylo';

  @override
  String get searchEmptySubtitle => 'Find people or posts';

  @override
  String get searchNoUsers => 'No users found';

  @override
  String get searchNoPosts => 'No posts found';

  @override
  String get joinGroupTitle => 'Join a group';

  @override
  String get inviteCodeHint => 'Enter the invite code';

  @override
  String get joinGroupSuccess => 'You joined the group!';

  @override
  String get invalidInviteCode => 'Invalid invite code';

  @override
  String get joinAction => 'Join';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get joinWithCodeTooltip => 'Join with a code';

  @override
  String get myGroupsTab => 'My groups';

  @override
  String get discoverTab => 'Discover';

  @override
  String get noGroupsTitle => 'No groups';

  @override
  String get noGroupsDiscoverTitle => 'No groups to discover';

  @override
  String get noGroupsSubtitle => 'Create or join a group to get started';

  @override
  String get noGroupsDiscoverSubtitle =>
      'Come back later to discover new groups';

  @override
  String get createGroupAction => 'Create a group';

  @override
  String joinGroupNameTitle(Object name) {
    return 'Join $name';
  }

  @override
  String groupMembersCount(Object current, Object max) {
    return '$current/$max members';
  }

  @override
  String get joinGroupError => 'Unable to join the group';

  @override
  String get removePhotoAction => 'Remove photo';

  @override
  String get groupCreatedSuccess => 'Group created successfully!';

  @override
  String get createGroupTitle => 'Create a group';

  @override
  String get createAction => 'Create';

  @override
  String get groupNameHint => 'e.g. College friends';

  @override
  String get groupNameRequiredError => 'Group name is required';

  @override
  String groupNameMinLengthError(Object min) {
    return 'Name must be at least $min characters';
  }

  @override
  String get groupDescriptionLabel => 'Description (optional)';

  @override
  String get groupDescriptionHint => 'Describe the purpose of this group...';

  @override
  String get maxMembersTitle => 'Maximum members';

  @override
  String get publicGroupTitle => 'Public group';

  @override
  String get privateGroupSubtitle =>
      'Only people with the invite code can join';

  @override
  String get groupInviteCodeInfo =>
      'An invite code will be generated automatically for your group.';

  @override
  String get walletTitle => 'My wallet';

  @override
  String get availableBalanceLabel => 'Available balance';

  @override
  String get depositAction => 'Deposit';

  @override
  String get withdrawAction => 'Withdraw';

  @override
  String get totalDepositsLabel => 'Total deposits';

  @override
  String get totalWithdrawalsLabel => 'Total withdrawals';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get withdrawalsTab => 'Withdrawals';

  @override
  String get noTransactionsTitle => 'No transactions';

  @override
  String get noTransactionsSubtitle => 'Your transactions will appear here';

  @override
  String get noWithdrawalsTitle => 'No withdrawals';

  @override
  String get noWithdrawalsSubtitle =>
      'Your withdrawal requests will appear here';

  @override
  String get depositTitle => 'Deposit money';

  @override
  String get depositViaLigos => 'Payment via Ligos';

  @override
  String get amountLabel => 'Amount (FCFA)';

  @override
  String get amountExample => 'e.g. 5000';

  @override
  String minimumAmountLabel(Object amount) {
    return 'Minimum amount: $amount';
  }

  @override
  String get depositInitError => 'Error while initializing';

  @override
  String get continueToLigos => 'Continue to Ligos';

  @override
  String get withdrawRequestTitle => 'Request a withdrawal';

  @override
  String get withdrawViaCinetpay => 'Withdrawal via Cinetpay';

  @override
  String get withdrawMethodLabel => 'Withdrawal method';

  @override
  String get mtnMobileMoneyLabel => 'MTN Mobile Money';

  @override
  String get orangeMoneyLabel => 'Orange Money';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => '6XXXXXXXX';

  @override
  String get phoneNumberRequiredError => 'Please enter a phone number';

  @override
  String get withdrawRequestSent => 'Withdrawal request sent';

  @override
  String get withdrawRequestError => 'Error while requesting withdrawal';

  @override
  String get confessionsTitle => 'Confessions';

  @override
  String get receivedTab => 'Received';

  @override
  String get sentTab => 'Sent';

  @override
  String get noConfessionsReceivedTitle => 'No confessions received';

  @override
  String get noConfessionsSentTitle => 'No confessions sent';

  @override
  String get noConfessionsTitle => 'No confessions';

  @override
  String get noConfessionsReceivedSubtitle =>
      'Confessions sent to you will appear here';

  @override
  String get noConfessionsSentSubtitle => 'Your confessions will appear here';

  @override
  String get noConfessionsSubtitle => 'Be the first to post a confession';

  @override
  String get createConfessionAction => 'Create a confession';

  @override
  String loadingErrorMessage(Object details) {
    return 'Loading error: $details';
  }

  @override
  String get postTitle => 'Post';

  @override
  String get postNotFound => 'Post not found';

  @override
  String likesCount(Object count) {
    return '$count like(s)';
  }

  @override
  String commentsCount(Object count) {
    return '$count comment(s)';
  }

  @override
  String get likeAction => 'Like';

  @override
  String get commentAction => 'Comment';

  @override
  String get shareAction => 'Share';

  @override
  String commentsCountTitle(Object count) {
    return 'Comments ($count)';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String revealIdentityCost(Object amount) {
    return 'Cost: $amount';
  }

  @override
  String revealIdentityAmount(Object amount) {
    return '$amount';
  }

  @override
  String get costLabel => 'Cost';

  @override
  String revealIdentitySuccessWithName(Object name) {
    return 'Identity revealed: $name';
  }

  @override
  String get reportPostTitle => 'Report post';

  @override
  String get reportPostPrompt =>
      'Do you want to report this post for inappropriate content?';

  @override
  String get reportPostSuccess => 'Post reported';

  @override
  String get reportAction => 'Report';

  @override
  String get statusLabel => 'Status';

  @override
  String get viewAction => 'View';

  @override
  String get subscriptionsTitle => 'My subscriptions';

  @override
  String get premiumPassTab => 'Premium Pass';

  @override
  String get targetedSubscriptionsTab => 'Targeted';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get historyTitle => 'History';

  @override
  String get noPassTitle => 'No pass';

  @override
  String get noPassSubtitle => 'Your Premium history will appear here';

  @override
  String expiresOnDate(Object date) {
    return 'Expires on $date';
  }

  @override
  String get noSubscriptionsTitle => 'No subscriptions';

  @override
  String get noSubscriptionsSubtitle =>
      'Your targeted subscriptions will appear here';

  @override
  String get noExpiryLabel => 'No expiration date';

  @override
  String get premiumBrandName => 'Weylo Premium';

  @override
  String get subscriptionCancelled => 'Subscription cancelled';

  @override
  String get storyReplyPlaceholder => 'Reply to the story...';

  @override
  String get visibleLabel => 'Visible';

  @override
  String get storyReplyHint => 'Write your reply...';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get viewMoreAction => 'See more';

  @override
  String get viewLessAction => 'See less';

  @override
  String confessionForUser(Object name) {
    return 'For $name';
  }

  @override
  String get boostAction => 'Boost';

  @override
  String get postDeletedSuccess => 'Post deleted';

  @override
  String get giftSentTitle => 'Gift sent!';

  @override
  String giftSentMessage(Object gift, Object username) {
    return 'Your $gift was sent to $username';
  }

  @override
  String sendGiftToUser(Object username) {
    return 'Send a gift to $username';
  }

  @override
  String get sendAnonymouslyLabel => 'Send anonymously';

  @override
  String sendGiftAction(Object gift) {
    return 'Send $gift';
  }

  @override
  String get selectGiftLabel => 'Select a gift';

  @override
  String get promoObjectiveBoostTitle => 'Boost my account';

  @override
  String get promoObjectiveBoostDescription =>
      'Increase your visibility and gain followers';

  @override
  String get promoObjectiveFollowers => 'Gain followers';

  @override
  String get promoObjectiveVisibility => 'More visibility';

  @override
  String get promoObjectiveEngagement => 'More engagement';

  @override
  String get promoObjectiveSalesTitle => 'Get sales';

  @override
  String get promoObjectiveSalesDescription =>
      'Convert your visitors into customers';

  @override
  String get promoObjectiveSellProducts => 'Sell products';

  @override
  String get promoObjectiveSellServices => 'Sell services';

  @override
  String get promoObjectivePromoteEvent => 'Promote an event';

  @override
  String get promoObjectiveProspectsTitle => 'Get prospects';

  @override
  String get promoObjectiveProspectsDescription =>
      'Generate qualified leads for your business';

  @override
  String get promoObjectiveCollectContacts => 'Collect contacts';

  @override
  String get promoObjectiveReceiveMessages => 'Receive messages';

  @override
  String get promoObjectiveWebsiteVisits => 'Website visits';

  @override
  String get promoStepGoalTitle => 'Choose your goal';

  @override
  String get promoStepDetailTitle => 'Refine your goal';

  @override
  String get promoStepPackTitle => 'Choose your pack';

  @override
  String get promoStepConfirmTitle => 'Confirmation';

  @override
  String get promotePostTitle => 'Promote';

  @override
  String get promoGoalQuestion => 'What\'s your goal?';

  @override
  String get promoGoalSubtitle => 'Select the primary goal of your promotion';

  @override
  String get promoSelectObjectiveFirst => 'Please select a goal first';

  @override
  String get promoDetailSubtitle => 'Choose what you want to achieve';

  @override
  String get promoPackTitle => 'Choose your pack';

  @override
  String get promoPackSubtitle =>
      'Select the duration and budget for your promotion';

  @override
  String promoReachBoost(Object boost) {
    return '+$boost% reach';
  }

  @override
  String promoBoostDuration(Object hours) {
    return '${hours}h boost';
  }

  @override
  String get promoNonFollowersIncluded => 'Non-followers included';

  @override
  String get promoDetailedStats => 'Detailed stats';

  @override
  String get popularLabel => 'POPULAR';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryObjectiveLabel => 'Goal';

  @override
  String get summaryPackLabel => 'Pack';

  @override
  String get summaryDurationLabel => 'Duration';

  @override
  String summaryDurationValue(Object hours) {
    return '$hours hours';
  }

  @override
  String get summaryReachBoostLabel => 'Reach boost';

  @override
  String summaryReachBoostValue(Object boost) {
    return '+$boost%';
  }

  @override
  String get summaryTotalLabel => 'Total';

  @override
  String get promoImportantInfoTitle => 'Important information';

  @override
  String get promoImportantInfoBody =>
      '• The boost will start immediately after payment\n• The boost duration is guaranteed\n• Statistics will be available in real time\n• No refunds after activation';

  @override
  String get termsPrefix => 'I accept the ';

  @override
  String get termsPromotionLabel => 'promotion terms';

  @override
  String get termsMiddle => ' and confirm that my post complies with the ';

  @override
  String get termsCommunityLabel => 'community rules';

  @override
  String get processingLabel => 'Processing...';

  @override
  String payAmountLabel(Object amount) {
    return 'Pay $amount';
  }

  @override
  String get payAction => 'Pay';

  @override
  String get promotePostSuccess => 'Post promoted successfully!';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get errorOccurredTitle => 'An error occurred';

  @override
  String get retryLaterSubtitle => 'Please try again later';

  @override
  String get verifiedAccountTooltip => 'Verified account';

  @override
  String get premiumAccountTooltip => 'Premium account';

  @override
  String get openAction => 'Open';

  @override
  String get myStatusLabel => 'My status';

  @override
  String get meLabel => 'Me';

  @override
  String get navFeedLabel => 'Feed';

  @override
  String get navMessagesLabel => 'Messages';

  @override
  String get navChatLabel => 'Chat';

  @override
  String get navGroupsLabel => 'Groups';

  @override
  String get navProfileLabel => 'Profile';

  @override
  String get pressToRecordLabel => 'Tap to record';

  @override
  String effectLabel(Object effect) {
    return 'Effect: $effect';
  }
}
