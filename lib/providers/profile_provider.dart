import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/confession.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import '../services/confession_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final FollowService _followService = FollowService();
  final ConfessionService _confessionService = ConfessionService();

  User? _profileUser;
  List<Confession> _userConfessions = [];
  List<Confession> _likedConfessions = [];
  List<User> _followers = [];
  List<User> _following = [];
  bool _isLoading = false;
  bool _isFollowLoading = false;
  String? _error;

  // Pagination
  int _confessionsPage = 1;
  int _likedPage = 1;
  int _followersPage = 1;
  int _followingPage = 1;
  bool _hasMoreConfessions = true;
  bool _hasMoreLiked = true;
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowing = true;

  User? get profileUser => _profileUser;
  List<Confession> get userConfessions => _userConfessions;
  List<Confession> get likedConfessions => _likedConfessions;
  List<User> get followers => _followers;
  List<User> get following => _following;
  bool get isLoading => _isLoading;
  bool get isFollowLoading => _isFollowLoading;
  String? get error => _error;
  bool get hasMoreConfessions => _hasMoreConfessions;
  bool get hasMoreLiked => _hasMoreLiked;
  bool get hasMoreFollowers => _hasMoreFollowers;
  bool get hasMoreFollowing => _hasMoreFollowing;

  /// Load user profile by username
  Future<void> loadProfile(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileUser = await _userService.getUserByUsername(username);

      // Reset pagination
      _confessionsPage = 1;
      _hasMoreConfessions = true;
      _userConfessions = [];

      // Load user's confessions using username directly (not ID)
      if (_profileUser != null) {
        await loadUserConfessionsByUsername(_profileUser!.username);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's confessions by user ID (legacy method)
  Future<void> loadUserConfessions(int userId, {bool loadMore = false}) async {
    if (!_hasMoreConfessions && loadMore) return;

    try {
      if (kDebugMode) print('ProfileProvider: Loading confessions for user $userId');

      final response = await _confessionService.getUserConfessions(
        userId,
        page: loadMore ? _confessionsPage : 1,
      );

      if (kDebugMode) {
        print('ProfileProvider: Loaded ${response.confessions.length} confessions');
        print('ProfileProvider: Has more: ${response.hasMore}');
        print('ProfileProvider: Page: ${response.currentPage}/${response.lastPage}');
      }

      if (loadMore) {
        _userConfessions.addAll(response.confessions);
      } else {
        _userConfessions = response.confessions;
        _confessionsPage = 1;
      }

      _hasMoreConfessions = response.hasMore;
      _confessionsPage++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('ProfileProvider: Error loading user confessions: $e');
        print('ProfileProvider: Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Load user's confessions by username (preferred method)
  Future<void> loadUserConfessionsByUsername(String username, {bool loadMore = false}) async {
    if (!_hasMoreConfessions && loadMore) return;

    try {
      if (kDebugMode) print('ProfileProvider: Loading confessions for user @$username');

      final response = await _confessionService.getUserConfessionsByUsername(
        username,
        page: loadMore ? _confessionsPage : 1,
      );

      if (kDebugMode) {
        print('ProfileProvider: Loaded ${response.confessions.length} confessions');
        print('ProfileProvider: Has more: ${response.hasMore}');
        print('ProfileProvider: Page: ${response.currentPage}/${response.lastPage}');
      }

      if (loadMore) {
        _userConfessions.addAll(response.confessions);
      } else {
        _userConfessions = response.confessions;
        _confessionsPage = 1;
      }

      _hasMoreConfessions = response.hasMore;
      _confessionsPage++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('ProfileProvider: Error loading user confessions by username: $e');
        print('ProfileProvider: Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Load liked confessions
  Future<void> loadLikedConfessions({bool loadMore = false}) async {
    if (!_hasMoreLiked && loadMore) return;

    try {
      final response = await _confessionService.getLikedConfessions(
        page: loadMore ? _likedPage : 1,
      );

      if (loadMore) {
        _likedConfessions.addAll(response.confessions);
      } else {
        _likedConfessions = response.confessions;
        _likedPage = 1;
      }

      _hasMoreLiked = response.hasMore;
      _likedPage++;
      notifyListeners();
    } catch (e) {
      // 404 errors are expected when there are no liked confessions yet
      // Silently handle these cases without logging
      if (!e.toString().contains('404')) {
        if (kDebugMode) print('Error loading liked confessions: $e');
      }
    }
  }

  /// Follow a user
  Future<bool> followUser(String username) async {
    _isFollowLoading = true;
    notifyListeners();

    try {
      final response = await _followService.followUser(username);

      if (response['success'] == true && _profileUser != null) {
        _profileUser = _profileUser!.copyWith(
          isFollowing: true,
          followersCount: _profileUser!.followersCount + 1,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error following user: $e');
      return false;
    } finally {
      _isFollowLoading = false;
      notifyListeners();
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String username) async {
    _isFollowLoading = true;
    notifyListeners();

    try {
      final response = await _followService.unfollowUser(username);

      if (response['success'] == true && _profileUser != null) {
        _profileUser = _profileUser!.copyWith(
          isFollowing: false,
          followersCount: _profileUser!.followersCount - 1,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error unfollowing user: $e');
      return false;
    } finally {
      _isFollowLoading = false;
      notifyListeners();
    }
  }

  /// Load followers list
  Future<void> loadFollowers(String username, {bool loadMore = false}) async {
    if (!_hasMoreFollowers && loadMore) return;

    try {
      final response = await _followService.getFollowers(
        username,
        page: loadMore ? _followersPage : 1,
      );

      final List<dynamic> data = response['data']['data'] ?? [];
      final newFollowers = data.map((json) => User.fromJson(json)).toList();

      if (loadMore) {
        _followers.addAll(newFollowers);
      } else {
        _followers = newFollowers;
        _followersPage = 1;
      }

      _hasMoreFollowers = newFollowers.length >= 20;
      _followersPage++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading followers: $e');
    }
  }

  /// Load following list
  Future<void> loadFollowing(String username, {bool loadMore = false}) async {
    if (!_hasMoreFollowing && loadMore) return;

    try {
      final response = await _followService.getFollowing(
        username,
        page: loadMore ? _followingPage : 1,
      );

      final List<dynamic> data = response['data']['data'] ?? [];
      final newFollowing = data.map((json) => User.fromJson(json)).toList();

      if (loadMore) {
        _following.addAll(newFollowing);
      } else {
        _following = newFollowing;
        _followingPage = 1;
      }

      _hasMoreFollowing = newFollowing.length >= 20;
      _followingPage++;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading following: $e');
    }
  }

  void clear() {
    _profileUser = null;
    _userConfessions = [];
    _likedConfessions = [];
    _followers = [];
    _following = [];
    _error = null;
    notifyListeners();
  }
}
