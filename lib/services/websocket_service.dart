import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_constants.dart';
import 'api_client.dart';
import 'storage_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  final StorageService _storage = StorageService();
  final ApiClient _apiClient = ApiClient();

  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _socketId;

  final Set<String> _subscribedChannels = {};

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _storage.getToken();
      if (token == null) {
        if (kDebugMode) print('WebSocket: No token available');
        return;
      }

      final wsUri = Uri.parse('${ApiConstants.wsUrl}/app/${ApiConstants.reverbAppKey}').replace(
        queryParameters: {
          'protocol': '7',
          'client': 'dart',
          'version': '2.0',
          'flash': 'false',
          'token': token,
        },
      );

      _channel = WebSocketChannel.connect(wsUri);

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();

      if (kDebugMode) print('WebSocket: Connected');
    } catch (e) {
      if (kDebugMode) print('WebSocket: Connection error - $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data as String);

      // Handle Pusher protocol messages
      Map<String, dynamic> json;
      if (decoded is String) {
        json = jsonDecode(decoded) as Map<String, dynamic>;
      } else if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else {
        if (kDebugMode) print('WebSocket: Unexpected message type - ${decoded.runtimeType}');
        return;
      }

      final event = json['event'] as String?;

      if (kDebugMode) print('WebSocket: Received event: $event');

      // Handle Pusher connection established
      if (event == 'pusher:connection_established') {
        final eventData = json['data'];
        Map<String, dynamic> dataMap;
        if (eventData is String) {
          dataMap = jsonDecode(eventData) as Map<String, dynamic>;
        } else {
          dataMap = eventData as Map<String, dynamic>;
        }
        _socketId = dataMap['socket_id'] as String?;
        if (kDebugMode) print('WebSocket: Socket ID: $_socketId');

        // Resubscribe to channels after reconnection
        _resubscribeToChannels();
        return;
      }

      // Handle subscription succeeded
      if (event == 'pusher_internal:subscription_succeeded') {
        final channel = json['channel'] as String?;
        if (kDebugMode) print('WebSocket: Subscribed to $channel');
        return;
      }

      // Handle Pusher ping/pong
      if (event == 'pusher:ping') {
        _sendPusherPong();
        return;
      }

      if (event == 'pusher:pong') {
        return;
      }

      // Handle Pusher error
      if (event == 'pusher:error') {
        final errorData = json['data'];
        if (kDebugMode) print('WebSocket: Pusher error - $errorData');
        return;
      }

      // Handle application events
      final message = WebSocketMessage.fromJson(json);
      _messageController.add(message);

    } catch (e) {
      if (kDebugMode) print('WebSocket: Error parsing message - $e');
    }
  }

  void _onDisconnected() {
    if (kDebugMode) print('WebSocket: Disconnected');
    _isConnected = false;
    _socketId = null;
    _connectionController.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    if (kDebugMode) print('WebSocket: Error - $error');
    _isConnected = false;
    _socketId = null;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendPusherPing();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendPusherPing() {
    _sendRaw({'event': 'pusher:ping', 'data': {}});
  }

  void _sendPusherPong() {
    _sendRaw({'event': 'pusher:pong', 'data': {}});
  }

  void _sendRaw(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) print('WebSocket: Cannot send - not connected');
      return;
    }

    try {
      final encoded = jsonEncode(message);
      _channel!.sink.add(encoded);
    } catch (e) {
      if (kDebugMode) print('WebSocket: Error sending message - $e');
    }
  }

  void send(String event, Map<String, dynamic> data) {
    _sendRaw({
      'event': event,
      'data': data,
    });
  }

  void _resubscribeToChannels() {
    for (final channel in _subscribedChannels) {
      _subscribeToChannelInternal(channel);
    }
  }

  void _subscribeToChannelInternal(String channel) async {
    if (_socketId == null) {
      if (kDebugMode) print('WebSocket: Socket ID not available yet, delaying subscribe for $channel');
      return;
    }

    try {
      final auth = await _authorizeChannel(channel);
      final payload = {
        'event': 'pusher:subscribe',
        'data': {
          'channel': channel,
          'auth': auth.auth,
          if (auth.channelData != null) 'channel_data': auth.channelData,
        },
      };
      _sendRaw(payload);
    } catch (e) {
      if (kDebugMode) print('WebSocket: Failed to authorize channel $channel - $e');
    }
  }

  Future<_ChannelAuth> _authorizeChannel(String channel) async {
    final socketId = _socketId;
    if (socketId == null) {
      throw StateError('WebSocket: Cannot authorize channel without socket id');
    }

    final response = await _apiClient.post(
      ApiConstants.broadcastingAuth,
      data: {
        'socket_id': socketId,
        'channel_name': channel,
      },
    );

    final payload = response.data;
    return _ChannelAuth(
      auth: payload['auth'] ?? '',
      channelData: payload['channel_data'],
    );
  }

  void subscribeToChannel(String channel) {
    _subscribedChannels.add(channel);
    if (_isConnected && _socketId != null) {
      _subscribeToChannelInternal(channel);
    }
  }

  void unsubscribeFromChannel(String channel) {
    _subscribedChannels.remove(channel);
    if (_isConnected) {
      _sendRaw({
        'event': 'pusher:unsubscribe',
        'data': {
          'channel': channel,
        },
      });
    }
  }

  void subscribeToUserChannel(int userId) {
    subscribeToChannel('private-user.$userId');
  }

  void subscribeToConversation(int conversationId) {
    subscribeToChannel('conversation.$conversationId');
  }

  void unsubscribeFromConversation(int conversationId) {
    unsubscribeFromChannel('conversation.$conversationId');
  }

  void subscribeToGroup(int groupId) {
    subscribeToChannel('group.$groupId');
  }

  void unsubscribeFromGroup(int groupId) {
    unsubscribeFromChannel('group.$groupId');
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _isConnected = false;
    _socketId = null;
    _connectionController.add(false);
    if (kDebugMode) print('WebSocket: Manually disconnected');
  }

  void dispose() {
    disconnect();
    _subscribedChannels.clear();
    _messageController.close();
    _connectionController.close();
  }
}

class _ChannelAuth {
  final String auth;
  final dynamic channelData;

  const _ChannelAuth({required this.auth, this.channelData});
}

class WebSocketMessage {
  final String event;
  final String? channel;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.event,
    this.channel,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    // Parse data - can be a String (JSON) or Map
    Map<String, dynamic> parsedData = {};
    final rawData = json['data'];
    if (rawData is String && rawData.isNotEmpty) {
      try {
        parsedData = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        parsedData = {'raw': rawData};
      }
    } else if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    }

    return WebSocketMessage(
      event: json['event'] ?? '',
      channel: json['channel'],
      data: parsedData,
    );
  }

  String get _normalizedEvent =>
      event.toLowerCase().replaceAll(RegExp(r'[\._-]'), '');

  bool _matchesEvent(String value) => _normalizedEvent == value;

  bool get isChatMessage =>
      _matchesEvent('chatmessagesent') || _matchesEvent('messagesent');

  bool get isGroupMessage =>
      _matchesEvent('groupmessagesent') || _matchesEvent('groupmessage');

  bool get isGiftSent => _matchesEvent('giftsent');
  bool get isNewMessage => _matchesEvent('messagesent');

  bool get isPresenceUpdate =>
      _matchesEvent('userpresenceupdated') ||
      _matchesEvent('presenceevent') ||
      _matchesEvent('presence');

  bool get isTyping =>
      _matchesEvent('clienttyping') || _matchesEvent('typingevent');

  bool get isMessageStatusUpdate =>
      _matchesEvent('messagestatusupdated') || _matchesEvent('messagestatus');
}
