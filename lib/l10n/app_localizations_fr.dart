// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String appVersion(Object version) {
    return 'Weylo v$version';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get accountSection => 'Compte';

  @override
  String get accountInfo => 'Informations du compte';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearanceSection => 'Apparence';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get premiumSection => 'Premium';

  @override
  String get weyloPremium => 'Weylo Premium';

  @override
  String get premiumSubtitle => 'Débloquez des fonctionnalités exclusives';

  @override
  String get upgrade => 'UPGRADE';

  @override
  String get mySubscriptions => 'Mes abonnements';

  @override
  String get subscriptionsSubtitle => 'Pass Premium et abonnements ciblés';

  @override
  String get premiumSettings => 'Réglages Premium';

  @override
  String get earnings => 'Revenus';

  @override
  String get earningsSubtitle => 'Creator Fund et revenus publicitaires';

  @override
  String get supportSection => 'Support';

  @override
  String get help => 'Aide';

  @override
  String get about => 'À propos';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutTitle => 'Déconnexion';

  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get logoutButton => 'Déconnexion';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get cancel => 'Annuler';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageChangedToFrench => 'Langue changée en français';

  @override
  String get languageChangedToEnglish => 'Langue changée en anglais';

  @override
  String get accountInfoTitle => 'Informations du compte';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Téléphone';

  @override
  String get bio => 'Bio';

  @override
  String get notProvided => 'Non renseigné';

  @override
  String get signupDate => 'Date d\'inscription';

  @override
  String errorMessage(Object details) {
    return 'Erreur : $details';
  }

  @override
  String get profilePostsTab => 'Publications';

  @override
  String get profileLikesTab => 'Likes';

  @override
  String get profileGiftsTab => 'Cadeaux';

  @override
  String get profileFollowers => 'Abonnés';

  @override
  String get profileFollowing => 'Suivis';

  @override
  String get profileEditProfile => 'Modifier le profil';

  @override
  String get profileShareProfile => 'Partager le profil';

  @override
  String get profileNoPostsTitle => 'Aucune publication';

  @override
  String get profileNoPostsSubtitle => 'Partagez votre première publication !';

  @override
  String get profilePromote => 'Promouvoir';

  @override
  String get profilePromoteSubtitle => 'Augmentez la visibilité de ce post';

  @override
  String get profileShare => 'Partager';

  @override
  String profileSharePostMessage(Object url) {
    return 'Découvre ce post sur Weylo : $url';
  }

  @override
  String get profileSharePostSubject => 'Post Weylo';

  @override
  String get profileDelete => 'Supprimer';

  @override
  String get profileDeletePostTitle => 'Supprimer la publication';

  @override
  String get profileDeletePostConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette publication ? Cette action est irréversible.';

  @override
  String get profileDeletePostSuccess => 'Publication supprimée';

  @override
  String get profileNoLikesTitle => 'Aucun like';

  @override
  String get profileNoLikesSubtitle =>
      'Les posts que vous aimez apparaîtront ici';

  @override
  String get profileNoGiftsTitle => 'Aucun cadeau reçu';

  @override
  String get profileNoGiftsSubtitle =>
      'Les cadeaux que vous recevez apparaîtront ici';

  @override
  String get giftDefaultName => 'Cadeau';

  @override
  String giftFromUser(Object username) {
    return 'De @$username';
  }

  @override
  String get giftAnonymous => 'Cadeau anonyme';

  @override
  String timeAgoMinutes(Object minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String timeAgoHours(Object hours) {
    return 'Il y a $hours h';
  }

  @override
  String timeAgoDays(Object days) {
    return 'Il y a $days j';
  }

  @override
  String get shareProfileTitle => 'Partager votre lien anonyme';

  @override
  String get shareProfileSubtitle => 'Choisissez comment partager votre lien';

  @override
  String get shareQrCodeTitle => 'Afficher le QR Code';

  @override
  String get shareQrCodeSubtitle => 'Idéal pour les tests locaux';

  @override
  String get shareWebLinkTitle => 'Partager le lien web';

  @override
  String shareWebLinkMessage(Object url) {
    return 'Envoyez-moi un message anonyme sur Weylo ! $url';
  }

  @override
  String get shareWebLinkSubject => 'Mon profil Weylo';

  @override
  String get shareAppLinkTitle => 'Copier le lien de l\'app';

  @override
  String get copyToClipboardSuccess => 'Lien copié dans le presse-papiers';

  @override
  String get scanQrTitle => 'Scannez ce QR Code';

  @override
  String get close => 'Fermer';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileWalletTitle => 'Mon portefeuille';

  @override
  String get profileStatsMessages => 'Messages';

  @override
  String get profileStatsConfessions => 'Confessions';

  @override
  String get profileStatsConversations => 'Conversations';

  @override
  String get profileUpgradeTitle => 'Passer à Premium';

  @override
  String get profileUpgradeSubtitle =>
      'Voir toutes les identités pour 5 000 FCFA/mois';

  @override
  String get profileMenuEditProfile => 'Modifier le profil';

  @override
  String get profileMenuMyGifts => 'Mes cadeaux';

  @override
  String get profileMenuBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get profileMenuHelpSupport => 'Aide & Support';

  @override
  String get profileMenuAbout => 'À propos';

  @override
  String get profileShareLinkCopied => 'Lien copié !';

  @override
  String get userNotFound => 'Utilisateur introuvable';

  @override
  String get retry => 'Réessayer';

  @override
  String get block => 'Bloquer';

  @override
  String get report => 'Signaler';

  @override
  String get userAnonymous => 'Anonyme';

  @override
  String get profileSubscriptions => 'Abonnements';

  @override
  String get followed => 'Abonné';

  @override
  String get follow => 'Suivre';

  @override
  String get message => 'Message';

  @override
  String get blockUserTitle => 'Bloquer cet utilisateur';

  @override
  String get blockUserConfirm =>
      'Voulez-vous vraiment bloquer cet utilisateur ? Vous ne recevrez plus de messages de sa part.';

  @override
  String get userBlocked => 'Utilisateur bloqué';

  @override
  String get reportUserTitle => 'Signaler cet utilisateur';

  @override
  String get reportReason => 'Raison';

  @override
  String get reportDetailsHint => 'Détails (optionnel)';

  @override
  String get reportSent => 'Signalement envoyé';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportHarassment => 'Harcèlement';

  @override
  String get reportInappropriate => 'Inapproprié';

  @override
  String get reportOther => 'Autre';

  @override
  String get giftsPrivate => 'Les cadeaux sont privés';

  @override
  String get giftsLoadError => 'Erreur lors du chargement';

  @override
  String giftFromUserLower(Object username) {
    return 'de $username';
  }

  @override
  String identityRevealed(Object name) {
    return 'Identité révélée : $name';
  }

  @override
  String get anonymousUser => 'Anonyme';

  @override
  String toRecipient(Object name) {
    return 'À $name';
  }

  @override
  String get userFallback => 'Utilisateur';

  @override
  String get messagesTitle => 'Messages anonymes';

  @override
  String get shareLinkSubject => 'Mon lien Weylo';

  @override
  String get inboxTabReceived => 'Reçus';

  @override
  String get inboxTabSent => 'Envoyés';

  @override
  String get emptyInboxTitle => 'Aucun message reçu';

  @override
  String get emptyInboxSubtitle =>
      'Partagez votre lien pour recevoir des messages anonymes';

  @override
  String get emptyInboxButton => 'Partager mon lien';

  @override
  String get emptySentTitle => 'Aucun message envoyé';

  @override
  String get emptySentSubtitle => 'Envoyez votre premier message anonyme';

  @override
  String get emptySentButton => 'Envoyer un message';

  @override
  String get sendMessageTitle => 'Envoyer un message';

  @override
  String get newMessageTitle => 'Nouveau message';

  @override
  String get searchUserHint => 'Rechercher un utilisateur...';

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get noUsersAvailable => 'Aucun utilisateur disponible pour le moment';

  @override
  String get maskedInfo => 'Informations masquées';

  @override
  String get statusNew => 'Nouveau';

  @override
  String get statusRevealed => 'Révélée';

  @override
  String get statusAnonymous => 'Anonyme';

  @override
  String get revealedConversations => 'Conversations révélées';

  @override
  String get revealedConversationsHelper =>
      'Ils ont déjà dévoilé leur identité';

  @override
  String get anonymousConversations => 'Conversations anonymes';

  @override
  String get anonymousConversationsHelper =>
      'Identité masquée malgré un échange';

  @override
  String get noConversation => 'Sans conversation';

  @override
  String get noConversationHelper => 'Pas encore échangé avec vous';

  @override
  String get selectRecipientError => 'Veuillez sélectionner un destinataire';

  @override
  String get enterMessageError => 'Veuillez entrer un message';

  @override
  String get messageSentSuccess => 'Message envoyé avec succès !';

  @override
  String get anonymousMode => 'Mode anonyme';

  @override
  String get publicMode => 'Mode public';

  @override
  String get anonymousModeSubtitle => 'Votre identité sera cachée';

  @override
  String get publicModeSubtitle => 'Votre nom sera visible';

  @override
  String get messageHint => 'Écrivez votre message...';

  @override
  String get voiceMessageRecorded => 'Message vocal enregistré';

  @override
  String voiceEffectLabel(Object effect) {
    return 'Effet : $effect';
  }

  @override
  String get sendAction => 'Envoyer';

  @override
  String get conversationsTitle => 'Conversations';

  @override
  String get emptyConversationsTitle => 'Aucune conversation';

  @override
  String get emptyConversationsSubtitle =>
      'Commencez une conversation avec quelqu\'un';

  @override
  String get searchConversationsHint => 'Rechercher dans les conversations...';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get yesterdayLabel => 'Hier';

  @override
  String get anonymousConversation => 'Anonyme';

  @override
  String get newConversationFab => 'Démarrer une nouvelle conversation';

  @override
  String get anonymousMessage => 'Message anonyme';

  @override
  String get youLabel => 'Vous';

  @override
  String get contactLabel => 'Contact';

  @override
  String get replyTo => 'Répondre à';

  @override
  String get reply => 'Réponse';

  @override
  String audioPlaybackError(Object details) {
    return 'Erreur lecture audio : $details';
  }

  @override
  String videoPlaybackError(Object details) {
    return 'Erreur lecture vidéo : $details';
  }

  @override
  String get attachmentImage => 'Image';

  @override
  String get attachmentVideo => 'Vidéo';

  @override
  String get chatSendError => 'Erreur lors de l\'envoi du message';

  @override
  String get chatEmpty => 'Aucun message. Commencez la conversation !';

  @override
  String get videoSelected => 'Vidéo sélectionnée';

  @override
  String get messageHintShort => 'Message...';

  @override
  String get statusSending => 'En cours';

  @override
  String get statusSent => 'Envoyé';

  @override
  String get statusRead => 'Lu';

  @override
  String get statusUnread => 'Non lu';

  @override
  String get statusFailed => 'Erreur';

  @override
  String get revealIdentityTitle => 'Révéler l\'identité';

  @override
  String revealIdentityPrompt(Object amount) {
    return 'Voulez-vous payer pour révéler l\'identité de cette personne ? Cette action coûte $amount FCFA.';
  }

  @override
  String get revealIdentitySuccess => 'Identité révélée !';

  @override
  String get revealIdentityAction => 'Révéler';

  @override
  String get sendGift => 'Envoyer un cadeau';

  @override
  String get blockUser => 'Bloquer';

  @override
  String get deleteConversation => 'Supprimer la conversation';

  @override
  String get conversationDeleted => 'Conversation supprimée';

  @override
  String get conversationDeleteError => 'Erreur lors de la suppression';

  @override
  String get messageCopied => 'Message copié';

  @override
  String streakDays(Object days) {
    return '$days jours de streak';
  }

  @override
  String streakExpiresIn(Object hours, Object minutes) {
    return 'Expire dans ${hours}h ${minutes}m';
  }

  @override
  String get streakExpired => 'Le streak est terminé';

  @override
  String get copyAction => 'Copier';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get deleteConversationConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.';

  @override
  String get giftRecipientUnknown => 'Impossible de déterminer le destinataire';

  @override
  String get loading => 'Chargement...';

  @override
  String get paymentTitle => 'Paiement';

  @override
  String get invalidPaymentUrl => 'URL de paiement invalide';

  @override
  String pageNotFound(Object uri) {
    return 'Page non trouvée : $uri';
  }

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get newChatTitle => 'Nouvelle conversation';

  @override
  String get startAction => 'Démarrer';

  @override
  String get startConversationError => 'Impossible de démarrer la conversation';

  @override
  String get addContentOrMediaError =>
      'Veuillez ajouter du contenu ou un média';

  @override
  String get postCreatedSuccess => 'Publication créée avec succès !';

  @override
  String postCreateError(Object details) {
    return 'Erreur lors de la création : $details';
  }

  @override
  String get createPostTitle => 'Nouvelle publication';

  @override
  String get publishAction => 'Publier';

  @override
  String get confessionHint =>
      'Qu\'avez-vous à confesser ? (optionnel avec média)';

  @override
  String get photoAction => 'Photo';

  @override
  String get postAnonymousTitle => 'Publication anonyme';

  @override
  String get postAnonymousSubtitle => 'Votre identité sera cachée';

  @override
  String get postPublicTitle => 'Publication publique';

  @override
  String get postPublicSubtitle => 'Visible par tous les utilisateurs';

  @override
  String get settingsUpdated => 'Paramètres mis à jour';

  @override
  String blockedUsersWithCount(Object count) {
    return 'Utilisateurs bloqués ($count)';
  }

  @override
  String get noBlockedUsers => 'Aucun utilisateur bloqué';

  @override
  String get unblockAction => 'Débloquer';

  @override
  String get blockedUsersTitle => 'Utilisateurs bloqués';

  @override
  String blockedUsersCount(Object count) {
    return '$count utilisateur(s)';
  }

  @override
  String get profileVisibilityHeader => 'VISIBILITÉ DU PROFIL';

  @override
  String get showNameOnPostsTitle => 'Afficher mon nom sur mes publications';

  @override
  String get showNameOnPostsSubtitle =>
      'Votre nom sera visible sur vos posts publics';

  @override
  String get showPhotoOnPostsTitle => 'Afficher ma photo sur mes publications';

  @override
  String get showPhotoOnPostsSubtitle => 'Votre photo de profil sera visible';

  @override
  String get activityHeader => 'ACTIVITÉ';

  @override
  String get showOnlineStatusTitle => 'Afficher le statut en ligne';

  @override
  String get showOnlineStatusSubtitle =>
      'Les autres peuvent voir quand vous êtes en ligne';

  @override
  String get allowAnonymousMessagesTitle => 'Autoriser les messages anonymes';

  @override
  String get allowAnonymousMessagesSubtitle => 'Recevoir des messages anonymes';

  @override
  String get accountManagementHeader => 'GESTION DU COMPTE';

  @override
  String get deleteAccountTitle => 'Supprimer mon compte';

  @override
  String get deleteAccountSubtitle => 'Cette action est irréversible';

  @override
  String get deleteAccountConfirm =>
      'Êtes-vous sûr de vouloir supprimer votre compte ? Toutes vos données seront définitivement supprimées.';

  @override
  String userUnblocked(Object username) {
    return '@$username a été débloqué';
  }

  @override
  String get legalLastUpdated => 'Dernière mise à jour : 1er janvier 2026';

  @override
  String get legalIntro =>
      'En utilisant Weylo, vous acceptez les conditions suivantes...';

  @override
  String get legalBody =>
      '1. Utilisation du service\n\nWeylo est une plateforme de messagerie anonyme. En utilisant ce service, vous vous engagez à respecter les autres utilisateurs et à ne pas publier de contenu illégal ou offensant.\n\n2. Confidentialité\n\nNous respectons votre vie privée. Vos messages anonymes ne révèlent pas votre identité sauf si vous choisissez de la révéler.\n\n3. Responsabilité\n\nVous êtes responsable du contenu que vous publiez. Weylo se réserve le droit de supprimer tout contenu inapproprié.';

  @override
  String get faqTitle => 'Questions fréquentes';

  @override
  String get faqSendAnonymousQuestion => 'Comment envoyer un message anonyme ?';

  @override
  String get faqSendAnonymousAnswer =>
      'Allez sur le profil d\'un utilisateur et tapez sur \"Envoyer un message\". Votre identité restera cachée à moins que vous ne choisissiez de la révéler.';

  @override
  String get faqRevealIdentityQuestion =>
      'Comment voir qui m\'a envoyé un message ?';

  @override
  String get faqRevealIdentityAnswer =>
      'Par défaut, les messages sont anonymes. Vous pouvez demander la révélation d\'identité moyennant des crédits ou un abonnement Premium.';

  @override
  String get faqShareLinkQuestion => 'Comment partager mon lien ?';

  @override
  String get faqShareLinkAnswer =>
      'Allez dans votre profil et tapez sur \"Partager le profil\". Vous pouvez partager votre lien sur les réseaux sociaux.';

  @override
  String get faqContactSupportQuestion => 'Comment contacter le support ?';

  @override
  String get faqContactSupportAnswer =>
      'Envoyez un email à support@weylo.app pour toute question ou problème.';

  @override
  String get emailClientError => 'Impossible d\'ouvrir le client email';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get appName => 'Weylo';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutTagline =>
      'La plateforme de messagerie anonyme\nqui connecte les gens en toute sécurité.';

  @override
  String get copyrightNotice => '© 2026 Weylo. Tous droits réservés.';

  @override
  String get takePhotoAction => 'Prendre une photo';

  @override
  String get chooseFromGalleryAction => 'Choisir dans la galerie';

  @override
  String get deletePhotoAction => 'Supprimer la photo';

  @override
  String get profilePhotoUpdated => 'Photo de profil mise à jour !';

  @override
  String get profilePhotoDeleted => 'Photo de profil supprimée !';

  @override
  String get profileUpdated => 'Profil mis à jour !';

  @override
  String get saveAction => 'Enregistrer';

  @override
  String get changeProfilePhoto => 'Changer la photo de profil';

  @override
  String get firstNameRequired => 'Veuillez entrer votre prénom';

  @override
  String get bioHint => 'Parlez de vous...';

  @override
  String get premiumActiveTitle => 'Vous êtes Premium !';

  @override
  String premiumDaysRemaining(Object days) {
    return '$days jours restants';
  }

  @override
  String get autoRenewTitle => 'Renouvellement automatique';

  @override
  String get autoRenewSubtitle => 'Renouveler automatiquement votre abonnement';

  @override
  String get premiumUnlockTitle => 'Débloquez toutes les fonctionnalités';

  @override
  String get featureRevealTitle => 'Voir l\'identité';

  @override
  String get featureRevealSubtitle => 'Révélez qui vous envoie des messages';

  @override
  String get featureBadgeTitle => 'Badge Premium';

  @override
  String get featureBadgeSubtitle => 'Montrez votre statut Premium';

  @override
  String get featureNoAdsTitle => 'Sans publicités';

  @override
  String get featureNoAdsSubtitle => 'Profitez d\'une expérience sans pub';

  @override
  String get featureStatsTitle => 'Statistiques avancées';

  @override
  String get featureStatsSubtitle => 'Analysez vos interactions';

  @override
  String get monthlyPlanTitle => 'Mensuel';

  @override
  String get monthlyPlanPrice => '2 500 FCFA/mois';

  @override
  String get yearlyPlanTitle => 'Annuel';

  @override
  String get yearlyPlanPrice => '20 000 FCFA/an (économisez 33 %)';

  @override
  String get subscribeAction => 'S\'abonner';

  @override
  String get premiumActivated => 'Abonnement Premium activé !';

  @override
  String get autoRenewEnabled => 'Renouvellement automatique activé';

  @override
  String get autoRenewDisabled => 'Renouvellement automatique désactivé';

  @override
  String get markAllRead => 'Tout lire';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get notificationsMarkedRead =>
      'Toutes les notifications marquées comme lues';

  @override
  String timeAgoMinutesShort(Object minutes) {
    return '$minutes min';
  }

  @override
  String timeAgoHoursShort(Object hours) {
    return '$hours h';
  }

  @override
  String timeAgoDaysShort(Object days) {
    return '$days j';
  }

  @override
  String get storyInvalidUserId => 'ID utilisateur invalide';

  @override
  String get storyNoAvailable => 'Aucune story disponible';

  @override
  String storyLoadError(Object details) {
    return 'Erreur de chargement : $details';
  }

  @override
  String get storyReplySent => 'Réponse envoyée';

  @override
  String get storyReplyError => 'Erreur lors de l\'envoi';

  @override
  String get storyNoActive => 'Vous n\'avez pas de story active';

  @override
  String get deleteStoryTitle => 'Supprimer la story ?';

  @override
  String get deleteStoryConfirm => 'Cette action est irréversible.';

  @override
  String get storyDeleted => 'Story supprimée';

  @override
  String get storyNoneTitle => 'Aucune story';

  @override
  String get createStoryAction => 'Créer une story';

  @override
  String viewsCount(Object count) {
    return '$count vues';
  }

  @override
  String get storyViewsEmpty => 'Les vues seront affichées ici';

  @override
  String get myStoryTitle => 'Ma story';

  @override
  String get followersTitle => 'Abonnés';

  @override
  String get followingTitle => 'Abonnements';

  @override
  String get noFollowers => 'Aucun abonné';

  @override
  String get noFollowing => 'Aucun abonnement';

  @override
  String get groupTitleFallback => 'Groupe';

  @override
  String membersCount(Object count) {
    return '$count membres';
  }

  @override
  String membersCountWithMax(Object count, Object max) {
    return '$count/$max membres';
  }

  @override
  String get groupEmptyTitle => 'Aucun message';

  @override
  String get groupEmptySubtitle =>
      'Envoyez un message pour démarrer la conversation';

  @override
  String replyToUser(Object name) {
    return 'Répondre à $name';
  }

  @override
  String get messageEditMode => 'Modification du message';

  @override
  String get editMessageHint => 'Modifier le message...';

  @override
  String get messageInputHint => 'Écrire un message...';

  @override
  String get voiceMessageLabel => 'Message vocal';

  @override
  String get messageLabel => 'Message';

  @override
  String get editAction => 'Modifier';

  @override
  String get deleteMessageTitle => 'Supprimer le message';

  @override
  String get deleteMessageConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce message ?';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get inviteCodeTitle => 'Code d\'invitation';

  @override
  String get inviteCodeCopied => 'Code copié !';

  @override
  String get editGroup => 'Modifier le groupe';

  @override
  String get groupInfo => 'Infos du groupe';

  @override
  String get regenerateInviteCode => 'Régénérer le code d\'invitation';

  @override
  String newInviteCode(Object code) {
    return 'Nouveau code : $code';
  }

  @override
  String get regenerateInviteError => 'Erreur lors de la régénération';

  @override
  String get leaveGroup => 'Quitter le groupe';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get deleteGroupConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce groupe ? Cette action est irréversible. Tous les messages et les membres seront supprimés.';

  @override
  String get groupDeleted => 'Groupe supprimé';

  @override
  String get inviteCodeShareHint =>
      'Partagez ce code pour inviter des personnes à rejoindre le groupe.';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get publicGroup => 'Groupe public';

  @override
  String get privateGroup => 'Groupe privé';

  @override
  String get changeGroupLogo => 'Changer le logo';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String get maxMembersLabel => 'Nombre maximum de membres';

  @override
  String get publicGroupSubtitle => 'Visible dans la découverte';

  @override
  String get groupUpdated => 'Groupe modifié !';

  @override
  String get leaveGroupConfirm =>
      'Êtes-vous sûr de vouloir quitter ce groupe ?';

  @override
  String get leftGroupSuccess => 'Vous avez quitté le groupe';

  @override
  String get groupMembersTitle => 'Membres du groupe';

  @override
  String get noMembers => 'Aucun membre';

  @override
  String get roleCreator => 'Créateur';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get removeMemberTitle => 'Retirer le membre';

  @override
  String removeMemberConfirm(Object name) {
    return 'Voulez-vous retirer $name du groupe ?';
  }

  @override
  String get removeAction => 'Retirer';

  @override
  String get memberRemoved => 'Membre retiré';

  @override
  String errorWithDebug(Object error, Object debug) {
    return '$error (debug : $debug)';
  }

  @override
  String get messageEdited => 'Message modifié';

  @override
  String get anonymousSender => 'Expéditeur anonyme';

  @override
  String get messageReported => 'Message signalé';

  @override
  String get messageNotFound => 'Message introuvable';

  @override
  String get identityRevealedTitle => 'Identité révélée';

  @override
  String sentByUser(Object name) {
    return 'Envoyé par $name';
  }

  @override
  String get replyOnceTitle => 'Répondre une fois';

  @override
  String get replyOnceSubtitle =>
      'Répondez à ce message pour démarrer une conversation dans le chat.';

  @override
  String get replyPlaceholder => 'Écrivez votre réponse...';

  @override
  String get replyAndStartConversation =>
      'Répondre et démarrer la conversation';

  @override
  String get sendingLabel => 'Envoi...';

  @override
  String get conversationStarted =>
      'Conversation démarrée ! Vous pouvez maintenant discuter.';

  @override
  String get replySent => 'Réponse envoyée';

  @override
  String get revealIdentityCreditsPrompt =>
      'Voulez-vous dépenser des crédits pour découvrir qui a envoyé ce message ? Cette action est irréversible.';

  @override
  String get supportEmailSubject => 'Support - Weylo';

  @override
  String get loginWelcome => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connectez-vous pour continuer';

  @override
  String get loginIdentifierLabel => 'Nom d\'utilisateur, email ou téléphone';

  @override
  String get loginIdentifierHint => 'Entrez votre identifiant';

  @override
  String get loginIdentifierRequired => 'Veuillez entrer votre identifiant';

  @override
  String get loginPinLabel => 'Code PIN';

  @override
  String get loginPinHint => 'Entrez votre code à 4 chiffres';

  @override
  String get loginPinRequired => 'Veuillez entrer votre code PIN';

  @override
  String get forgotPin => 'Code oublié ?';

  @override
  String get loginAction => 'Se connecter';

  @override
  String get orSeparator => 'ou';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get registerTitle => 'Inscription';

  @override
  String registerStepLabel(Object step, Object total) {
    return 'Étape $step sur $total';
  }

  @override
  String get registerPersonalInfoTitle => 'Informations personnelles';

  @override
  String get registerAccountInfoTitle => 'Votre compte';

  @override
  String get registerSecurityTitle => 'Sécurité';

  @override
  String get registerNameQuestion => 'Comment vous appelez-vous ?';

  @override
  String get registerNameSubtitle =>
      'Entrez votre prénom et nom pour personnaliser votre profil';

  @override
  String get firstNameLabelRequired => 'Prénom *';

  @override
  String get firstNameHint => 'Entrez votre prénom';

  @override
  String get firstNameTooShort =>
      'Le prénom doit contenir au moins 2 caractères';

  @override
  String get lastNameLabelOptional => 'Nom (optionnel)';

  @override
  String get lastNameHint => 'Entrez votre nom';

  @override
  String get continueAction => 'Continuer';

  @override
  String get registerIdentityTitle => 'Créez votre identité';

  @override
  String get registerIdentitySubtitle =>
      'Choisissez un nom d\'utilisateur unique et ajoutez vos coordonnées';

  @override
  String get usernameLabelRequired => 'Nom d\'utilisateur *';

  @override
  String get usernameHint => 'Choisissez un nom unique';

  @override
  String get usernameRequired => 'Le nom d\'utilisateur est requis';

  @override
  String get usernameInvalid =>
      'Utilisez 3 à 20 caractères (lettres, chiffres, _)';

  @override
  String get emailLabelOptional => 'Email (optionnel)';

  @override
  String get emailHint => 'Entrez votre email';

  @override
  String get emailInvalid => 'Email invalide';

  @override
  String get phoneLabelOptional => 'Téléphone (optionnel)';

  @override
  String get phoneHint => '6XXXXXXXX';

  @override
  String get phoneInvalid => 'Numéro de téléphone invalide';

  @override
  String get registerSecureTitle => 'Sécurisez votre compte';

  @override
  String get registerSecureSubtitle =>
      'Créez un code PIN à 4 chiffres pour protéger votre compte';

  @override
  String get pinLabelRequired => 'Code PIN *';

  @override
  String get pinCreateHint => 'Créez un code à 4 chiffres';

  @override
  String get pinRequired => 'Le code est requis';

  @override
  String get pinInvalid => 'Le code doit contenir exactement 4 chiffres';

  @override
  String get pinConfirmLabelRequired => 'Confirmer le code *';

  @override
  String get pinConfirmHint => 'Confirmez votre code PIN';

  @override
  String get pinConfirmRequired => 'Veuillez confirmer votre code';

  @override
  String get pinMismatch => 'Les codes ne correspondent pas';

  @override
  String get acceptTermsError =>
      'Veuillez accepter les conditions d\'utilisation';

  @override
  String get acceptTermsPrefix => 'J\'accepte les ';

  @override
  String get acceptTermsLink => 'conditions d\'utilisation';

  @override
  String get acceptPrivacyMiddle => ' et la ';

  @override
  String get acceptPrivacyLink => 'politique de confidentialité';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get loginLink => 'Se connecter';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get verifyIdentityTitle => 'Vérification d\'identité';

  @override
  String get verifyIdentitySubtitle =>
      'Entrez votre numéro de téléphone et votre prénom pour vérifier votre identité';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSubtitle => 'Créez votre nouveau mot de passe';

  @override
  String get verifyIdentityError => 'Impossible de vérifier votre identité';

  @override
  String get resetPasswordError =>
      'Impossible de réinitialiser le mot de passe';

  @override
  String get passwordResetSuccess => 'Mot de passe modifié avec succès';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get phoneRequired => 'Le numéro de téléphone est requis';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get firstNameRequiredSimple => 'Le prénom est requis';

  @override
  String get verifyIdentityAction => 'Vérifier mon identité';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get newPasswordHint => 'Créez un nouveau mot de passe';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Confirmez votre mot de passe';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get resetPasswordAction => 'Réinitialiser le mot de passe';

  @override
  String get navMessages => 'Messages';

  @override
  String get navConfessions => 'Confessions';

  @override
  String get navChat => 'Chat';

  @override
  String get navGroups => 'Groupes';

  @override
  String get navProfile => 'Profil';

  @override
  String get searchAction => 'Rechercher';

  @override
  String get loadingErrorTitle => 'Erreur de chargement';

  @override
  String get feedEmptyTitle => 'Aucune publication';

  @override
  String get feedEmptySubtitle => 'Soyez le premier à publier !';

  @override
  String sharePostMessage(Object url) {
    return 'Découvrez cette publication sur Weylo ! $url';
  }

  @override
  String get sharePostSubject => 'Publication Weylo';

  @override
  String get feedPostHint => 'Exprimez-vous...';

  @override
  String get videoSelectedLabel => 'Vidéo sélectionnée';

  @override
  String get addImageAction => 'Ajouter une image';

  @override
  String get addGifAction => 'Ajouter un GIF';

  @override
  String get addVideoAction => 'Ajouter une vidéo';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityAnonymous => 'Anonyme';

  @override
  String get storyContentRequired => 'Ajoutez du contenu à votre story.';

  @override
  String get storyPublishedSuccess => 'Story publiée !';

  @override
  String get storyPublishError => 'Erreur lors de la publication';

  @override
  String get connectionError =>
      'Erreur de connexion. Vérifiez votre connexion Internet.';

  @override
  String get unsupportedFileFormat => 'Format de fichier non pris en charge';

  @override
  String get fileTooLarge => 'Fichier trop volumineux';

  @override
  String get storyWriteHint => 'Écrivez quelque chose...';

  @override
  String get galleryLabel => 'Galerie';

  @override
  String get videoLabel => 'Vidéo';

  @override
  String get textLabel => 'Texte';

  @override
  String get commentAddError => 'Impossible d\'ajouter le commentaire';

  @override
  String get viewCommentsAction => 'Voir les commentaires';

  @override
  String viewCommentsCount(Object count) {
    return 'Voir les $count commentaire(s)';
  }

  @override
  String get storyReplySendError => 'Erreur lors de l\'envoi';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get noCommentsTitle => 'Aucun commentaire';

  @override
  String get noCommentsSubtitle => 'Soyez le premier à commenter !';

  @override
  String get commentHint => 'Ajouter un commentaire...';

  @override
  String get earningsTitle => 'Revenus';

  @override
  String get earningsHistoryTitle => 'Historique des paiements';

  @override
  String get earningsTotalsLabel => 'Revenus cumulés';

  @override
  String get creatorFundLabel => 'Fonds des créateurs';

  @override
  String get adRevenueLabel => 'Revenus publicitaires';

  @override
  String get adsLabel => 'Publicités';

  @override
  String get viewsLabel => 'Vues';

  @override
  String get likesLabel => 'Likes';

  @override
  String get scoreLabel => 'Score';

  @override
  String poolLabel(Object amount) {
    return 'Pool : $amount';
  }

  @override
  String get noPayoutsTitle => 'Aucun paiement';

  @override
  String get noPayoutsSubtitle => 'Les paiements apparaîtront ici';

  @override
  String get searchHint => 'Rechercher des personnes ou des publications...';

  @override
  String peopleTabCount(Object count) {
    return 'Personnes ($count)';
  }

  @override
  String postsTabCount(Object count) {
    return 'Publications ($count)';
  }

  @override
  String get searchEmptyTitle => 'Rechercher sur Weylo';

  @override
  String get searchEmptySubtitle => 'Trouvez des personnes ou des publications';

  @override
  String get searchNoUsers => 'Aucun utilisateur trouvé';

  @override
  String get searchNoPosts => 'Aucune publication trouvée';

  @override
  String get joinGroupTitle => 'Rejoindre un groupe';

  @override
  String get inviteCodeHint => 'Entrez le code d\'invitation';

  @override
  String get joinGroupSuccess => 'Vous avez rejoint le groupe !';

  @override
  String get invalidInviteCode => 'Code d\'invitation invalide';

  @override
  String get joinAction => 'Rejoindre';

  @override
  String get groupsTitle => 'Groupes';

  @override
  String get joinWithCodeTooltip => 'Rejoindre avec un code';

  @override
  String get myGroupsTab => 'Mes groupes';

  @override
  String get discoverTab => 'Découvrir';

  @override
  String get noGroupsTitle => 'Aucun groupe';

  @override
  String get noGroupsDiscoverTitle => 'Aucun groupe à découvrir';

  @override
  String get noGroupsSubtitle => 'Créez ou rejoignez un groupe pour commencer';

  @override
  String get noGroupsDiscoverSubtitle =>
      'Revenez plus tard pour découvrir de nouveaux groupes';

  @override
  String get createGroupAction => 'Créer un groupe';

  @override
  String joinGroupNameTitle(Object name) {
    return 'Rejoindre $name';
  }

  @override
  String groupMembersCount(Object current, Object max) {
    return '$current/$max membres';
  }

  @override
  String get joinGroupError => 'Impossible de rejoindre le groupe';

  @override
  String get removePhotoAction => 'Supprimer la photo';

  @override
  String get groupCreatedSuccess => 'Groupe créé avec succès !';

  @override
  String get createGroupTitle => 'Créer un groupe';

  @override
  String get createAction => 'Créer';

  @override
  String get groupNameHint => 'Ex : Amis de l\'université';

  @override
  String get groupNameRequiredError => 'Le nom du groupe est requis';

  @override
  String groupNameMinLengthError(Object min) {
    return 'Le nom doit contenir au moins $min caractères';
  }

  @override
  String get groupDescriptionLabel => 'Description (optionnelle)';

  @override
  String get groupDescriptionHint => 'Décrivez le but de ce groupe...';

  @override
  String get maxMembersTitle => 'Nombre maximum de membres';

  @override
  String get publicGroupTitle => 'Groupe public';

  @override
  String get privateGroupSubtitle =>
      'Seules les personnes avec le code d\'invitation peuvent rejoindre';

  @override
  String get groupInviteCodeInfo =>
      'Un code d\'invitation sera généré automatiquement pour votre groupe.';

  @override
  String get walletTitle => 'Mon portefeuille';

  @override
  String get availableBalanceLabel => 'Solde disponible';

  @override
  String get depositAction => 'Déposer';

  @override
  String get withdrawAction => 'Retirer';

  @override
  String get totalDepositsLabel => 'Total dépôts';

  @override
  String get totalWithdrawalsLabel => 'Total retraits';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get withdrawalsTab => 'Retraits';

  @override
  String get noTransactionsTitle => 'Aucune transaction';

  @override
  String get noTransactionsSubtitle => 'Vos transactions apparaîtront ici';

  @override
  String get noWithdrawalsTitle => 'Aucun retrait';

  @override
  String get noWithdrawalsSubtitle =>
      'Vos demandes de retrait apparaîtront ici';

  @override
  String get depositTitle => 'Déposer de l\'argent';

  @override
  String get depositViaLigos => 'Paiement via Ligos';

  @override
  String get amountLabel => 'Montant (FCFA)';

  @override
  String get amountExample => 'Ex : 5000';

  @override
  String minimumAmountLabel(Object amount) {
    return 'Montant minimum : $amount';
  }

  @override
  String get depositInitError => 'Erreur lors de l\'initialisation';

  @override
  String get continueToLigos => 'Continuer vers Ligos';

  @override
  String get withdrawRequestTitle => 'Demander un retrait';

  @override
  String get withdrawViaCinetpay => 'Retrait via Cinetpay';

  @override
  String get withdrawMethodLabel => 'Méthode de retrait';

  @override
  String get mtnMobileMoneyLabel => 'MTN Mobile Money';

  @override
  String get orangeMoneyLabel => 'Orange Money';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get phoneNumberHint => '6XXXXXXXX';

  @override
  String get phoneNumberRequiredError =>
      'Veuillez entrer un numéro de téléphone';

  @override
  String get withdrawRequestSent => 'Demande de retrait envoyée';

  @override
  String get withdrawRequestError => 'Erreur lors de la demande';

  @override
  String get confessionsTitle => 'Confessions';

  @override
  String get receivedTab => 'Reçues';

  @override
  String get sentTab => 'Envoyées';

  @override
  String get noConfessionsReceivedTitle => 'Aucune confession reçue';

  @override
  String get noConfessionsSentTitle => 'Aucune confession envoyée';

  @override
  String get noConfessionsTitle => 'Aucune confession';

  @override
  String get noConfessionsReceivedSubtitle =>
      'Les confessions qui vous sont adressées apparaîtront ici';

  @override
  String get noConfessionsSentSubtitle => 'Vos confessions apparaîtront ici';

  @override
  String get noConfessionsSubtitle =>
      'Soyez le premier à poster une confession';

  @override
  String get createConfessionAction => 'Créer une confession';

  @override
  String loadingErrorMessage(Object details) {
    return 'Erreur de chargement : $details';
  }

  @override
  String get postTitle => 'Publication';

  @override
  String get postNotFound => 'Publication non trouvée';

  @override
  String likesCount(Object count) {
    return '$count j\'aime';
  }

  @override
  String commentsCount(Object count) {
    return '$count commentaire(s)';
  }

  @override
  String get likeAction => 'J\'aime';

  @override
  String get commentAction => 'Commenter';

  @override
  String get shareAction => 'Partager';

  @override
  String commentsCountTitle(Object count) {
    return 'Commentaires ($count)';
  }

  @override
  String get replyAction => 'Répondre';

  @override
  String revealIdentityCost(Object amount) {
    return 'Coût : $amount';
  }

  @override
  String revealIdentityAmount(Object amount) {
    return '$amount';
  }

  @override
  String get costLabel => 'Coût';

  @override
  String revealIdentitySuccessWithName(Object name) {
    return 'Identité révélée : $name';
  }

  @override
  String get reportPostTitle => 'Signaler la publication';

  @override
  String get reportPostPrompt =>
      'Voulez-vous signaler cette publication pour contenu inapproprié ?';

  @override
  String get reportPostSuccess => 'Publication signalée';

  @override
  String get reportAction => 'Signaler';

  @override
  String get statusLabel => 'Statut';

  @override
  String get viewAction => 'Voir';

  @override
  String get subscriptionsTitle => 'Mes abonnements';

  @override
  String get premiumPassTab => 'Pass Premium';

  @override
  String get targetedSubscriptionsTab => 'Ciblés';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusInactive => 'Inactif';

  @override
  String get historyTitle => 'Historique';

  @override
  String get noPassTitle => 'Aucun pass';

  @override
  String get noPassSubtitle => 'Votre historique Premium apparaîtra ici';

  @override
  String expiresOnDate(Object date) {
    return 'Expire le $date';
  }

  @override
  String get noSubscriptionsTitle => 'Aucun abonnement';

  @override
  String get noSubscriptionsSubtitle =>
      'Vos abonnements ciblés apparaîtront ici';

  @override
  String get noExpiryLabel => 'Sans date d\'expiration';

  @override
  String get premiumBrandName => 'Weylo Premium';

  @override
  String get subscriptionCancelled => 'Abonnement annulé';

  @override
  String get storyReplyPlaceholder => 'Répondre à la story...';

  @override
  String get visibleLabel => 'Visible';

  @override
  String get storyReplyHint => 'Écrivez votre réponse...';

  @override
  String get visibilityPrivate => 'Privée';

  @override
  String get viewMoreAction => 'Voir plus';

  @override
  String get viewLessAction => 'Voir moins';

  @override
  String confessionForUser(Object name) {
    return 'Pour $name';
  }

  @override
  String get boostAction => 'Booster';

  @override
  String get postDeletedSuccess => 'Publication supprimée';

  @override
  String get giftSentTitle => 'Cadeau envoyé !';

  @override
  String giftSentMessage(Object gift, Object username) {
    return 'Votre $gift a été envoyé à $username';
  }

  @override
  String sendGiftToUser(Object username) {
    return 'Envoyer un cadeau à $username';
  }

  @override
  String get sendAnonymouslyLabel => 'Envoyer anonymement';

  @override
  String sendGiftAction(Object gift) {
    return 'Envoyer $gift';
  }

  @override
  String get selectGiftLabel => 'Sélectionnez un cadeau';

  @override
  String get promoObjectiveBoostTitle => 'Booster mon compte';

  @override
  String get promoObjectiveBoostDescription =>
      'Augmentez votre visibilité et gagnez des abonnés';

  @override
  String get promoObjectiveFollowers => 'Gagner des abonnés';

  @override
  String get promoObjectiveVisibility => 'Plus de visibilité';

  @override
  String get promoObjectiveEngagement => 'Plus d\'engagement';

  @override
  String get promoObjectiveSalesTitle => 'Obtenir des ventes';

  @override
  String get promoObjectiveSalesDescription =>
      'Convertissez vos visiteurs en clients';

  @override
  String get promoObjectiveSellProducts => 'Vendre des produits';

  @override
  String get promoObjectiveSellServices => 'Vendre des services';

  @override
  String get promoObjectivePromoteEvent => 'Promouvoir un événement';

  @override
  String get promoObjectiveProspectsTitle => 'Obtenir des prospects';

  @override
  String get promoObjectiveProspectsDescription =>
      'Générez des leads qualifiés pour votre activité';

  @override
  String get promoObjectiveCollectContacts => 'Collecter des contacts';

  @override
  String get promoObjectiveReceiveMessages => 'Recevoir des messages';

  @override
  String get promoObjectiveWebsiteVisits => 'Visites sur mon site';

  @override
  String get promoStepGoalTitle => 'Choisissez votre objectif';

  @override
  String get promoStepDetailTitle => 'Précisez votre objectif';

  @override
  String get promoStepPackTitle => 'Choisissez votre pack';

  @override
  String get promoStepConfirmTitle => 'Confirmation';

  @override
  String get promotePostTitle => 'Promouvoir';

  @override
  String get promoGoalQuestion => 'Quel est votre objectif ?';

  @override
  String get promoGoalSubtitle =>
      'Sélectionnez l\'objectif principal de votre promotion';

  @override
  String get promoSelectObjectiveFirst =>
      'Veuillez d\'abord sélectionner un objectif';

  @override
  String get promoDetailSubtitle =>
      'Choisissez ce que vous souhaitez accomplir';

  @override
  String get promoPackTitle => 'Choisissez votre pack';

  @override
  String get promoPackSubtitle =>
      'Sélectionnez la durée et le budget de votre promotion';

  @override
  String promoReachBoost(Object boost) {
    return '+$boost% portée';
  }

  @override
  String promoBoostDuration(Object hours) {
    return '$hours h de boost';
  }

  @override
  String get promoNonFollowersIncluded => 'Non-abonnés inclus';

  @override
  String get promoDetailedStats => 'Stats détaillées';

  @override
  String get popularLabel => 'POPULAIRE';

  @override
  String get summaryTitle => 'Récapitulatif';

  @override
  String get summaryObjectiveLabel => 'Objectif';

  @override
  String get summaryPackLabel => 'Pack';

  @override
  String get summaryDurationLabel => 'Durée';

  @override
  String summaryDurationValue(Object hours) {
    return '$hours heures';
  }

  @override
  String get summaryReachBoostLabel => 'Boost portée';

  @override
  String summaryReachBoostValue(Object boost) {
    return '+$boost%';
  }

  @override
  String get summaryTotalLabel => 'Total';

  @override
  String get promoImportantInfoTitle => 'Informations importantes';

  @override
  String get promoImportantInfoBody =>
      '• Le boost démarrera immédiatement après le paiement\n• La durée du boost est garantie\n• Les statistiques seront disponibles en temps réel\n• Aucun remboursement possible après activation';

  @override
  String get termsPrefix => 'J\'accepte les ';

  @override
  String get termsPromotionLabel => 'conditions générales de promotion';

  @override
  String get termsMiddle => ' et je confirme que ma publication respecte les ';

  @override
  String get termsCommunityLabel => 'règles de la communauté';

  @override
  String get processingLabel => 'Traitement...';

  @override
  String payAmountLabel(Object amount) {
    return 'Payer $amount';
  }

  @override
  String get payAction => 'Payer';

  @override
  String get promotePostSuccess => 'Publication promue avec succès !';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get errorOccurredTitle => 'Une erreur est survenue';

  @override
  String get retryLaterSubtitle => 'Veuillez réessayer plus tard';

  @override
  String get verifiedAccountTooltip => 'Compte vérifié';

  @override
  String get premiumAccountTooltip => 'Compte Premium';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get myStatusLabel => 'Mon statut';

  @override
  String get meLabel => 'Moi';

  @override
  String get navFeedLabel => 'Fil';

  @override
  String get navMessagesLabel => 'Messages';

  @override
  String get navChatLabel => 'Chat';

  @override
  String get navGroupsLabel => 'Groupes';

  @override
  String get navProfileLabel => 'Profil';

  @override
  String get pressToRecordLabel => 'Appuyez pour enregistrer';

  @override
  String effectLabel(Object effect) {
    return 'Effet : $effect';
  }
}
