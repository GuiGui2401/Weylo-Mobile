import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/widgets/gifts/gift_bottom_sheet.dart';

class SendGiftScreen extends StatefulWidget {
  final int conversationId;

  const SendGiftScreen({super.key, required this.conversationId});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  final ChatService _chatService = ChatService();
  Conversation? _conversation;
  bool _isLoading = true;
  String? _error;
  bool _sheetShown = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      final conversation = await _chatService.getConversation(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _isLoading = false;
      });
      _tryShowGiftSheet(conversation);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _tryShowGiftSheet(Conversation conversation) {
    if (_sheetShown) return;
    final recipient = conversation.otherParticipant;
    if (recipient == null) {
      setState(() {
        _error = 'Impossible de déterminer le destinataire';
      });
      return;
    }

    _sheetShown = true;
    GiftBottomSheet.show(
      context,
      recipientId: recipient.id,
      recipientUsername: recipient.username,
      conversationId: conversation.id,
    ).whenComplete(() {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer un cadeau'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : const Text('Chargement...'),
      ),
    );
  }
}
