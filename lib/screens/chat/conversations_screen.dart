import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import '../../services/widgets/common/widgets.dart';
import '../../services/widgets/stories/stories_bar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final RefreshController _refreshController = RefreshController();
  final WebSocketService _webSocket = WebSocketService();
  StreamSubscription<WebSocketMessage>? _messageSubscription;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasLoadedForSession = false;

  @override
  void initState() {
    super.initState();
    _subscribeToWebSocketEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAuthenticated) {
      if (!_hasLoadedForSession) {
        _hasLoadedForSession = true;
        _loadConversations();
      }
    } else {
      if (_hasLoadedForSession) {
        _hasLoadedForSession = false;
        setState(() {
          _conversations = [];
          _isLoading = false;
          _hasError = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
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
        _sortConversations();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _subscribeToWebSocketEvents() {
    _webSocket.connect();
    _messageSubscription = _webSocket.messages.listen(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    if (!message.isChatMessage && !message.isNewMessage) return;
    final chatMessage = ChatMessage.fromJson(message.data);
    _applyIncomingMessage(chatMessage);
  }

  Future<void> _applyIncomingMessage(ChatMessage chatMessage) async {
    if (!mounted) return;
    final conversationId = chatMessage.conversationId;
    if (conversationId == 0) return;

    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final existingIndex = _conversations.indexWhere(
      (conv) => conv.id == conversationId,
    );

    if (existingIndex == -1) {
      try {
        final conversation = await _chatService.getConversation(conversationId);
        if (!mounted) return;
        setState(() {
          _conversations.insert(0, conversation);
          _sortConversations();
        });
      } catch (e) {
        debugPrint(
          '[Conversations] Failed to fetch conversation $conversationId: $e',
        );
      }
      return;
    }

    setState(() {
      final existing = _conversations[existingIndex];
      final updated = existing.copyWith(
        lastMessage: chatMessage,
        lastMessageAt: chatMessage.createdAt,
        messageCount: existing.messageCount + 1,
        unreadCount: chatMessage.senderId != currentUserId
            ? existing.unreadCount + 1
            : existing.unreadCount,
      );
      _conversations.removeAt(existingIndex);
      _conversations.insert(0, updated);
      _sortConversations();
    });
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      if (a.streakCount != b.streakCount) {
        return b.streakCount.compareTo(a.streakCount);
      }
      final aTime = a.lastMessageAt ?? a.updatedAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.updatedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  Future<void> _onRefresh() async {
    await _loadConversations();
    _refreshController.refreshCompleted();
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _ConversationSearchSheet(conversations: _conversations),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.conversationsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const StoriesBar(),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _hasError
                    ? ErrorState(onRetry: _loadConversations)
                    : _conversations.isEmpty
                        ? EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: l10n.emptyConversationsTitle,
                            subtitle: l10n.emptyConversationsSubtitle,
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                return _ConversationTile(
                                  conversation: _conversations[index],
                                  onTap: () {
                                    context
                                        .push('/chat/${_conversations[index].id}');
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
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
          heroTag: 'conversations_fab',
          onPressed: () {
            context.push('/new-chat');
          },
          tooltip: l10n.newConversationFab,
          backgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.chat,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _ConversationSearchSheet extends StatefulWidget {
  final List<Conversation> conversations;

  const _ConversationSearchSheet({required this.conversations});

  @override
  State<_ConversationSearchSheet> createState() =>
      _ConversationSearchSheetState();
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
          final lastMessage =
              conversation.lastMessage?.content.toLowerCase() ?? '';

          return username.contains(_searchQuery) ||
              fullName.contains(_searchQuery) ||
              lastMessage.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                hintText: l10n.searchConversationsHint,
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
                          ? l10n.emptyConversationsTitle
                          : l10n.noResultsFound,
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: _filteredConversations[index],
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          '/chat/${_filteredConversations[index].id}',
                        );
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

  const _ConversationTile({required this.conversation, this.onTap});

  Widget? _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall;
    final isUnread = conversation.unreadCount > 0;
    final messageStyle = baseStyle?.copyWith(
      color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
    );

    final messageWidget = conversation.lastMessage != null
        ? Text(
            conversation.lastMessage!.content,
            style: messageStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : null;

    final streakIndicator = conversation.streakCount > 0
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _StreakStatusIndicator(conversation: conversation),
          )
        : null;

    if (messageWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [messageWidget, if (streakIndicator != null) streakIndicator],
      );
    }
    return streakIndicator;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final otherUser = conversation.getOtherParticipant(currentUserId);
    final streakCount = conversation.streakCount;
    final showHourglass = _shouldShowHourglass();

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          AvatarWidget(
            imageUrl: otherUser?.avatar,
            name: otherUser?.fullName,
            size: 52,
            showOnlineIndicator: otherUser?.isOnline == true,
            isOnline: otherUser?.isOnline == true,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        conversation.isIdentityRevealed
                            ? otherUser?.fullName ??
                                AppLocalizations.of(context)!.userFallback
                            : AppLocalizations.of(context)!
                                .anonymousConversation,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (streakCount > 0) ...[
                      _FlameBadge(
                        count: streakCount,
                        flameLevel: conversation.flameLevel.name,
                      ),
                    ],
                    if (showHourglass) ...[
                      const SizedBox(width: 4),
                      const _PulsingHourglassIcon(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: _buildSubtitle(context),
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

  bool _shouldShowHourglass() {
    if (conversation.streakCount <= 0) return false;
    final referenceTime =
        conversation.lastMessageAt ??
        conversation.updatedAt ??
        conversation.createdAt;
    final expiryTime = referenceTime.add(const Duration(hours: 24));
    final remaining = expiryTime.difference(DateTime.now());
    return remaining > Duration.zero && remaining <= const Duration(hours: 3);
  }

  String? _buildStatusText(BuildContext context, User? user) {
    if (user == null) return null;
    final isOnline = user.isOnline;
    if (isOnline) {
      return Localizations.localeOf(context).languageCode == 'fr'
          ? 'En ligne'
          : 'Online';
    }
    final lastSeen = user.lastSeenAt;
    if (lastSeen == null) return null;

    final now = DateTime.now();
    final isToday =
        now.year == lastSeen.year &&
        now.month == lastSeen.month &&
        now.day == lastSeen.day;
    final timeText = Helpers.formatTime(lastSeen);

    if (Localizations.localeOf(context).languageCode == 'fr') {
      if (isToday) {
        return "En ligne aujourd'hui a $timeText";
      }
      final dateText = Helpers.formatDate(lastSeen);
      return 'En ligne le $dateText a $timeText';
    }

    if (isToday) {
      return 'Online today at $timeText';
    }
    final dateText = Helpers.formatDate(lastSeen);
    return 'Online on $dateText at $timeText';
  }
}

class _StreakStatusIndicator extends StatelessWidget {
  const _StreakStatusIndicator({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final referenceTime =
        conversation.lastMessageAt ??
        conversation.updatedAt ??
        conversation.createdAt;
    const streakDuration = Duration(hours: 24);
    final expiryTime = referenceTime.add(streakDuration);
    final now = DateTime.now();
    final remaining = expiryTime.difference(now);
    final isExpired = remaining <= Duration.zero;
    int boundedRemainingSeconds;
    if (remaining.isNegative) {
      boundedRemainingSeconds = 0;
    } else if (remaining.inSeconds > streakDuration.inSeconds) {
      boundedRemainingSeconds = streakDuration.inSeconds;
    } else {
      boundedRemainingSeconds = remaining.inSeconds;
    }
    final progress = streakDuration.inSeconds > 0
        ? boundedRemainingSeconds / streakDuration.inSeconds
        : 0.0;
    final flameColor = Helpers.getFlameColor(conversation.flameLevel.name);
    final indicatorColor = flameColor == Colors.transparent
        ? AppColors.primary
        : flameColor;
    final backgroundColor = indicatorColor.withOpacity(0.25);
    if (isExpired) {
      return Row(
        children: [
          const Icon(
            Icons.hourglass_disabled,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.streakExpired,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    final hoursLeft = remaining.inHours;
    final minutesLeft = remaining.inMinutes % 60;
    final showHourglass = remaining <= const Duration(hours: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          color: indicatorColor,
          backgroundColor: backgroundColor,
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (showHourglass) ...[
              const Icon(
                Icons.hourglass_bottom,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              l10n.streakExpiresIn(hoursLeft, minutesLeft),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _FlameBadge extends StatefulWidget {
  const _FlameBadge({required this.count, required this.flameLevel});

  final int count;
  final String flameLevel;

  @override
  State<_FlameBadge> createState() => _FlameBadgeState();
}

class _FlameBadgeState extends State<_FlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _pulseUp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_controller);

    if (_isMilestone(widget.count)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant _FlameBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count && _isMilestone(widget.count)) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isMilestone(int count) {
    return count == 10 || count == 50 || count == 100;
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = widget.count < 0 ? 0 : widget.count;
    final flameColor = Helpers.getFlameColor(widget.flameLevel);
    final effectiveColor =
        flameColor == Colors.transparent ? AppColors.flameOrange : flameColor;

    return AnimatedScale(
      scale: widget.count > 0 ? (_pulseUp ? 1.06 : 1.0) : 1.0,
      duration: const Duration(milliseconds: 900),
      onEnd: widget.count > 0
          ? () {
              if (!mounted) return;
              setState(() {
                _pulseUp = !_pulseUp;
              });
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            Text(
              '$displayCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingHourglassIcon extends StatefulWidget {
  const _PulsingHourglassIcon();

  @override
  State<_PulsingHourglassIcon> createState() => _PulsingHourglassIconState();
}

class _PulsingHourglassIconState extends State<_PulsingHourglassIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(
        Icons.hourglass_bottom,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
