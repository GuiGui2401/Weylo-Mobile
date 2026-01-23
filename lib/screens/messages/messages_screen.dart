import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/message.dart';
import '../../services/message_service.dart';
import '../../services/widgets/common/widgets.dart';
import '../../services/widgets/messages/message_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MessageService _messageService = MessageService();
  final RefreshController _receivedRefreshController = RefreshController();
  final RefreshController _sentRefreshController = RefreshController();

  List<AnonymousMessage> _receivedMessages = [];
  List<AnonymousMessage> _sentMessages = [];
  bool _isLoading = true;
  bool _hasError = false;
  MessageStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receivedRefreshController.dispose();
    _sentRefreshController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _messageService.getInbox(),
        _messageService.getSentMessages(),
        _messageService.getStats(),
      ]);

      setState(() {
        _receivedMessages = (results[0] as PaginatedMessages).messages;
        _sentMessages = (results[1] as PaginatedMessages).messages;
        _stats = results[2] as MessageStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh({required bool isReceived}) async {
    await _loadData();
    if (isReceived) {
      _receivedRefreshController.refreshCompleted();
    } else {
      _sentRefreshController.refreshCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.messagesTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.inboxTabReceived),
                  if (_stats != null && _stats!.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_stats!.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: l10n.inboxTabSent),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fond.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const LoadingWidget()
            : _hasError
            ? ErrorState(onRetry: _loadData)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMessagesList(_receivedMessages, isReceived: true),
                  _buildMessagesList(_sentMessages, isReceived: false),
                ],
              ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'messages_fab',
          onPressed: () => context.push('/send-message'),
          backgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.edit,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    List<AnonymousMessage> messages, {
    required bool isReceived,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = isReceived
        ? _receivedRefreshController
        : _sentRefreshController;
    final emptyState = EmptyState(
      icon: Icons.mail_outline,
      title: isReceived ? l10n.emptyInboxTitle : l10n.emptySentTitle,
      subtitle: isReceived ? l10n.emptyInboxSubtitle : l10n.emptySentSubtitle,
      buttonText: isReceived ? l10n.emptyInboxButton : l10n.emptySentButton,
      onButtonPressed: () => context.push('/send-message'),
    );

    return SmartRefresher(
      controller: controller,
      enablePullDown: true,
      onRefresh: () => _onRefresh(isReceived: isReceived),
      child: messages.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [emptyState],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageCard(
                  message: message,
                  isReceived: isReceived,
                  onTap: () => context.push('/message/${message.id}'),
                );
              },
            ),
    );
  }
}
