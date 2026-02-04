import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/message_service.dart';

class MessagesProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  List<AnonymousMessage> _receivedMessages = [];
  List<AnonymousMessage> _sentMessages = [];
  MessageStats? _stats;
  bool _isLoading = false;
  bool _hasError = false;

  List<AnonymousMessage> get receivedMessages => _receivedMessages;
  List<AnonymousMessage> get sentMessages => _sentMessages;
  MessageStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final results = await Future.wait([
        _messageService.getInbox(),
        _messageService.getSentMessages(),
        _messageService.getStats(),
      ]);

      _receivedMessages = (results[0] as PaginatedMessages).messages;
      _sentMessages = (results[1] as PaginatedMessages).messages;
      _stats = results[2] as MessageStats;
    } catch (e) {
      _hasError = true;
      if (kDebugMode) print('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadData();
  }
}
