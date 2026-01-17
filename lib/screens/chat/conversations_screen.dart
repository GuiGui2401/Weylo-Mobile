import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/stories/stories_bar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final RefreshController _refreshController = RefreshController();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final conversations = await _chatService.getConversations();
      setState(() {
        _conversations = conversations;
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
    await _loadConversations();
    _refreshController.refreshCompleted();
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ConversationSearchSheet(conversations: _conversations),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stories bar
          const StoriesBar(),
          // Conversations list
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _hasError
                    ? ErrorState(onRetry: _loadConversations)
                    : _conversations.isEmpty
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: 'Aucune conversation',
                            subtitle: 'Commencez une conversation avec quelqu\'un',
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                return _ConversationTile(
                                  conversation: _conversations[index],
                                  onTap: () {
                                    context.push('/chat/${_conversations[index].id}');
                                  },
                                );
                              },
                            ),
                          ),
          ),
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
          heroTag: 'conversations_fab',
          onPressed: () {
            // Start new conversation
            context.push('/new-chat');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}

class _ConversationSearchSheet extends StatefulWidget {
  final List<Conversation> conversations;

  const _ConversationSearchSheet({required this.conversations});

  @override
  State<_ConversationSearchSheet> createState() => _ConversationSearchSheetState();
}

class _ConversationSearchSheetState extends State<_ConversationSearchSheet> {
  String _searchQuery = '';
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
  }

  void _filterConversations(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
        _filteredConversations = widget.conversations.where((conversation) {
          final otherUser = conversation.getOtherParticipant(currentUserId);
          final username = otherUser?.username.toLowerCase() ?? '';
          final fullName = otherUser?.fullName.toLowerCase() ?? '';
          final lastMessage = conversation.lastMessage?.content.toLowerCase() ?? '';

          return username.contains(_searchQuery) ||
                 fullName.contains(_searchQuery) ||
                 lastMessage.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les conversations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterConversations,
            ),
          ),
          Expanded(
            child: _filteredConversations.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                        ? 'Aucune conversation'
                        : 'Aucun résultat trouvé',
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: _filteredConversations[index],
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/chat/${_filteredConversations[index].id}');
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onTap;

  const _ConversationTile({
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final otherUser = conversation.getOtherParticipant(currentUserId);
    final flameEmoji = conversation.getFlameEmoji();

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          AvatarWidget(
            imageUrl: otherUser?.avatar,
            name: otherUser?.fullName,
            size: 52,
          ),
          if (!conversation.isIdentityRevealed)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_off,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.isIdentityRevealed
                  ? otherUser?.fullName ?? 'Utilisateur'
                  : 'Anonyme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (flameEmoji.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(flameEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 2),
            Text(
              '${conversation.streakCount}',
              style: TextStyle(
                fontSize: 12,
                color: Helpers.getFlameColor(conversation.flameLevel.name),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: conversation.unreadCount > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.lastMessageAt != null
                ? Helpers.getTimeAgo(conversation.lastMessageAt!)
                : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
