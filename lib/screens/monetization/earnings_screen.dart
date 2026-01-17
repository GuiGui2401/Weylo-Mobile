import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/monetization.dart';
import '../../services/monetization_service.dart';
import '../../services/widgets/common/widgets.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final MonetizationService _monetizationService = MonetizationService();
  MonetizationOverview? _overview;
  List<MonetizationPayout> _payouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _monetizationService.getOverview(),
        _monetizationService.getPayouts(),
      ]);

      setState(() {
        _overview = results[0] as MonetizationOverview;
        _payouts = results[1] as List<MonetizationPayout>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenus'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTotalsCard(),
                  const SizedBox(height: 16),
                  if (_overview != null) ...[
                    _buildPeriodCard('Creator Fund', _overview!.creatorFund, AppColors.primary),
                    const SizedBox(height: 12),
                    _buildPeriodCard('Revenus publicitaires', _overview!.adRevenue, AppColors.success),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Historique des paiements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildPayoutsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalsCard() {
    final totalCreator = _overview?.totalCreatorFund ?? 0;
    final totalAds = _overview?.totalAdRevenue ?? 0;
    final total = totalCreator + totalAds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenus cumulés',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTotalChip('Creator Fund', totalCreator, Colors.white),
              const SizedBox(width: 8),
              _buildTotalChip('Ads', totalAds, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalChip(String label, int amount, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label • ${Helpers.formatCurrency(amount)}',
        style: TextStyle(color: textColor, fontSize: 12),
      ),
    );
  }

  Widget _buildPeriodCard(String title, MonetizationPeriodStats stats, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(Icons.insights, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Text(
                Helpers.formatCurrency(stats.estimatedAmount),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetric('Vues', stats.views.toString()),
              const SizedBox(width: 12),
              _buildMetric('Likes', stats.likes.toString()),
              const SizedBox(width: 12),
              _buildMetric('Score', stats.score.toString()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pool: ${Helpers.formatCurrency(stats.pool)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsList() {
    if (_payouts.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_outlined,
        title: 'Aucun paiement',
        subtitle: 'Les paiements apparaîtront ici',
      );
    }

    return Column(
      children: _payouts.map((payout) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.monetization_on, color: AppColors.primary),
          ),
          title: Text(payout.typeLabel),
          subtitle: Text(
            '${Helpers.formatCurrency(payout.amount)} • ${payout.status}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Text(
            '${payout.periodStart.day}/${payout.periodStart.month}/${payout.periodStart.year}',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        );
      }).toList(),
    );
  }
}
