import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../core/theme/app_colors.dart';
import '../../models/confession.dart';
import '../../services/confession_service.dart';
import '../../widgets/common/widgets.dart';
import '../../widgets/confessions/confession_card.dart';

class ConfessionsScreen extends StatefulWidget {
  const ConfessionsScreen({super.key});

  @override
  State<ConfessionsScreen> createState() => _ConfessionsScreenState();
}

class _ConfessionsScreenState extends State<ConfessionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConfessionService _confessionService = ConfessionService();
  final RefreshController _refreshController = RefreshController();

  List<Confession> _publicConfessions = [];
  List<Confession> _receivedConfessions = [];
  List<Confession> _sentConfessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _confessionService.getPublicConfessions(),
        _confessionService.getReceivedConfessions(),
        _confessionService.getSentConfessions(),
      ]);

      setState(() {
        _publicConfessions = (results[0] as PaginatedConfessions).confessions;
        _hasMore = (results[0] as PaginatedConfessions).hasMore;
        _receivedConfessions = (results[1] as PaginatedConfessions).confessions;
        _sentConfessions = (results[2] as PaginatedConfessions).confessions;
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
    _currentPage = 1;
    await _loadData();
    _refreshController.refreshCompleted();
  }

  Future<void> _loadMore() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final result = await _confessionService.getPublicConfessions(page: _currentPage + 1);
      setState(() {
        _publicConfessions.addAll(result.confessions);
        _currentPage++;
        _hasMore = result.hasMore;
      });
      _refreshController.loadComplete();
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  void _handleLike(Confession confession) async {
    try {
      Confession updatedConfession;
      if (confession.isLiked) {
        updatedConfession = await _confessionService.unlikeConfession(confession.id);
      } else {
        updatedConfession = await _confessionService.likeConfession(confession.id);
      }

      setState(() {
        final index = _publicConfessions.indexWhere((c) => c.id == confession.id);
        if (index != -1) {
          _publicConfessions[index] = updatedConfession;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confessions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Reçues'),
            Tab(text: 'Envoyées'),
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
                    _buildConfessionsList(_publicConfessions, enableLoadMore: true),
                    _buildConfessionsList(_receivedConfessions, isReceived: true),
                    _buildConfessionsList(_sentConfessions, isSent: true),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'confessions_fab',
        onPressed: () => context.push('/create-confession'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConfessionsList(
    List<Confession> confessions, {
    bool isReceived = false,
    bool isSent = false,
    bool enableLoadMore = false,
  }) {
    if (confessions.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_outline,
        title: isReceived
            ? 'Aucune confession reçue'
            : isSent
                ? 'Aucune confession envoyée'
                : 'Aucune confession',
        subtitle: isReceived
            ? 'Les confessions qui vous sont adressées apparaîtront ici'
            : isSent
                ? 'Vos confessions apparaîtront ici'
                : 'Soyez le premier à poster une confession',
        buttonText: 'Créer une confession',
        onButtonPressed: () => context.push('/create-confession'),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: enableLoadMore ? _loadMore : null,
      enablePullUp: enableLoadMore,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: confessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final confession = confessions[index];
          return ConfessionCard(
            confession: confession,
            onTap: () => context.push('/confession/${confession.id}'),
            onLike: () => _handleLike(confession),
            onComment: () => context.push('/confession/${confession.id}'),
          );
        },
      ),
    );
  }
}
