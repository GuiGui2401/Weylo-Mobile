import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/confession.dart';
import '../models/user.dart';
import '../services/confession_service.dart';
import '../services/pusher_service.dart';
import '../services/user_service.dart';

class FeedProvider extends ChangeNotifier {
  final ConfessionService _confessionService = ConfessionService();
  final PusherService _pusherService = PusherService();
  final UserService _userService = UserService();

  List<Confession> _confessions = [];
  List<User> _contactRecommendations = [];
  bool _isLoading = false;
  bool _isLoadingRecommendations = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _recommendationsError;
  bool _contactsPermissionDenied = false;

  List<Confession> get confessions => _confessions;
  List<User> get contactRecommendations => _contactRecommendations;
  bool get isLoading => _isLoading;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get recommendationsError => _recommendationsError;
  bool get contactsPermissionDenied => _contactsPermissionDenied;

  FeedProvider() {
    _setupRealTimeUpdates();
  }

  void _setupRealTimeUpdates() {
    _pusherService.subscribeToPublicFeed();
    _pusherService.onEvent.listen((event) {
      if (event.isNewConfession) {
        _handleNewConfession(event.data);
      } else if (event.isConfessionLiked) {
        _handleConfessionLiked(event.data);
      }
    });
  }

  void _handleNewConfession(String data) {
    try {
      // Parse and add new confession at the top
      // Implementation depends on the event data format
      refresh();
    } catch (e) {
      if (kDebugMode) print('Error handling new confession: $e');
    }
  }

  void _handleConfessionLiked(String data) {
    // Update like count for confession
    notifyListeners();
  }

  Future<void> loadConfessions({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _confessionService.getConfessions(
        page: _currentPage,
      );

      if (refresh) {
        _confessions = response.confessions;
      } else {
        _confessions.addAll(response.confessions);
      }

      _hasMore = response.hasMore;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error loading confessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContactRecommendations({bool requestPermission = false}) async {
    if (_isLoadingRecommendations) return;

    _isLoadingRecommendations = true;
    _recommendationsError = null;
    notifyListeners();

    try {
      bool hasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (!hasPermission) {
        _contactsPermissionDenied = true;
        _contactRecommendations = [];
        return;
      }
      _contactsPermissionDenied = false;

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final phones = contacts
          .expand((contact) => contact.phones)
          .map((phone) => phone.number)
          .where((number) => number.trim().isNotEmpty)
          .toList();

      if (phones.isEmpty) {
        _contactRecommendations = [];
        return;
      }

      _contactRecommendations =
          await _userService.getRecommendationsFromContacts(phones);
    } catch (e) {
      _recommendationsError = e.toString();
      if (kDebugMode) print('Error loading recommendations: $e');
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadConfessions(refresh: true);
  }

  Future<void> loadMore() async {
    await loadConfessions();
  }

  Future<bool> likeConfession(int confessionId) async {
    try {
      await _confessionService.likeConfession(confessionId);
      final index = _confessions.indexWhere((c) => c.id == confessionId);
      if (index != -1) {
        final confession = _confessions[index];
        _confessions[index] = confession.copyWith(
          isLiked: true,
          likesCount: confession.likesCount + 1,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error liking confession: $e');
      return false;
    }
  }

  Future<bool> unlikeConfession(int confessionId) async {
    try {
      await _confessionService.unlikeConfession(confessionId);
      final index = _confessions.indexWhere((c) => c.id == confessionId);
      if (index != -1) {
        final confession = _confessions[index];
        _confessions[index] = confession.copyWith(
          isLiked: false,
          likesCount: confession.likesCount - 1,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error unliking confession: $e');
      return false;
    }
  }

  Future<bool> createConfession({
    required String content,
    bool isPublic = true,
    String? recipientUsername,
  }) async {
    try {
      final newConfession = await _confessionService.createConfession(
        content: content,
        type: isPublic ? 'public' : 'private',
        recipientUsername: recipientUsername,
      );

      if (isPublic) {
        // Add to top of feed for public confessions
        _confessions.insert(0, newConfession);
        notifyListeners();
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Error creating confession: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
