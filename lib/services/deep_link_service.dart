import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;

  Future<void> initialize(BuildContext context, {GoRouter? router}) async {
    _router = router;

    // Handle initial link if app was started from a link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      // Delay to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleDeepLink(context, initialUri);
      });
    }

    // Handle links when app is in foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(context, uri);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(BuildContext context, Uri uri) {
    debugPrint('========================================');
    debugPrint('Deep link received: $uri');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('Path: ${uri.path}');
    debugPrint('Path segments: ${uri.pathSegments}');
    debugPrint('========================================');

    // Ignorer les URLs localhost en développement (Flutter Web)
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      debugPrint('Ignoring localhost URL in development');
      return;
    }

    final path = uri.path;
    final pathSegments = uri.pathSegments;
    String? targetRoute;

    // Handle different deep link patterns
    if (path.startsWith('/u/') && pathSegments.length >= 2) {
      // User profile: weylo://u/username or https://weylo.app/u/username
      final username = pathSegments[1];
      targetRoute = '/u/$username';
      debugPrint('Navigating to user profile: $targetRoute');
    } else if (path.startsWith('/m/') && pathSegments.length >= 2) {
      // Anonymous message: weylo://m/username
      final username = pathSegments[1];
      targetRoute = '/send-anonymous/$username';
      debugPrint('Navigating to send anonymous message: $targetRoute');
    } else if (path.startsWith('/send/') && pathSegments.length >= 2) {
      // Anonymous message (alternative): weylo://send/username
      final username = pathSegments[1];
      targetRoute = '/send-anonymous/$username';
      debugPrint('Navigating to send anonymous message: $targetRoute');
    } else if (pathSegments.length == 1 && pathSegments[0].isNotEmpty) {
      // Direct username: weylo://username - for anonymous messages
      final username = pathSegments[0];
      targetRoute = '/send-anonymous/$username';
      debugPrint('Navigating to send anonymous message (direct): $targetRoute');
    } else if (path.startsWith('/post/') && pathSegments.length >= 2) {
      // Post detail: weylo://post/123 or https://weylo.app/post/123
      final postId = pathSegments[1];
      targetRoute = '/post/$postId';
      debugPrint('Navigating to post: $targetRoute');
    } else if (path.startsWith('/chat/') && pathSegments.length >= 2) {
      // Chat conversation: weylo://chat/123
      final chatId = pathSegments[1];
      targetRoute = '/chat/$chatId';
      debugPrint('Navigating to chat: $targetRoute');
    } else if (path.startsWith('/stories/') && pathSegments.length >= 2) {
      // Stories: weylo://stories/userId
      final userId = pathSegments[1];
      targetRoute = '/stories/$userId';
      debugPrint('Navigating to stories: $targetRoute');
    } else if (path == '/wallet') {
      // Wallet: weylo://wallet
      targetRoute = '/wallet';
      debugPrint('Navigating to wallet: $targetRoute');
    } else if (path == '/premium') {
      // Premium: weylo://premium
      targetRoute = '/premium';
      debugPrint('Navigating to premium: $targetRoute');
    } else {
      // Default to home
      debugPrint('Unknown deep link pattern, going to home');
      targetRoute = '/';
    }

    // Navigate using the router
    try {
      if (_router != null) {
        _router!.push(targetRoute);
        debugPrint('Navigation successful using router');
      } else {
        context.push(targetRoute);
        debugPrint('Navigation successful using context');
      }
    } catch (e) {
      debugPrint('Error navigating to $targetRoute: $e');
      // Try fallback navigation
      try {
        context.go('/');
      } catch (e2) {
        debugPrint('Fallback navigation also failed: $e2');
      }
    }
  }

  /// Generate a shareable link for a post
  static String getPostShareLink(int postId) {
    return 'https://weylo.app/post/$postId';
  }

  /// Generate a shareable link for a user profile
  static String getProfileShareLink(String username) {
    return 'https://weylo.app/u/$username';
  }

  /// Generate an app deep link for a post
  static String getPostDeepLink(int postId) {
    return 'weylo://post/$postId';
  }

  /// Generate an app deep link for a user profile
  static String getProfileDeepLink(String username) {
    return 'weylo://u/$username';
  }

  /// Generate a shareable link for anonymous messages (web)
  static String getAnonymousMessageShareLink(String username) {
    return 'https://weylo.app/u/$username';
  }

  /// Generate an app deep link for anonymous messages
  static String getAnonymousMessageDeepLink(String username) {
    return 'weylo://m/$username';
  }
}
