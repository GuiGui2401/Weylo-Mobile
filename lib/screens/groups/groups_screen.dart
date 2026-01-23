import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/widgets/common/widgets.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();
  final RefreshController _myGroupsRefreshController = RefreshController();
  final RefreshController _discoverGroupsRefreshController =
      RefreshController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Group> _myGroups = [];
  List<Group> _discoverGroups = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _myGroupsRefreshController.dispose();
    _discoverGroupsRefreshController.dispose();
    _inviteCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _groupService.getMyGroups(),
        _groupService.discoverGroups(),
      ]);

      final myGroups = results[0] as List<Group>;
      final discoverGroups = results[1] as List<Group>;
      final existingIds = myGroups.map((group) => group.id).toSet();

      setState(() {
        _myGroups = myGroups;
        _discoverGroups = discoverGroups
            .where((group) => !existingIds.contains(group.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh(RefreshController controller) async {
    await _loadData();
    controller.refreshCompleted();
  }

  void _showJoinDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinGroupTitle),
        content: TextField(
          controller: _inviteCodeController,
          decoration: InputDecoration(
            hintText: l10n.inviteCodeHint,
            prefixIcon: const Icon(Icons.link),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _inviteCodeController.text.trim();
              if (code.isEmpty) return;

              try {
                await _groupService.joinGroup(code);
                if (mounted) {
                  Navigator.pop(context);
                  Helpers.showSuccessSnackBar(context, l10n.joinGroupSuccess);
                  _loadData();
                }
              } catch (e) {
                Helpers.showErrorSnackBar(context, l10n.invalidInviteCode);
              }

              _inviteCodeController.clear();
            },
            child: Text(l10n.joinAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.groupsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showJoinDialog,
            tooltip: l10n.joinWithCodeTooltip,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.myGroupsTab),
            Tab(text: l10n.discoverTab),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _hasError
          ? ErrorState(onRetry: _loadData)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un groupe',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupsList(
                        _filteredGroups(_myGroups),
                        isMyGroups: true,
                        controller: _myGroupsRefreshController,
                      ),
                      _buildGroupsList(
                        _filteredGroups(_discoverGroups),
                        isDiscover: true,
                        controller: _discoverGroupsRefreshController,
                      ),
                    ],
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
          heroTag: 'groups_fab',
          onPressed: () => context.push('/create-group'),
          backgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(
    List<Group> groups, {
    bool isMyGroups = false,
    bool isDiscover = false,
    required RefreshController controller,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: isMyGroups ? l10n.noGroupsTitle : l10n.noGroupsDiscoverTitle,
        subtitle: isMyGroups
            ? l10n.noGroupsSubtitle
            : l10n.noGroupsDiscoverSubtitle,
        buttonText: isMyGroups ? l10n.createGroupAction : null,
        onButtonPressed: isMyGroups
            ? () => context.push('/create-group')
            : null,
      );
    }

    return SmartRefresher(
      controller: controller,
      onRefresh: () => _onRefresh(controller),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _GroupCard(
            group: group,
            isDiscover: isDiscover,
            onTap: () {
              if (isDiscover) {
                _showJoinGroupDialog(group);
              } else {
                context.push('/group/${group.id}');
              }
            },
          );
        },
      ),
    );
  }

  List<Group> _filteredGroups(List<Group> groups) {
    if (_searchQuery.isEmpty) return groups;
    final query = _searchQuery.toLowerCase();
    return groups.where((group) {
      final name = group.name.toLowerCase();
      final description = (group.description ?? '').toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  void _showJoinGroupDialog(Group group) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinGroupNameTitle(group.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              Text(group.description!),
              const SizedBox(height: 12),
            ],
            Text(l10n.groupMembersCount(group.membersCount, group.maxMembers)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _groupService.joinGroup(group.inviteCode);
                if (mounted) {
                  Navigator.pop(context);
                  Helpers.showSuccessSnackBar(context, l10n.joinGroupSuccess);
                  _loadData();
                }
              } catch (e) {
                Helpers.showErrorSnackBar(context, l10n.joinGroupError);
              }
            },
            child: Text(l10n.joinAction),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool isDiscover;
  final VoidCallback? onTap;

  const _GroupCard({required this.group, this.isDiscover = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusText = _buildGroupStatusText(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: group.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          group.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          group.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.visibilityPublic,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (group.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (statusText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.membersCount}/${group.maxMembers}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!isDiscover && group.lastMessage != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              group.lastMessage!.content,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isDiscover && group.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isDiscover)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildGroupStatusText(BuildContext context) {
    final members = group.members ?? [];
    final onlineCount =
        members.where((m) => m.user?.isOnline == true).length;
    final locale = Localizations.localeOf(context).languageCode;
    final membersLabel = locale == 'fr'
        ? '${group.membersCount} membres'
        : '${group.membersCount} members';

    if (onlineCount > 0) {
      final onlineLabel =
          locale == 'fr' ? '$onlineCount en ligne' : '$onlineCount online';
      return '$onlineLabel • $membersLabel';
    }

    final lastActivity =
        group.lastMessage?.createdAt ?? group.updatedAt ?? group.createdAt;
    final now = DateTime.now();
    final isToday =
        now.year == lastActivity.year &&
        now.month == lastActivity.month &&
        now.day == lastActivity.day;
    final timeText = Helpers.formatTime(lastActivity);

    if (locale == 'fr') {
      final base = isToday
          ? "Derniere activite aujourd'hui a $timeText"
          : 'Derniere activite le ${Helpers.formatDate(lastActivity)} a $timeText';
      return '$base • $membersLabel';
    }
    final base = isToday
        ? 'Last active today at $timeText'
        : 'Last active on ${Helpers.formatDate(lastActivity)} at $timeText';
    return '$base • $membersLabel';
  }
}
