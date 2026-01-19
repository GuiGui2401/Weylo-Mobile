import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Weylo v{version}'**
  String appVersion(Object version);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInfo;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @premiumSection.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumSection;

  /// No description provided for @weyloPremium.
  ///
  /// In en, this message translates to:
  /// **'Weylo Premium'**
  String get weyloPremium;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock exclusive features'**
  String get premiumSubtitle;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE'**
  String get upgrade;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My subscriptions'**
  String get mySubscriptions;

  /// No description provided for @subscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium pass and targeted subscriptions'**
  String get subscriptionsSubtitle;

  /// No description provided for @premiumSettings.
  ///
  /// In en, this message translates to:
  /// **'Premium settings'**
  String get premiumSettings;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @earningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creator Fund and ad revenue'**
  String get earningsSubtitle;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChangedToFrench.
  ///
  /// In en, this message translates to:
  /// **'Language changed to French'**
  String get languageChangedToFrench;

  /// No description provided for @languageChangedToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChangedToEnglish;

  /// No description provided for @accountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInfoTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @signupDate.
  ///
  /// In en, this message translates to:
  /// **'Sign-up date'**
  String get signupDate;

  /// Error message with error details
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorMessage(Object details);

  /// No description provided for @profilePostsTab.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profilePostsTab;

  /// No description provided for @profileLikesTab.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get profileLikesTab;

  /// No description provided for @profileGiftsTab.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get profileGiftsTab;

  /// No description provided for @profileFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowers;

  /// No description provided for @profileFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowing;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @profileShareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get profileShareProfile;

  /// No description provided for @profileNoPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get profileNoPostsTitle;

  /// No description provided for @profileNoPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your first post!'**
  String get profileNoPostsSubtitle;

  /// No description provided for @profilePromote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get profilePromote;

  /// No description provided for @profilePromoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Increase the visibility of this post'**
  String get profilePromoteSubtitle;

  /// No description provided for @profileShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileShare;

  /// Share post message
  ///
  /// In en, this message translates to:
  /// **'Check out this post on Weylo: {url}'**
  String profileSharePostMessage(Object url);

  /// No description provided for @profileSharePostSubject.
  ///
  /// In en, this message translates to:
  /// **'Weylo post'**
  String get profileSharePostSubject;

  /// No description provided for @profileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDelete;

  /// No description provided for @profileDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get profileDeletePostTitle;

  /// No description provided for @profileDeletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post? This action cannot be undone.'**
  String get profileDeletePostConfirm;

  /// No description provided for @profileDeletePostSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get profileDeletePostSuccess;

  /// No description provided for @profileNoLikesTitle.
  ///
  /// In en, this message translates to:
  /// **'No likes'**
  String get profileNoLikesTitle;

  /// No description provided for @profileNoLikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Posts you like will appear here'**
  String get profileNoLikesSubtitle;

  /// No description provided for @profileNoGiftsTitle.
  ///
  /// In en, this message translates to:
  /// **'No gifts received'**
  String get profileNoGiftsTitle;

  /// No description provided for @profileNoGiftsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gifts you receive will appear here'**
  String get profileNoGiftsSubtitle;

  /// No description provided for @giftDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giftDefaultName;

  /// Gift sender
  ///
  /// In en, this message translates to:
  /// **'From @{username}'**
  String giftFromUser(Object username);

  /// No description provided for @giftAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous gift'**
  String get giftAnonymous;

  /// Time ago in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeAgoMinutes(Object minutes);

  /// Time ago in hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeAgoHours(Object hours);

  /// Time ago in days
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeAgoDays(Object days);

  /// No description provided for @shareProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your anonymous link'**
  String get shareProfileTitle;

  /// No description provided for @shareProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to share your link'**
  String get shareProfileSubtitle;

  /// No description provided for @shareQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get shareQrCodeTitle;

  /// No description provided for @shareQrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Great for local testing'**
  String get shareQrCodeSubtitle;

  /// No description provided for @shareWebLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Share web link'**
  String get shareWebLinkTitle;

  /// Share web link message
  ///
  /// In en, this message translates to:
  /// **'Send me an anonymous message on Weylo! {url}'**
  String shareWebLinkMessage(Object url);

  /// No description provided for @shareWebLinkSubject.
  ///
  /// In en, this message translates to:
  /// **'My Weylo profile'**
  String get shareWebLinkSubject;

  /// No description provided for @shareAppLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy app link'**
  String get shareAppLinkTitle;

  /// No description provided for @copyToClipboardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get copyToClipboardSuccess;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code'**
  String get scanQrTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get profileWalletTitle;

  /// No description provided for @profileStatsMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileStatsMessages;

  /// No description provided for @profileStatsConfessions.
  ///
  /// In en, this message translates to:
  /// **'Confessions'**
  String get profileStatsConfessions;

  /// No description provided for @profileStatsConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get profileStatsConversations;

  /// No description provided for @profileUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get profileUpgradeTitle;

  /// No description provided for @profileUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See all identities for 5,000 FCFA/month'**
  String get profileUpgradeSubtitle;

  /// No description provided for @profileMenuEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileMenuEditProfile;

  /// No description provided for @profileMenuMyGifts.
  ///
  /// In en, this message translates to:
  /// **'My gifts'**
  String get profileMenuMyGifts;

  /// No description provided for @profileMenuBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get profileMenuBlockedUsers;

  /// No description provided for @profileMenuHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileMenuHelpSupport;

  /// No description provided for @profileMenuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileMenuAbout;

  /// No description provided for @profileShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get profileShareLinkCopied;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @userAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get userAnonymous;

  /// No description provided for @profileSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileSubscriptions;

  /// No description provided for @followed.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followed;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user'**
  String get blockUserTitle;

  /// Block user confirmation
  ///
  /// In en, this message translates to:
  /// **'Do you really want to block this user? You will no longer receive messages from them.'**
  String get blockUserConfirm;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this user'**
  String get reportUserTitle;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReason;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetailsHint;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportHarassment;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get reportInappropriate;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @giftsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Gifts are private'**
  String get giftsPrivate;

  /// No description provided for @giftsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error while loading'**
  String get giftsLoadError;

  /// Gift sender lowercase
  ///
  /// In en, this message translates to:
  /// **'from {username}'**
  String giftFromUserLower(Object username);

  /// Identity revealed label
  ///
  /// In en, this message translates to:
  /// **'Identity revealed: {name}'**
  String identityRevealed(Object name);

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousUser;

  /// Message recipient label
  ///
  /// In en, this message translates to:
  /// **'To {name}'**
  String toRecipient(Object name);

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous messages'**
  String get messagesTitle;

  /// No description provided for @shareLinkSubject.
  ///
  /// In en, this message translates to:
  /// **'My Weylo link'**
  String get shareLinkSubject;

  /// No description provided for @inboxTabReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get inboxTabReceived;

  /// No description provided for @inboxTabSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get inboxTabSent;

  /// No description provided for @emptyInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages received'**
  String get emptyInboxTitle;

  /// No description provided for @emptyInboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your link to receive anonymous messages'**
  String get emptyInboxSubtitle;

  /// No description provided for @emptyInboxButton.
  ///
  /// In en, this message translates to:
  /// **'Share my link'**
  String get emptyInboxButton;

  /// No description provided for @emptySentTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages sent'**
  String get emptySentTitle;

  /// No description provided for @emptySentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send your first anonymous message'**
  String get emptySentSubtitle;

  /// No description provided for @emptySentButton.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get emptySentButton;

  /// No description provided for @sendMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get sendMessageTitle;

  /// No description provided for @newMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageTitle;

  /// No description provided for @searchUserHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a user...'**
  String get searchUserHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @noUsersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No users available at the moment'**
  String get noUsersAvailable;

  /// No description provided for @maskedInfo.
  ///
  /// In en, this message translates to:
  /// **'Information hidden'**
  String get maskedInfo;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusRevealed.
  ///
  /// In en, this message translates to:
  /// **'Revealed'**
  String get statusRevealed;

  /// No description provided for @statusAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get statusAnonymous;

  /// No description provided for @revealedConversations.
  ///
  /// In en, this message translates to:
  /// **'Revealed conversations'**
  String get revealedConversations;

  /// No description provided for @revealedConversationsHelper.
  ///
  /// In en, this message translates to:
  /// **'They have already revealed their identity'**
  String get revealedConversationsHelper;

  /// No description provided for @anonymousConversations.
  ///
  /// In en, this message translates to:
  /// **'Anonymous conversations'**
  String get anonymousConversations;

  /// No description provided for @anonymousConversationsHelper.
  ///
  /// In en, this message translates to:
  /// **'Identity hidden despite a conversation'**
  String get anonymousConversationsHelper;

  /// No description provided for @noConversation.
  ///
  /// In en, this message translates to:
  /// **'No conversation'**
  String get noConversation;

  /// No description provided for @noConversationHelper.
  ///
  /// In en, this message translates to:
  /// **'No interaction yet'**
  String get noConversationHelper;

  /// No description provided for @selectRecipientError.
  ///
  /// In en, this message translates to:
  /// **'Please select a recipient'**
  String get selectRecipientError;

  /// No description provided for @enterMessageError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get enterMessageError;

  /// No description provided for @messageSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully!'**
  String get messageSentSuccess;

  /// No description provided for @anonymousMode.
  ///
  /// In en, this message translates to:
  /// **'Anonymous mode'**
  String get anonymousMode;

  /// No description provided for @publicMode.
  ///
  /// In en, this message translates to:
  /// **'Public mode'**
  String get publicMode;

  /// No description provided for @anonymousModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity will be hidden'**
  String get anonymousModeSubtitle;

  /// No description provided for @publicModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name will be visible'**
  String get publicModeSubtitle;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get messageHint;

  /// No description provided for @voiceMessageRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice message recorded'**
  String get voiceMessageRecorded;

  /// Voice effect label
  ///
  /// In en, this message translates to:
  /// **'Effect: {effect}'**
  String voiceEffectLabel(Object effect);

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendAction;

  /// No description provided for @conversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversationsTitle;

  /// No description provided for @emptyConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get emptyConversationsTitle;

  /// No description provided for @emptyConversationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with someone'**
  String get emptyConversationsSubtitle;

  /// No description provided for @searchConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversationsHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @anonymousConversation.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousConversation;

  /// No description provided for @newConversationFab.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat'**
  String get newConversationFab;

  /// No description provided for @anonymousMessage.
  ///
  /// In en, this message translates to:
  /// **'Anonymous message'**
  String get anonymousMessage;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to'**
  String get replyTo;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @audioPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Audio playback error: {details}'**
  String audioPlaybackError(Object details);

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Video playback error: {details}'**
  String videoPlaybackError(Object details);

  /// No description provided for @attachmentImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get attachmentImage;

  /// No description provided for @attachmentVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attachmentVideo;

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending message'**
  String get chatSendError;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages. Start the conversation!'**
  String get chatEmpty;

  /// No description provided for @videoSelected.
  ///
  /// In en, this message translates to:
  /// **'Video selected'**
  String get videoSelected;

  /// No description provided for @messageHintShort.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHintShort;

  /// No description provided for @statusSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get statusSending;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get statusRead;

  /// No description provided for @statusUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get statusUnread;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusFailed;

  /// No description provided for @revealIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal identity'**
  String get revealIdentityTitle;

  /// Reveal identity prompt
  ///
  /// In en, this message translates to:
  /// **'Do you want to pay to reveal this person\'s identity? This costs {amount} FCFA.'**
  String revealIdentityPrompt(Object amount);

  /// No description provided for @revealIdentitySuccess.
  ///
  /// In en, this message translates to:
  /// **'Identity revealed!'**
  String get revealIdentitySuccess;

  /// No description provided for @revealIdentityAction.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get revealIdentityAction;

  /// No description provided for @sendGift.
  ///
  /// In en, this message translates to:
  /// **'Send a gift'**
  String get sendGift;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deleteConversation;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @conversationDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error while deleting'**
  String get conversationDeleteError;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// Streak days
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String streakDays(Object days);

  /// Label showing how much time is left before the streak expires
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours}h {minutes}m'**
  String streakExpiresIn(Object hours, Object minutes);

  /// No description provided for @streakExpired.
  ///
  /// In en, this message translates to:
  /// **'Streak ended'**
  String get streakExpired;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// Delete conversation confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This action cannot be undone.'**
  String get deleteConversationConfirm;

  /// No description provided for @giftRecipientUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine the recipient'**
  String get giftRecipientUnknown;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @invalidPaymentUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid payment URL'**
  String get invalidPaymentUrl;

  /// Page not found message
  ///
  /// In en, this message translates to:
  /// **'Page not found: {uri}'**
  String pageNotFound(Object uri);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @newChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newChatTitle;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startAction;

  /// No description provided for @startConversationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the conversation'**
  String get startConversationError;

  /// No description provided for @addContentOrMediaError.
  ///
  /// In en, this message translates to:
  /// **'Please add content or media'**
  String get addContentOrMediaError;

  /// No description provided for @postCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get postCreatedSuccess;

  /// Post creation error
  ///
  /// In en, this message translates to:
  /// **'Error while creating: {details}'**
  String postCreateError(Object details);

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get createPostTitle;

  /// No description provided for @publishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishAction;

  /// No description provided for @confessionHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to confess? (optional with media)'**
  String get confessionHint;

  /// No description provided for @photoAction.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoAction;

  /// No description provided for @postAnonymousTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous post'**
  String get postAnonymousTitle;

  /// No description provided for @postAnonymousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity will be hidden'**
  String get postAnonymousSubtitle;

  /// No description provided for @postPublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Public post'**
  String get postPublicTitle;

  /// No description provided for @postPublicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible to all users'**
  String get postPublicSubtitle;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// Blocked users with count
  ///
  /// In en, this message translates to:
  /// **'Blocked users ({count})'**
  String blockedUsersWithCount(Object count);

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// Blocked users count
  ///
  /// In en, this message translates to:
  /// **'{count} user(s)'**
  String blockedUsersCount(Object count);

  /// No description provided for @profileVisibilityHeader.
  ///
  /// In en, this message translates to:
  /// **'PROFILE VISIBILITY'**
  String get profileVisibilityHeader;

  /// No description provided for @showNameOnPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show my name on my posts'**
  String get showNameOnPostsTitle;

  /// No description provided for @showNameOnPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name will be visible on public posts'**
  String get showNameOnPostsSubtitle;

  /// No description provided for @showPhotoOnPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show my photo on my posts'**
  String get showPhotoOnPostsTitle;

  /// No description provided for @showPhotoOnPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile photo will be visible'**
  String get showPhotoOnPostsSubtitle;

  /// No description provided for @activityHeader.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get activityHeader;

  /// No description provided for @showOnlineStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Show online status'**
  String get showOnlineStatusTitle;

  /// No description provided for @showOnlineStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others can see when you are online'**
  String get showOnlineStatusSubtitle;

  /// No description provided for @allowAnonymousMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow anonymous messages'**
  String get allowAnonymousMessagesTitle;

  /// No description provided for @allowAnonymousMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive anonymous messages'**
  String get allowAnonymousMessagesSubtitle;

  /// No description provided for @accountManagementHeader.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT MANAGEMENT'**
  String get accountManagementHeader;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? All your data will be permanently deleted.'**
  String get deleteAccountConfirm;

  /// User unblocked message
  ///
  /// In en, this message translates to:
  /// **'@{username} has been unblocked'**
  String userUnblocked(Object username);

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: January 1, 2026'**
  String get legalLastUpdated;

  /// No description provided for @legalIntro.
  ///
  /// In en, this message translates to:
  /// **'By using Weylo, you agree to the following terms...'**
  String get legalIntro;

  /// No description provided for @legalBody.
  ///
  /// In en, this message translates to:
  /// **'1. Use of the service\n\nWeylo is an anonymous messaging platform. By using this service, you agree to respect other users and not post illegal or offensive content.\n\n2. Privacy\n\nWe respect your privacy. Anonymous messages do not reveal your identity unless you choose to reveal it.\n\n3. Responsibility\n\nYou are responsible for the content you post. Weylo reserves the right to remove any inappropriate content.'**
  String get legalBody;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqTitle;

  /// No description provided for @faqSendAnonymousQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I send an anonymous message?'**
  String get faqSendAnonymousQuestion;

  /// No description provided for @faqSendAnonymousAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to a user\'s profile and tap \"Send a message\". Your identity will stay hidden unless you choose to reveal it.'**
  String get faqSendAnonymousAnswer;

  /// No description provided for @faqRevealIdentityQuestion.
  ///
  /// In en, this message translates to:
  /// **'How can I see who sent me a message?'**
  String get faqRevealIdentityQuestion;

  /// No description provided for @faqRevealIdentityAnswer.
  ///
  /// In en, this message translates to:
  /// **'By default, messages are anonymous. You can request identity reveal using credits or a Premium subscription.'**
  String get faqRevealIdentityAnswer;

  /// No description provided for @faqShareLinkQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I share my link?'**
  String get faqShareLinkQuestion;

  /// No description provided for @faqShareLinkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to your profile and tap \"Share profile\". You can share your link on social networks.'**
  String get faqShareLinkAnswer;

  /// No description provided for @faqContactSupportQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get faqContactSupportQuestion;

  /// No description provided for @faqContactSupportAnswer.
  ///
  /// In en, this message translates to:
  /// **'Send an email to support@weylo.app for any question or issue.'**
  String get faqContactSupportAnswer;

  /// No description provided for @emailClientError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the email client'**
  String get emailClientError;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Weylo'**
  String get appName;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'The anonymous messaging platform\nthat connects people safely.'**
  String get aboutTagline;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Weylo. All rights reserved.'**
  String get copyrightNotice;

  /// No description provided for @takePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhotoAction;

  /// No description provided for @chooseFromGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGalleryAction;

  /// No description provided for @deletePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get deletePhotoAction;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile photo deleted!'**
  String get profilePhotoDeleted;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get firstNameRequired;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get bioHint;

  /// No description provided for @premiumActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Premium!'**
  String get premiumActiveTitle;

  /// Days remaining
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String premiumDaysRemaining(Object days);

  /// No description provided for @autoRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal'**
  String get autoRenewTitle;

  /// No description provided for @autoRenewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically renew your subscription'**
  String get autoRenewSubtitle;

  /// No description provided for @premiumUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get premiumUnlockTitle;

  /// No description provided for @featureRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'See identity'**
  String get featureRevealTitle;

  /// No description provided for @featureRevealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal who sends you messages'**
  String get featureRevealSubtitle;

  /// No description provided for @featureBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium badge'**
  String get featureBadgeTitle;

  /// No description provided for @featureBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your Premium status'**
  String get featureBadgeSubtitle;

  /// No description provided for @featureNoAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get featureNoAdsTitle;

  /// No description provided for @featureNoAdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy an ad-free experience'**
  String get featureNoAdsSubtitle;

  /// No description provided for @featureStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced stats'**
  String get featureStatsTitle;

  /// No description provided for @featureStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze your interactions'**
  String get featureStatsSubtitle;

  /// No description provided for @monthlyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyPlanTitle;

  /// No description provided for @monthlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'2,500 FCFA/month'**
  String get monthlyPlanPrice;

  /// No description provided for @yearlyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyPlanTitle;

  /// No description provided for @yearlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'20,000 FCFA/year (save 33%)'**
  String get yearlyPlanPrice;

  /// No description provided for @subscribeAction.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeAction;

  /// No description provided for @premiumActivated.
  ///
  /// In en, this message translates to:
  /// **'Premium subscription activated!'**
  String get premiumActivated;

  /// No description provided for @autoRenewEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal enabled'**
  String get autoRenewEnabled;

  /// No description provided for @autoRenewDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal disabled'**
  String get autoRenewDisabled;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @notificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkedRead;

  /// Minutes ago short
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String timeAgoMinutesShort(Object minutes);

  /// Hours ago short
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String timeAgoHoursShort(Object hours);

  /// Days ago short
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String timeAgoDaysShort(Object days);

  /// No description provided for @storyInvalidUserId.
  ///
  /// In en, this message translates to:
  /// **'Invalid user ID'**
  String get storyInvalidUserId;

  /// No description provided for @storyNoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No story available'**
  String get storyNoAvailable;

  /// Story load error
  ///
  /// In en, this message translates to:
  /// **'Loading error: {details}'**
  String storyLoadError(Object details);

  /// No description provided for @storyReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get storyReplySent;

  /// No description provided for @storyReplyError.
  ///
  /// In en, this message translates to:
  /// **'Error sending reply'**
  String get storyReplyError;

  /// No description provided for @storyNoActive.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an active story'**
  String get storyNoActive;

  /// No description provided for @deleteStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete story?'**
  String get deleteStoryTitle;

  /// No description provided for @deleteStoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteStoryConfirm;

  /// No description provided for @storyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Story deleted'**
  String get storyDeleted;

  /// No description provided for @storyNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No story'**
  String get storyNoneTitle;

  /// No description provided for @createStoryAction.
  ///
  /// In en, this message translates to:
  /// **'Create a story'**
  String get createStoryAction;

  /// Views count
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String viewsCount(Object count);

  /// No description provided for @storyViewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Views will appear here'**
  String get storyViewsEmpty;

  /// No description provided for @myStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My story'**
  String get myStoryTitle;

  /// No description provided for @followersTitle.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersTitle;

  /// No description provided for @followingTitle.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTitle;

  /// No description provided for @noFollowers.
  ///
  /// In en, this message translates to:
  /// **'No followers'**
  String get noFollowers;

  /// No description provided for @noFollowing.
  ///
  /// In en, this message translates to:
  /// **'No following'**
  String get noFollowing;

  /// No description provided for @groupTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupTitleFallback;

  /// Members count
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(Object count);

  /// Members count with max
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} members'**
  String membersCountWithMax(Object count, Object max);

  /// No description provided for @groupEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get groupEmptyTitle;

  /// No description provided for @groupEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get groupEmptySubtitle;

  /// Reply to user
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyToUser(Object name);

  /// No description provided for @messageEditMode.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get messageEditMode;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Edit message...'**
  String get editMessageHint;

  /// No description provided for @messageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get messageInputHint;

  /// No description provided for @voiceMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessageLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get inviteCodeCopied;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group info'**
  String get groupInfo;

  /// No description provided for @regenerateInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Regenerate invite code'**
  String get regenerateInviteCode;

  /// New invite code
  ///
  /// In en, this message translates to:
  /// **'New code: {code}'**
  String newInviteCode(Object code);

  /// No description provided for @regenerateInviteError.
  ///
  /// In en, this message translates to:
  /// **'Error while regenerating'**
  String get regenerateInviteError;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group? This action is irreversible. All messages and members will be removed.'**
  String get deleteGroupConfirm;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupDeleted;

  /// No description provided for @inviteCodeShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code to invite people to join the group.'**
  String get inviteCodeShareHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @publicGroup.
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get publicGroup;

  /// No description provided for @privateGroup.
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get privateGroup;

  /// No description provided for @changeGroupLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get changeGroupLogo;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @maxMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum members'**
  String get maxMembersLabel;

  /// No description provided for @publicGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible in discovery'**
  String get publicGroupSubtitle;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated!'**
  String get groupUpdated;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get leaveGroupConfirm;

  /// No description provided for @leftGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'You left the group'**
  String get leftGroupSuccess;

  /// No description provided for @groupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Group members'**
  String get groupMembersTitle;

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// No description provided for @roleCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get roleCreator;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMemberTitle;

  /// Remove member confirmation
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove {name} from the group?'**
  String removeMemberConfirm(Object name);

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// Error with debug
  ///
  /// In en, this message translates to:
  /// **'{error} (debug: {debug})'**
  String errorWithDebug(Object error, Object debug);

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'Message edited'**
  String get messageEdited;

  /// No description provided for @anonymousSender.
  ///
  /// In en, this message translates to:
  /// **'Anonymous sender'**
  String get anonymousSender;

  /// No description provided for @messageReported.
  ///
  /// In en, this message translates to:
  /// **'Message reported'**
  String get messageReported;

  /// No description provided for @messageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get messageNotFound;

  /// No description provided for @identityRevealedTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity revealed'**
  String get identityRevealedTitle;

  /// Sent by user
  ///
  /// In en, this message translates to:
  /// **'Sent by {name}'**
  String sentByUser(Object name);

  /// No description provided for @replyOnceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply once'**
  String get replyOnceTitle;

  /// No description provided for @replyOnceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to this message to start a conversation in the chat.'**
  String get replyOnceSubtitle;

  /// No description provided for @replyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get replyPlaceholder;

  /// No description provided for @replyAndStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Reply and start the conversation'**
  String get replyAndStartConversation;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingLabel;

  /// No description provided for @conversationStarted.
  ///
  /// In en, this message translates to:
  /// **'Conversation started! You can now chat.'**
  String get conversationStarted;

  /// No description provided for @replySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get replySent;

  /// No description provided for @revealIdentityCreditsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to spend credits to discover who sent this message? This action is irreversible.'**
  String get revealIdentityCreditsPrompt;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Support - Weylo'**
  String get supportEmailSubject;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Username, email, or phone'**
  String get loginIdentifierLabel;

  /// No description provided for @loginIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your identifier'**
  String get loginIdentifierHint;

  /// No description provided for @loginIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your identifier'**
  String get loginIdentifierRequired;

  /// No description provided for @loginPinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get loginPinLabel;

  /// No description provided for @loginPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get loginPinHint;

  /// No description provided for @loginPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your PIN'**
  String get loginPinRequired;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAction;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerTitle;

  /// No description provided for @registerStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String registerStepLabel(Object step, Object total);

  /// No description provided for @registerPersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get registerPersonalInfoTitle;

  /// No description provided for @registerAccountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get registerAccountInfoTitle;

  /// No description provided for @registerSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get registerSecurityTitle;

  /// No description provided for @registerNameQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get registerNameQuestion;

  /// No description provided for @registerNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your first and last name to personalize your profile'**
  String get registerNameSubtitle;

  /// No description provided for @firstNameLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'First name *'**
  String get firstNameLabelRequired;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// No description provided for @firstNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'First name must be at least 2 characters'**
  String get firstNameTooShort;

  /// No description provided for @lastNameLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Last name (optional)'**
  String get lastNameLabelOptional;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNameHint;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @registerIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your identity'**
  String get registerIdentityTitle;

  /// No description provided for @registerIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username and add your contact details'**
  String get registerIdentitySubtitle;

  /// No description provided for @usernameLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get usernameLabelRequired;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 characters (letters, numbers, _)'**
  String get usernameInvalid;

  /// No description provided for @emailLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailLabelOptional;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalid;

  /// No description provided for @phoneLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneLabelOptional;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'6XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneInvalid;

  /// No description provided for @registerSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get registerSecureTitle;

  /// No description provided for @registerSecureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN to protect your account'**
  String get registerSecureSubtitle;

  /// No description provided for @pinLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN *'**
  String get pinLabelRequired;

  /// No description provided for @pinCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN'**
  String get pinCreateHint;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN is required'**
  String get pinRequired;

  /// No description provided for @pinInvalid.
  ///
  /// In en, this message translates to:
  /// **'PIN must be exactly 4 digits'**
  String get pinInvalid;

  /// No description provided for @pinConfirmLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN *'**
  String get pinConfirmLabelRequired;

  /// No description provided for @pinConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get pinConfirmHint;

  /// No description provided for @pinConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your PIN'**
  String get pinConfirmRequired;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @acceptTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms of use'**
  String get acceptTermsError;

  /// No description provided for @acceptTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get acceptTermsPrefix;

  /// No description provided for @acceptTermsLink.
  ///
  /// In en, this message translates to:
  /// **'terms of use'**
  String get acceptTermsLink;

  /// No description provided for @acceptPrivacyMiddle.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get acceptPrivacyMiddle;

  /// No description provided for @acceptPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get acceptPrivacyLink;

  /// No description provided for @createMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get createMyAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @verifyIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get verifyIdentityTitle;

  /// No description provided for @verifyIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and first name to verify your identity'**
  String get verifyIdentitySubtitle;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your new password'**
  String get newPasswordSubtitle;

  /// No description provided for @verifyIdentityError.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify your identity'**
  String get verifyIdentityError;

  /// No description provided for @resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset password'**
  String get resetPasswordError;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordResetSuccess;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @firstNameRequiredSimple.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequiredSimple;

  /// No description provided for @verifyIdentityAction.
  ///
  /// In en, this message translates to:
  /// **'Verify my identity'**
  String get verifyIdentityAction;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get newPasswordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordAction;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navConfessions.
  ///
  /// In en, this message translates to:
  /// **'Confessions'**
  String get navConfessions;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @loadingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingErrorTitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post!'**
  String get feedEmptySubtitle;

  /// Share post message
  ///
  /// In en, this message translates to:
  /// **'Check out this post on Weylo! {url}'**
  String sharePostMessage(Object url);

  /// No description provided for @sharePostSubject.
  ///
  /// In en, this message translates to:
  /// **'Weylo post'**
  String get sharePostSubject;

  /// No description provided for @feedPostHint.
  ///
  /// In en, this message translates to:
  /// **'Share what\'s on your mind...'**
  String get feedPostHint;

  /// No description provided for @videoSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected video'**
  String get videoSelectedLabel;

  /// No description provided for @addImageAction.
  ///
  /// In en, this message translates to:
  /// **'Add an image'**
  String get addImageAction;

  /// No description provided for @addGifAction.
  ///
  /// In en, this message translates to:
  /// **'Add a GIF'**
  String get addGifAction;

  /// No description provided for @addVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Add a video'**
  String get addVideoAction;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @visibilityAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get visibilityAnonymous;

  /// No description provided for @storyContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Add content to your story.'**
  String get storyContentRequired;

  /// No description provided for @storyPublishedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Story published!'**
  String get storyPublishedSuccess;

  /// No description provided for @storyPublishError.
  ///
  /// In en, this message translates to:
  /// **'Error while publishing'**
  String get storyPublishError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet connection.'**
  String get connectionError;

  /// No description provided for @unsupportedFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format'**
  String get unsupportedFileFormat;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large'**
  String get fileTooLarge;

  /// No description provided for @storyWriteHint.
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get storyWriteHint;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @textLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textLabel;

  /// No description provided for @commentAddError.
  ///
  /// In en, this message translates to:
  /// **'Unable to add the comment'**
  String get commentAddError;

  /// No description provided for @viewCommentsAction.
  ///
  /// In en, this message translates to:
  /// **'View comments'**
  String get viewCommentsAction;

  /// View comments count
  ///
  /// In en, this message translates to:
  /// **'View {count} comment(s)'**
  String viewCommentsCount(Object count);

  /// No description provided for @storyReplySendError.
  ///
  /// In en, this message translates to:
  /// **'Error while sending'**
  String get storyReplySendError;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @noCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get noCommentsTitle;

  /// No description provided for @noCommentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get noCommentsSubtitle;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentHint;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @earningsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get earningsHistoryTitle;

  /// No description provided for @earningsTotalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total earnings'**
  String get earningsTotalsLabel;

  /// No description provided for @creatorFundLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator Fund'**
  String get creatorFundLabel;

  /// No description provided for @adRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad revenue'**
  String get adRevenueLabel;

  /// No description provided for @adsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get adsLabel;

  /// No description provided for @viewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsLabel;

  /// No description provided for @likesLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// Pool label
  ///
  /// In en, this message translates to:
  /// **'Pool: {amount}'**
  String poolLabel(Object amount);

  /// No description provided for @noPayoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'No payouts'**
  String get noPayoutsTitle;

  /// No description provided for @noPayoutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payouts will appear here'**
  String get noPayoutsSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for people or posts...'**
  String get searchHint;

  /// People tab count
  ///
  /// In en, this message translates to:
  /// **'People ({count})'**
  String peopleTabCount(Object count);

  /// Posts tab count
  ///
  /// In en, this message translates to:
  /// **'Posts ({count})'**
  String postsTabCount(Object count);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search on Weylo'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find people or posts'**
  String get searchEmptySubtitle;

  /// No description provided for @searchNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get searchNoUsers;

  /// No description provided for @searchNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get searchNoPosts;

  /// No description provided for @joinGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get joinGroupTitle;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code'**
  String get inviteCodeHint;

  /// No description provided for @joinGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'You joined the group!'**
  String get joinGroupSuccess;

  /// No description provided for @invalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get invalidInviteCode;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinAction;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @joinWithCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCodeTooltip;

  /// No description provided for @myGroupsTab.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroupsTab;

  /// No description provided for @discoverTab.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTab;

  /// No description provided for @noGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get noGroupsTitle;

  /// No description provided for @noGroupsDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups to discover'**
  String get noGroupsDiscoverTitle;

  /// No description provided for @noGroupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or join a group to get started'**
  String get noGroupsSubtitle;

  /// No description provided for @noGroupsDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Come back later to discover new groups'**
  String get noGroupsDiscoverSubtitle;

  /// No description provided for @createGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get createGroupAction;

  /// Join group by name
  ///
  /// In en, this message translates to:
  /// **'Join {name}'**
  String joinGroupNameTitle(Object name);

  /// Group members count
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} members'**
  String groupMembersCount(Object current, Object max);

  /// No description provided for @joinGroupError.
  ///
  /// In en, this message translates to:
  /// **'Unable to join the group'**
  String get joinGroupError;

  /// No description provided for @removePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoAction;

  /// No description provided for @groupCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully!'**
  String get groupCreatedSuccess;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get createGroupTitle;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. College friends'**
  String get groupNameHint;

  /// No description provided for @groupNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequiredError;

  /// Group name min length error
  ///
  /// In en, this message translates to:
  /// **'Name must be at least {min} characters'**
  String groupNameMinLengthError(Object min);

  /// No description provided for @groupDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get groupDescriptionLabel;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the purpose of this group...'**
  String get groupDescriptionHint;

  /// No description provided for @maxMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum members'**
  String get maxMembersTitle;

  /// No description provided for @publicGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get publicGroupTitle;

  /// No description provided for @privateGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only people with the invite code can join'**
  String get privateGroupSubtitle;

  /// No description provided for @groupInviteCodeInfo.
  ///
  /// In en, this message translates to:
  /// **'An invite code will be generated automatically for your group.'**
  String get groupInviteCodeInfo;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get walletTitle;

  /// No description provided for @availableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalanceLabel;

  /// No description provided for @depositAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositAction;

  /// No description provided for @withdrawAction.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawAction;

  /// No description provided for @totalDepositsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total deposits'**
  String get totalDepositsLabel;

  /// No description provided for @totalWithdrawalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total withdrawals'**
  String get totalWithdrawalsLabel;

  /// No description provided for @transactionsTab.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTab;

  /// No description provided for @withdrawalsTab.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawalsTab;

  /// No description provided for @noTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactionsTitle;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here'**
  String get noTransactionsSubtitle;

  /// No description provided for @noWithdrawalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No withdrawals'**
  String get noWithdrawalsTitle;

  /// No description provided for @noWithdrawalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal requests will appear here'**
  String get noWithdrawalsSubtitle;

  /// No description provided for @depositTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit money'**
  String get depositTitle;

  /// No description provided for @depositViaLigos.
  ///
  /// In en, this message translates to:
  /// **'Payment via Ligos'**
  String get depositViaLigos;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (FCFA)'**
  String get amountLabel;

  /// No description provided for @amountExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5000'**
  String get amountExample;

  /// Minimum amount label
  ///
  /// In en, this message translates to:
  /// **'Minimum amount: {amount}'**
  String minimumAmountLabel(Object amount);

  /// No description provided for @depositInitError.
  ///
  /// In en, this message translates to:
  /// **'Error while initializing'**
  String get depositInitError;

  /// No description provided for @continueToLigos.
  ///
  /// In en, this message translates to:
  /// **'Continue to Ligos'**
  String get continueToLigos;

  /// No description provided for @withdrawRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a withdrawal'**
  String get withdrawRequestTitle;

  /// No description provided for @withdrawViaCinetpay.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal via Cinetpay'**
  String get withdrawViaCinetpay;

  /// No description provided for @withdrawMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal method'**
  String get withdrawMethodLabel;

  /// No description provided for @mtnMobileMoneyLabel.
  ///
  /// In en, this message translates to:
  /// **'MTN Mobile Money'**
  String get mtnMobileMoneyLabel;

  /// No description provided for @orangeMoneyLabel.
  ///
  /// In en, this message translates to:
  /// **'Orange Money'**
  String get orangeMoneyLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'6XXXXXXXX'**
  String get phoneNumberHint;

  /// No description provided for @phoneNumberRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get phoneNumberRequiredError;

  /// No description provided for @withdrawRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request sent'**
  String get withdrawRequestSent;

  /// No description provided for @withdrawRequestError.
  ///
  /// In en, this message translates to:
  /// **'Error while requesting withdrawal'**
  String get withdrawRequestError;

  /// No description provided for @confessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confessions'**
  String get confessionsTitle;

  /// No description provided for @receivedTab.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedTab;

  /// No description provided for @sentTab.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentTab;

  /// No description provided for @noConfessionsReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'No confessions received'**
  String get noConfessionsReceivedTitle;

  /// No description provided for @noConfessionsSentTitle.
  ///
  /// In en, this message translates to:
  /// **'No confessions sent'**
  String get noConfessionsSentTitle;

  /// No description provided for @noConfessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No confessions'**
  String get noConfessionsTitle;

  /// No description provided for @noConfessionsReceivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confessions sent to you will appear here'**
  String get noConfessionsReceivedSubtitle;

  /// No description provided for @noConfessionsSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your confessions will appear here'**
  String get noConfessionsSentSubtitle;

  /// No description provided for @noConfessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post a confession'**
  String get noConfessionsSubtitle;

  /// No description provided for @createConfessionAction.
  ///
  /// In en, this message translates to:
  /// **'Create a confession'**
  String get createConfessionAction;

  /// Loading error with details
  ///
  /// In en, this message translates to:
  /// **'Loading error: {details}'**
  String loadingErrorMessage(Object details);

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postTitle;

  /// No description provided for @postNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found'**
  String get postNotFound;

  /// Likes count
  ///
  /// In en, this message translates to:
  /// **'{count} like(s)'**
  String likesCount(Object count);

  /// Comments count
  ///
  /// In en, this message translates to:
  /// **'{count} comment(s)'**
  String commentsCount(Object count);

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeAction;

  /// No description provided for @commentAction.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// Comments section title
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsCountTitle(Object count);

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// Reveal identity cost
  ///
  /// In en, this message translates to:
  /// **'Cost: {amount}'**
  String revealIdentityCost(Object amount);

  /// Reveal identity amount
  ///
  /// In en, this message translates to:
  /// **'{amount}'**
  String revealIdentityAmount(Object amount);

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// Reveal identity success with name
  ///
  /// In en, this message translates to:
  /// **'Identity revealed: {name}'**
  String revealIdentitySuccessWithName(Object name);

  /// No description provided for @reportPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPostTitle;

  /// No description provided for @reportPostPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to report this post for inappropriate content?'**
  String get reportPostPrompt;

  /// No description provided for @reportPostSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post reported'**
  String get reportPostSuccess;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My subscriptions'**
  String get subscriptionsTitle;

  /// No description provided for @premiumPassTab.
  ///
  /// In en, this message translates to:
  /// **'Premium Pass'**
  String get premiumPassTab;

  /// No description provided for @targetedSubscriptionsTab.
  ///
  /// In en, this message translates to:
  /// **'Targeted'**
  String get targetedSubscriptionsTab;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @noPassTitle.
  ///
  /// In en, this message translates to:
  /// **'No pass'**
  String get noPassTitle;

  /// No description provided for @noPassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Premium history will appear here'**
  String get noPassSubtitle;

  /// Expires on date
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String expiresOnDate(Object date);

  /// No description provided for @noSubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get noSubscriptionsTitle;

  /// No description provided for @noSubscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your targeted subscriptions will appear here'**
  String get noSubscriptionsSubtitle;

  /// No description provided for @noExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'No expiration date'**
  String get noExpiryLabel;

  /// No description provided for @premiumBrandName.
  ///
  /// In en, this message translates to:
  /// **'Weylo Premium'**
  String get premiumBrandName;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @storyReplyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Reply to the story...'**
  String get storyReplyPlaceholder;

  /// No description provided for @visibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visibleLabel;

  /// No description provided for @storyReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get storyReplyHint;

  /// No description provided for @visibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibilityPrivate;

  /// No description provided for @viewMoreAction.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get viewMoreAction;

  /// No description provided for @viewLessAction.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get viewLessAction;

  /// Confession recipient
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String confessionForUser(Object name);

  /// No description provided for @boostAction.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boostAction;

  /// No description provided for @postDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeletedSuccess;

  /// No description provided for @giftSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift sent!'**
  String get giftSentTitle;

  /// Gift sent message
  ///
  /// In en, this message translates to:
  /// **'Your {gift} was sent to {username}'**
  String giftSentMessage(Object gift, Object username);

  /// Send gift to user
  ///
  /// In en, this message translates to:
  /// **'Send a gift to {username}'**
  String sendGiftToUser(Object username);

  /// No description provided for @sendAnonymouslyLabel.
  ///
  /// In en, this message translates to:
  /// **'Send anonymously'**
  String get sendAnonymouslyLabel;

  /// Send gift action
  ///
  /// In en, this message translates to:
  /// **'Send {gift}'**
  String sendGiftAction(Object gift);

  /// No description provided for @selectGiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Select a gift'**
  String get selectGiftLabel;

  /// No description provided for @promoObjectiveBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Boost my account'**
  String get promoObjectiveBoostTitle;

  /// No description provided for @promoObjectiveBoostDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase your visibility and gain followers'**
  String get promoObjectiveBoostDescription;

  /// No description provided for @promoObjectiveFollowers.
  ///
  /// In en, this message translates to:
  /// **'Gain followers'**
  String get promoObjectiveFollowers;

  /// No description provided for @promoObjectiveVisibility.
  ///
  /// In en, this message translates to:
  /// **'More visibility'**
  String get promoObjectiveVisibility;

  /// No description provided for @promoObjectiveEngagement.
  ///
  /// In en, this message translates to:
  /// **'More engagement'**
  String get promoObjectiveEngagement;

  /// No description provided for @promoObjectiveSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Get sales'**
  String get promoObjectiveSalesTitle;

  /// No description provided for @promoObjectiveSalesDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert your visitors into customers'**
  String get promoObjectiveSalesDescription;

  /// No description provided for @promoObjectiveSellProducts.
  ///
  /// In en, this message translates to:
  /// **'Sell products'**
  String get promoObjectiveSellProducts;

  /// No description provided for @promoObjectiveSellServices.
  ///
  /// In en, this message translates to:
  /// **'Sell services'**
  String get promoObjectiveSellServices;

  /// No description provided for @promoObjectivePromoteEvent.
  ///
  /// In en, this message translates to:
  /// **'Promote an event'**
  String get promoObjectivePromoteEvent;

  /// No description provided for @promoObjectiveProspectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Get prospects'**
  String get promoObjectiveProspectsTitle;

  /// No description provided for @promoObjectiveProspectsDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate qualified leads for your business'**
  String get promoObjectiveProspectsDescription;

  /// No description provided for @promoObjectiveCollectContacts.
  ///
  /// In en, this message translates to:
  /// **'Collect contacts'**
  String get promoObjectiveCollectContacts;

  /// No description provided for @promoObjectiveReceiveMessages.
  ///
  /// In en, this message translates to:
  /// **'Receive messages'**
  String get promoObjectiveReceiveMessages;

  /// No description provided for @promoObjectiveWebsiteVisits.
  ///
  /// In en, this message translates to:
  /// **'Website visits'**
  String get promoObjectiveWebsiteVisits;

  /// No description provided for @promoStepGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your goal'**
  String get promoStepGoalTitle;

  /// No description provided for @promoStepDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Refine your goal'**
  String get promoStepDetailTitle;

  /// No description provided for @promoStepPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your pack'**
  String get promoStepPackTitle;

  /// No description provided for @promoStepConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get promoStepConfirmTitle;

  /// No description provided for @promotePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get promotePostTitle;

  /// No description provided for @promoGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get promoGoalQuestion;

  /// No description provided for @promoGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the primary goal of your promotion'**
  String get promoGoalSubtitle;

  /// No description provided for @promoSelectObjectiveFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a goal first'**
  String get promoSelectObjectiveFirst;

  /// No description provided for @promoDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to achieve'**
  String get promoDetailSubtitle;

  /// No description provided for @promoPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your pack'**
  String get promoPackTitle;

  /// No description provided for @promoPackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the duration and budget for your promotion'**
  String get promoPackSubtitle;

  /// Reach boost
  ///
  /// In en, this message translates to:
  /// **'+{boost}% reach'**
  String promoReachBoost(Object boost);

  /// Boost duration
  ///
  /// In en, this message translates to:
  /// **'{hours}h boost'**
  String promoBoostDuration(Object hours);

  /// No description provided for @promoNonFollowersIncluded.
  ///
  /// In en, this message translates to:
  /// **'Non-followers included'**
  String get promoNonFollowersIncluded;

  /// No description provided for @promoDetailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed stats'**
  String get promoDetailedStats;

  /// No description provided for @popularLabel.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popularLabel;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @summaryObjectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get summaryObjectiveLabel;

  /// No description provided for @summaryPackLabel.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get summaryPackLabel;

  /// No description provided for @summaryDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get summaryDurationLabel;

  /// Summary duration value
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String summaryDurationValue(Object hours);

  /// No description provided for @summaryReachBoostLabel.
  ///
  /// In en, this message translates to:
  /// **'Reach boost'**
  String get summaryReachBoostLabel;

  /// Summary reach boost value
  ///
  /// In en, this message translates to:
  /// **'+{boost}%'**
  String summaryReachBoostValue(Object boost);

  /// No description provided for @summaryTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get summaryTotalLabel;

  /// No description provided for @promoImportantInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Important information'**
  String get promoImportantInfoTitle;

  /// No description provided for @promoImportantInfoBody.
  ///
  /// In en, this message translates to:
  /// **'• The boost will start immediately after payment\n• The boost duration is guaranteed\n• Statistics will be available in real time\n• No refunds after activation'**
  String get promoImportantInfoBody;

  /// No description provided for @termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get termsPrefix;

  /// No description provided for @termsPromotionLabel.
  ///
  /// In en, this message translates to:
  /// **'promotion terms'**
  String get termsPromotionLabel;

  /// No description provided for @termsMiddle.
  ///
  /// In en, this message translates to:
  /// **' and confirm that my post complies with the '**
  String get termsMiddle;

  /// No description provided for @termsCommunityLabel.
  ///
  /// In en, this message translates to:
  /// **'community rules'**
  String get termsCommunityLabel;

  /// No description provided for @processingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingLabel;

  /// Pay amount label
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmountLabel(Object amount);

  /// No description provided for @payAction.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payAction;

  /// No description provided for @promotePostSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post promoted successfully!'**
  String get promotePostSuccess;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @errorOccurredTitle.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurredTitle;

  /// No description provided for @retryLaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get retryLaterSubtitle;

  /// No description provided for @verifiedAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Verified account'**
  String get verifiedAccountTooltip;

  /// No description provided for @premiumAccountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Premium account'**
  String get premiumAccountTooltip;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @myStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'My status'**
  String get myStatusLabel;

  /// No description provided for @meLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meLabel;

  /// No description provided for @navFeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeedLabel;

  /// No description provided for @navMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessagesLabel;

  /// No description provided for @navChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChatLabel;

  /// No description provided for @navGroupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroupsLabel;

  /// No description provided for @navProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfileLabel;

  /// No description provided for @pressToRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get pressToRecordLabel;

  /// Voice effect label
  ///
  /// In en, this message translates to:
  /// **'Effect: {effect}'**
  String effectLabel(Object effect);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
