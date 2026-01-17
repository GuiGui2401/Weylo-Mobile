import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../widgets/common/widgets.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupService _groupService = GroupService();
  final RefreshController _myGroupsRefreshController = RefreshController();
  final RefreshController _discoverGroupsRefreshController = RefreshController();
  final TextEditingController _inviteCodeController = TextEditingController();

  List<Group> _myGroups = [];
  List<Group> _discoverGroups = [];
  bool _isLoading = true;
  bool _hasError = false;

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
        _discoverGroups = discoverGroups.where((group) => !existingIds.contains(group.id)).toList();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre un groupe'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            hintText: 'Entrez le code d\'invitation',
            prefixIcon: Icon(Icons.link),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _inviteCodeController.text.trim();
              if (code.isEmpty) return;

              try {
                await _groupService.joinGroup(code);
                if (mounted) {
                  Navigator.pop(context);
                  Helpers.showSuccessSnackBar(context, 'Vous avez rejoint le groupe !');
                  _loadData();
                }
              } catch (e) {
                Helpers.showErrorSnackBar(context, 'Code d\'invitation invalide');
              }

              _inviteCodeController.clear();
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showJoinDialog,
            tooltip: 'Rejoindre avec un code',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes groupes'),
            Tab(text: 'Découvrir'),
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
                    _buildGroupsList(
                      _myGroups,
                      isMyGroups: true,
                      controller: _myGroupsRefreshController,
                    ),
                    _buildGroupsList(
                      _discoverGroups,
                      isDiscover: true,
                      controller: _discoverGroupsRefreshController,
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'groups_fab',
        onPressed: () => context.push('/create-group'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupsList(
    List<Group> groups, {
    bool isMyGroups = false,
    bool isDiscover = false,
    required RefreshController controller,
  }) {
    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: isMyGroups ? 'Aucun groupe' : 'Aucun groupe à découvrir',
        subtitle: isMyGroups
            ? 'Créez ou rejoignez un groupe pour commencer'
            : 'Revenez plus tard pour découvrir de nouveaux groupes',
        buttonText: isMyGroups ? 'Créer un groupe' : null,
        onButtonPressed: isMyGroups ? () => context.push('/create-group') : null,
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

  void _showJoinGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejoindre ${group.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              Text(group.description!),
              const SizedBox(height: 12),
            ],
            Text('${group.membersCount}/${group.maxMembers} membres'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _groupService.joinGroup(group.inviteCode);
                if (mounted) {
                  Navigator.pop(context);
                  Helpers.showSuccessSnackBar(context, 'Vous avez rejoint le groupe !');
                  _loadData();
                }
              } catch (e) {
                Helpers.showErrorSnackBar(context, 'Impossible de rejoindre le groupe');
              }
            },
            child: const Text('Rejoindre'),
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

  const _GroupCard({
    required this.group,
    this.isDiscover = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Public',
                              style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}
