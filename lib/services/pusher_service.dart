import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter? _pusher;
  final StorageService _storage = StorageService();

  final _messageController = StreamController<PusherEvent>.broadcast();
  final _connectionController = StreamController<String>.broadcast();

  Stream<PusherEvent> get onEvent => _messageController.stream;
  Stream<String> get onConnectionStateChange => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _currentUserId;
  final Set<String> _subscribedChannels = {};

  Future<void> connect({String? userId}) async {
    if (_isConnected) return;

    try {
      final token = await _storage.getToken();
      if (token == null) {
        if (kDebugMode) print('Pusher: No token available');
        return;
      }

      _currentUserId = userId;
      _pusher = PusherChannelsFlutter.getInstance();

      // Initialize with Reverb/custom host configuration
      await _pusher!.init(
        apiKey: ApiConstants.reverbAppKey,
        cluster: 'mt1', // Required but not used for custom host
        useTLS: ApiConstants.reverbScheme == 'https',
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
        onEvent: _onEvent,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: (String channelName, String socketId, dynamic options) async {
          // Custom authorizer for private/presence channels
          return {
            'auth': token,
            'channel_data': {
              'user_id': userId ?? 'anonymous',
            },
          };
        },
      );

      await _pusher!.connect();

      if (kDebugMode) print('Pusher: Connecting...');
    } catch (e) {
      if (kDebugMode) print('Pusher: Connection error - $e');
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    if (kDebugMode) print('Pusher: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
    _connectionController.add(currentState);

    // Resubscribe to channels after reconnection
    if (_isConnected && _subscribedChannels.isNotEmpty) {
      for (var channel in _subscribedChannels) {
        _resubscribe(channel);
      }
    }
  }

  void _onError(String message, int? code, dynamic e) {
    if (kDebugMode) print('Pusher Error: $message (code: $code)');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    if (kDebugMode) print('Pusher: Subscribed to $channelName');
    _subscribedChannels.add(channelName);
  }

  void _onSubscriptionError(String message, dynamic e) {
    if (kDebugMode) print('Pusher: Subscription error - $message');
  }

  void _onEvent(PusherEvent event) {
    if (kDebugMode) print('Pusher Event: ${event.eventName} on ${event.channelName}');
    _messageController.add(event);
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    if (kDebugMode) print('Pusher: Member added to $channelName: ${member.userId}');
    _messageController.add(PusherEvent(
      channelName: channelName,
      eventName: 'member_added',
      data: member.userInfo.toString(),
      userId: member.userId,
    ));
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    if (kDebugMode) print('Pusher: Member removed from $channelName: ${member.userId}');
    _messageController.add(PusherEvent(
      channelName: channelName,
      eventName: 'member_removed',
      data: member.userInfo.toString(),
      userId: member.userId,
    ));
  }

  Future<void> _resubscribe(String channelName) async {
    try {
      await _pusher?.subscribe(channelName: channelName);
    } catch (e) {
      if (kDebugMode) print('Pusher: Resubscription error - $e');
    }
  }

  // Channel subscription methods
  Future<void> subscribeToUserChannel(int userId) async {
    final channelName = 'private-user.$userId';
    if (!_subscribedChannels.contains(channelName)) {
      await _pusher?.subscribe(channelName: channelName);
    }
  }

  Future<void> subscribeToConversation(int conversationId) async {
    final channelName = 'conversation.$conversationId';
    if (!_subscribedChannels.contains(channelName)) {
      await _pusher?.subscribe(channelName: channelName);
    }
  }

  Future<void> unsubscribeFromConversation(int conversationId) async {
    final channelName = 'conversation.$conversationId';
    if (_subscribedChannels.contains(channelName)) {
      await _pusher?.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
    }
  }

  Future<void> subscribeToGroup(int groupId) async {
    final channelName = 'group.$groupId';
    if (!_subscribedChannels.contains(channelName)) {
      await _pusher?.subscribe(channelName: channelName);
    }
  }

  Future<void> unsubscribeFromGroup(int groupId) async {
    final channelName = 'group.$groupId';
    if (_subscribedChannels.contains(channelName)) {
      await _pusher?.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
    }
  }

  Future<void> subscribeToPublicFeed() async {
    const channelName = 'confessions';
    if (!_subscribedChannels.contains(channelName)) {
      await _pusher?.subscribe(channelName: channelName);
    }
  }

  Future<void> subscribeToNotifications(int userId) async {
    final channelName = 'private-notifications.$userId';
    if (!_subscribedChannels.contains(channelName)) {
      await _pusher?.subscribe(channelName: channelName);
    }
  }

  // Send client event (for presence channels)
  Future<void> trigger(String channelName, String eventName, dynamic data) async {
    await _pusher?.trigger(PusherEvent(
      channelName: channelName,
      eventName: eventName,
      data: data.toString(),
    ));
  }

  Future<void> disconnect() async {
    for (var channel in _subscribedChannels.toList()) {
      await _pusher?.unsubscribe(channelName: channel);
    }
    _subscribedChannels.clear();
    await _pusher?.disconnect();
    _isConnected = false;
    if (kDebugMode) print('Pusher: Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

// Extension to handle Pusher events in a type-safe way
extension PusherEventExtension on PusherEvent {
  String get _normalizedEvent =>
      eventName.toLowerCase().replaceAll(RegExp(r'[\._-]'), '');

  bool get isChatMessage => _normalizedEvent == 'chatmessagesent';
  bool get isGroupMessage => _normalizedEvent == 'groupmessagesent';
  bool get isGiftSent => _normalizedEvent == 'giftsent';
  bool get isNewMessage => _normalizedEvent == 'messagesent';
  bool get isNewConfession => _normalizedEvent == 'confessioncreated';
  bool get isConfessionLiked => _normalizedEvent == 'confessionliked';
  bool get isNotification => _normalizedEvent == 'notificationreceived';
  bool get isPresenceUpdate => _normalizedEvent == 'userpresenceupdated';
  bool get isTyping => _normalizedEvent == 'clienttyping';
  bool get isStopTyping => _normalizedEvent == 'clientstoptyping';
}
