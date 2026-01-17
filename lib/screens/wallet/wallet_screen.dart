import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WalletService _walletService = WalletService();

  List<WalletTransaction> _transactions = [];
  List<Withdrawal> _withdrawals = [];
  WalletStats? _stats;
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
        _walletService.getTransactions(),
        _walletService.getWithdrawals(),
        _walletService.getStats(),
      ]);

      setState(() {
        _transactions = results[0] as List<WalletTransaction>;
        _withdrawals = results[1] as List<Withdrawal>;
        _stats = results[2] as WalletStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon portefeuille'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Balance Card
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
                      const Text(
                        'Solde disponible',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Helpers.formatCurrency(user?.walletBalance ?? 0),
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
                              label: 'Déposer',
                              onTap: () => _showDepositDialog(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.arrow_upward,
                              label: 'Retirer',
                              onTap: () => _showWithdrawDialog(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stats
                if (_stats != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatItem(
                          label: 'Total dépôts',
                          value: Helpers.formatCurrency(_stats!.totalDeposits),
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        _StatItem(
                          label: 'Total retraits',
                          value: Helpers.formatCurrency(_stats!.totalWithdrawals),
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Transactions'),
                    Tab(text: 'Retraits'),
                  ],
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsList(),
                      _buildWithdrawalsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Aucune transaction',
        subtitle: 'Vos transactions apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _TransactionTile(transaction: transaction);
      },
    );
  }

  Widget _buildWithdrawalsList() {
    if (_withdrawals.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_outlined,
        title: 'Aucun retrait',
        subtitle: 'Vos demandes de retrait apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = _withdrawals[index];
        return _WithdrawalTile(withdrawal: withdrawal);
      },
    );
  }

  void _showDepositDialog(BuildContext context) {
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
              'Deposer de l\'argent',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    'Paiement via Ligos',
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
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: 'Ex: 5000',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Montant minimum: 500 FCFA',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount < 500) {
                  Helpers.showErrorSnackBar(context, 'Montant minimum: 500 FCFA');
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
                    context.push('/payment?url=${Uri.encodeComponent(response.paymentUrl)}');
                  }
                } catch (e) {
                  Helpers.showErrorSnackBar(context, 'Erreur lors de l\'initialisation');
                }
              },
              child: const Text('Continuer vers Ligos'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
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
                'Demander un retrait',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Retrait via Cinetpay',
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
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  hintText: 'Ex: 5000',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Methode de retrait',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: const [
                  DropdownMenuItem(value: 'mtn', child: Text('MTN Mobile Money')),
                  DropdownMenuItem(value: 'orange', child: Text('Orange Money')),
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
                decoration: const InputDecoration(
                  labelText: 'Numero de telephone',
                  hintText: '6XXXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Montant minimum: 1 000 FCFA',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount < 1000) {
                    Helpers.showErrorSnackBar(context, 'Montant minimum: 1 000 FCFA');
                    return;
                  }

                  if (phoneController.text.isEmpty) {
                    Helpers.showErrorSnackBar(context, 'Veuillez entrer un numero de telephone');
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
                      Helpers.showSuccessSnackBar(context, 'Demande de retrait envoyee');
                      _loadData();
                    }
                  } catch (e) {
                    Helpers.showErrorSnackBar(context, 'Erreur lors de la demande');
                  }
                },
                child: const Text('Demander le retrait'),
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

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

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
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
            color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
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
          child: Icon(
            Icons.account_balance,
            color: _statusColor,
          ),
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
