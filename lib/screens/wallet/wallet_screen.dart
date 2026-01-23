import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/wallet.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/widgets/common/widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WalletService _walletService = WalletService();

  List<WalletTransaction> _transactions = [];
  List<Withdrawal> _withdrawals = [];
  WalletStats? _stats;
  bool _isLoading = true;

  Future<void> _onRefresh() async {
    await _loadData();
  }

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
        _walletService.getTransactions(),
        _walletService.getWithdrawals(),
        _walletService.getStats(),
        _walletService.getWallet(),
      ]);

      setState(() {
        _transactions = results[0] as List<WalletTransaction>;
        _withdrawals = results[1] as List<Withdrawal>;
        _stats = results[2] as WalletStats;
        _isLoading = false;
      });

      final walletResponse = results[3] as Map<String, dynamic>;
      final walletBalance = _parseWalletBalance(walletResponse);
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user != null && walletBalance != user.walletBalance) {
        authProvider.updateUser(user.copyWith(walletBalance: walletBalance));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _parseWalletBalance(Map<String, dynamic> data) {
    final wallet = data['wallet'];
    final value = wallet is Map
        ? wallet['balance']
        : data['balance'] ?? data['wallet_balance'];
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.availableBalanceLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Helpers.formatCurrency(
                                    user?.walletBalance ?? 0,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.add,
                                        label: l10n.depositAction,
                                        onTap: () =>
                                            _showDepositDialog(context),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.arrow_upward,
                                        label: l10n.withdrawAction,
                                        onTap: () =>
                                            _showWithdrawDialog(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_stats != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  _StatItem(
                                    label: l10n.totalDepositsLabel,
                                    value: Helpers.formatCurrency(
                                      _stats!.totalDeposits,
                                    ),
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatItem(
                                    label: l10n.totalWithdrawalsLabel,
                                    value: Helpers.formatCurrency(
                                      _stats!.totalWithdrawals,
                                    ),
                                    color: AppColors.warning,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _WalletTabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: l10n.transactionsTab),
                            Tab(text: l10n.withdrawalsTab),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [_buildTransactionsList(), _buildWithdrawalsList()],
                ),
              ),
            ),
    );
  }

  Widget _buildTransactionsList() {
    final l10n = AppLocalizations.of(context)!;
    return _transactions.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.noTransactionsTitle,
                subtitle: l10n.noTransactionsSubtitle,
              ),
            ],
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return _TransactionTile(transaction: transaction);
            },
          );
  }

  Widget _buildWithdrawalsList() {
    final l10n = AppLocalizations.of(context)!;
    return _withdrawals.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              EmptyState(
                icon: Icons.account_balance_outlined,
                title: l10n.noWithdrawalsTitle,
                subtitle: l10n.noWithdrawalsSubtitle,
              ),
            ],
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = _withdrawals[index];
              return _WithdrawalTile(withdrawal: withdrawal);
            },
          );
  }

  void _showDepositDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.depositTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.depositViaLigos,
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                hintText: l10n.amountExample,
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.minimumAmountLabel('500 FCFA'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount < 500) {
                  Helpers.showErrorSnackBar(
                    context,
                    l10n.minimumAmountLabel('500 FCFA'),
                  );
                  return;
                }

                try {
                  final response = await _walletService.initiateDeposit(
                    amount: amount,
                    provider: 'ligos',
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    // Open payment URL
                    context.push(
                      '/payment?url=${Uri.encodeComponent(response.paymentUrl)}',
                    );
                  }
                } catch (e) {
                  Helpers.showErrorSnackBar(context, l10n.depositInitError);
                }
              },
              child: Text(l10n.continueToLigos),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedProvider = 'mtn';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.withdrawRequestTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.withdrawViaCinetpay,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  hintText: l10n.amountExample,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProvider,
                decoration: InputDecoration(
                  labelText: l10n.withdrawMethodLabel,
                  prefixIcon: const Icon(Icons.account_balance),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'mtn',
                    child: Text(l10n.mtnMobileMoneyLabel),
                  ),
                  DropdownMenuItem(
                    value: 'orange',
                    child: Text(l10n.orangeMoneyLabel),
                  ),
                ],
                onChanged: (value) {
                  setModalState(() {
                    selectedProvider = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  hintText: l10n.phoneNumberHint,
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.minimumAmountLabel('1 000 FCFA'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount < 1000) {
                    Helpers.showErrorSnackBar(
                      context,
                      l10n.minimumAmountLabel('1 000 FCFA'),
                    );
                    return;
                  }

                  if (phoneController.text.isEmpty) {
                    Helpers.showErrorSnackBar(
                      context,
                      l10n.phoneNumberRequiredError,
                    );
                    return;
                  }

                  try {
                    await _walletService.requestWithdrawal(
                      amount: amount,
                      provider: 'cinetpay_$selectedProvider',
                      phoneNumber: phoneController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      Helpers.showSuccessSnackBar(
                        context,
                        l10n.withdrawRequestSent,
                      );
                      _loadData();
                    }
                  } catch (e) {
                    Helpers.showErrorSnackBar(
                      context,
                      l10n.withdrawRequestError,
                    );
                  }
                },
                child: Text(l10n.withdrawAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isCredit ? AppColors.success : AppColors.error).withOpacity(
              0.1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(transaction.typeLabel),
        subtitle: Text(
          Helpers.formatDateTime(transaction.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'} ${Helpers.formatCurrency(transaction.amount)}',
          style: TextStyle(
            color: isCredit ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  final Withdrawal withdrawal;

  const _WithdrawalTile({required this.withdrawal});

  Color get _statusColor {
    switch (withdrawal.status) {
      case WithdrawalStatus.completed:
        return AppColors.success;
      case WithdrawalStatus.rejected:
        return AppColors.error;
      case WithdrawalStatus.processing:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.account_balance, color: _statusColor),
        ),
        title: Text(Helpers.formatCurrency(withdrawal.amount)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(withdrawal.providerLabel),
            Text(
              Helpers.formatDateTime(withdrawal.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            withdrawal.statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _WalletTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _WalletTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _WalletTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
