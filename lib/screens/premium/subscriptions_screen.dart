import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/premium.dart';
import '../../services/premium_service.dart';
import '../../services/widgets/common/widgets.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  final PremiumService _premiumService = PremiumService();
  late TabController _tabController;

  PremiumPassStatusResponse? _passStatus;
  List<PremiumSubscription> _subscriptions = [];
  List<PremiumPass> _passHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _premiumService.getPassStatus(),
        _premiumService.getActiveSubscriptions(),
        _premiumService.getPassHistory(),
      ]);

      setState(() {
        _passStatus = results[0] as PremiumPassStatusResponse;
        _subscriptions = results[1] as List<PremiumSubscription>;
        _passHistory = results[2] as List<PremiumPass>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription(PremiumSubscription subscription) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _premiumService.cancelSubscription(subscription.id);
      await _loadData();
      if (mounted) {
        Helpers.showSuccessSnackBar(context, l10n.subscriptionCancelled);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, l10n.errorMessage(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.premiumPassTab),
            Tab(text: l10n.targetedSubscriptionsTab),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [_buildPremiumPassTab(), _buildSubscriptionsTab()],
            ),
    );
  }

  Widget _buildPremiumPassTab() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumBrandName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _passStatus?.isActive == true
                      ? l10n.statusActive
                      : l10n.statusInactive,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (_passStatus?.daysRemaining != null &&
                    _passStatus!.daysRemaining > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.premiumDaysRemaining(_passStatus!.daysRemaining),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.historyTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_passHistory.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.noPassTitle,
              subtitle: l10n.noPassSubtitle,
            )
          else
            Column(
              children: _passHistory.map((pass) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(Helpers.formatCurrency(pass.amount.toInt())),
                  subtitle: Text(
                    l10n.expiresOnDate(
                      '${pass.expiresAt.day}/${pass.expiresAt.month}/${pass.expiresAt.year}',
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: Text(
                    pass.status.name,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_subscriptions.isEmpty) {
      return EmptyState(
        icon: Icons.subscriptions_outlined,
        title: l10n.noSubscriptionsTitle,
        subtitle: l10n.noSubscriptionsSubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.lock_open, color: AppColors.primary),
              title: Text(subscription.typeLabel),
              subtitle: Text(
                subscription.expiresAt != null
                    ? l10n.expiresOnDate(
                        '${subscription.expiresAt!.day}/${subscription.expiresAt!.month}/${subscription.expiresAt!.year}',
                      )
                    : l10n.noExpiryLabel,
              ),
              trailing: TextButton(
                onPressed: () => _cancelSubscription(subscription),
                child: Text(l10n.cancel),
              ),
            ),
          );
        },
      ),
    );
  }
}
