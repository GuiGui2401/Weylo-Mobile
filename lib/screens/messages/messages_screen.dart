import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../services/widgets/common/widgets.dart';
import '../../services/widgets/messages/message_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MessageService _messageService = MessageService();
  final RefreshController _refreshController = RefreshController();

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
    _refreshController.dispose();
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

  Future<void> _onRefresh() async {
    await _loadData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages anonymes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (user != null) {
                final link = 'https://weylo.app/${user.username}';
                Share.share(
                  'Envoyez-moi un message anonyme sur Weylo! $link',
                  subject: 'Mon lien Weylo',
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Reçus'),
                  if (_stats != null && _stats!.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const Tab(text: 'Envoyés'),
          ],
        ),
      ),
      body: _isLoading
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'messages_fab',
          onPressed: () => context.push('/send-message'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<AnonymousMessage> messages, {required bool isReceived}) {
    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.mail_outline,
        title: isReceived ? 'Aucun message reçu' : 'Aucun message envoyé',
        subtitle: isReceived
            ? 'Partagez votre lien pour recevoir des messages anonymes'
            : 'Envoyez votre premier message anonyme',
        buttonText: isReceived ? 'Partager mon lien' : 'Envoyer un message',
        onButtonPressed: () {
          if (isReceived) {
            final user = context.read<AuthProvider>().user;
            if (user != null) {
              final link = 'https://weylo.app/${user.username}';
              Share.share(
                'Envoyez-moi un message anonyme sur Weylo! $link',
                subject: 'Mon lien Weylo',
              );
            }
          } else {
            context.push('/send-message');
          }
        },
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: ListView.separated(
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
