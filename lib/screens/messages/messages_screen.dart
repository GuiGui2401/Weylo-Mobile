import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../services/deep_link_service.dart';
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
  final RefreshController _receivedRefreshController = RefreshController();
  final RefreshController _sentRefreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receivedRefreshController.dispose();
    _sentRefreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh({required bool isReceived}) async {
    await context.read<MessagesProvider>().refresh();
    if (isReceived) {
      _receivedRefreshController.refreshCompleted();
    } else {
      _sentRefreshController.refreshCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = context.watch<MessagesProvider>().stats;
    final username = context.watch<AuthProvider>().user?.username;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.messagesTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(username != null ? 100 : 48),
          child: Column(
            children: [
              if (username != null)
                _buildShareLinkBanner(username, l10n),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.inboxTabReceived),
                        if (stats != null && stats.unreadCount > 0) ...[
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
                              '${stats.unreadCount}',
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
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/fond.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Consumer<MessagesProvider>(
          builder: (context, messagesProvider, _) {
            if (messagesProvider.isLoading &&
                messagesProvider.receivedMessages.isEmpty) {
              return const LoadingWidget();
            }
            if (messagesProvider.hasError) {
              return ErrorState(
                onRetry: () => messagesProvider.refresh(),
              );
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesList(
                  messagesProvider.receivedMessages,
                  isReceived: true,
                ),
                _buildMessagesList(
                  messagesProvider.sentMessages,
                  isReceived: false,
                ),
              ],
            );
          },
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

  Widget _buildShareLinkBanner(String username, AppLocalizations l10n) {
    final shareUrl = DeepLinkService.getAnonymousMessageShareLink(username);
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (mounted) {
          Helpers.showSuccessSnackBar(context, l10n.copyToClipboardSuccess);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shareUrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (mounted) {
                  Helpers.showSuccessSnackBar(context, l10n.copyToClipboardSuccess);
                }
              },
              child: const Icon(Icons.copy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Share.share(shareUrl),
              child: const Icon(Icons.share, color: Colors.white, size: 18),
            ),
          ],
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
      titleColor: Colors.white,
      subtitleColor: Colors.white70,
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
