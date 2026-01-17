import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/premium_service.dart';
import '../../services/widgets/common/widgets.dart';

class PremiumSettingsScreen extends StatefulWidget {
  const PremiumSettingsScreen({super.key});

  @override
  State<PremiumSettingsScreen> createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends State<PremiumSettingsScreen> {
  final PremiumService _premiumService = PremiumService();
  PremiumPassStatusResponse? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _premiumService.getPassStatus();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoRenew() async {
    try {
      if (_status?.autoRenew == true) {
        await _premiumService.disableAutoRenew();
      } else {
        await _premiumService.enableAutoRenew();
      }
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _status?.autoRenew == true
                  ? 'Renouvellement automatique activé'
                  : 'Renouvellement automatique désactivé',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('Statut'),
                  subtitle: Text(_status?.isActive == true ? 'Actif' : 'Inactif'),
                  trailing: TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text('Voir'),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Renouvellement automatique'),
                  subtitle: const Text('Renouveler automatiquement votre abonnement'),
                  value: _status?.autoRenew ?? false,
                  onChanged: (_) => _toggleAutoRenew(),
                ),
              ],
            ),
    );
  }
}
