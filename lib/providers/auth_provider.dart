import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/websocket_service.dart';
import '../core/errors/exceptions.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  final WebSocketService _webSocket = WebSocketService();
  final UserService _userService = UserService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  User? get currentUser => _user; // Alias for user
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getSavedUser();
        if (_user != null) {
          _status = AuthStatus.authenticated;
          _connectWebSocket();
        } else {
          // Token exists but no user data, fetch from server
          try {
            _user = await _authService.getCurrentUser();
            _status = AuthStatus.authenticated;
            _connectWebSocket();
          } catch (e) {
            await _authService.logout();
            _status = AuthStatus.unauthenticated;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        _status = AuthStatus.authenticated;
        _connectWebSocket();
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _error = response.message ?? 'Erreur de connexion';
        notifyListeners();
        return false;
      }
    } on ValidationException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    String? lastName,
    required String username,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.user != null) {
        _user = response.user;
        _status = AuthStatus.authenticated;
        _connectWebSocket();
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _error = response.message ?? 'Erreur d\'inscription';
        notifyListeners();
        return false;
      }
    } on ValidationException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
      if (e.errors != null) {
        final firstError = e.errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          _error = firstError.first.toString();
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _webSocket.disconnect();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  void updateUser(User user) {
    _user = user;
    _storage.saveUser(user);
    notifyListeners();
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (_user == null) return;

    // Merge with existing settings
    final currentSettings = _user!.settings ?? UserSettings();
    final newSettings = UserSettings(
      notificationsEnabled:
          settings['notifications_enabled'] ??
          currentSettings.notificationsEnabled,
      emailNotifications:
          settings['email_notifications'] ?? currentSettings.emailNotifications,
      pushNotifications:
          settings['push_notifications'] ?? currentSettings.pushNotifications,
      showOnlineStatus:
          settings['show_online_status'] ?? currentSettings.showOnlineStatus,
      allowAnonymousMessages: false,
      showNameOnPosts:
          settings['show_name_on_posts'] ?? currentSettings.showNameOnPosts,
      showPhotoOnPosts:
          settings['show_photo_on_posts'] ?? currentSettings.showPhotoOnPosts,
      language: settings['language'] ?? currentSettings.language,
      theme: settings['theme'] ?? currentSettings.theme,
    );

    _user = await _userService.updateSettings(newSettings);
    notifyListeners();
  }

  void _connectWebSocket() {
    if (_user != null) {
      _webSocket.connect();
      _webSocket.subscribeToUserChannel(_user!.id);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
