import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/helpers.dart';
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
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_status?.autoRenew == true) {
        await _premiumService.disableAutoRenew();
      } else {
        await _premiumService.enableAutoRenew();
      }
      await _loadStatus();
      if (mounted) {
        Helpers.showSuccessSnackBar(
          context,
          _status?.autoRenew == true
              ? l10n.autoRenewEnabled
              : l10n.autoRenewDisabled,
        );
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
        title: Text(l10n.premiumSettings),
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
                  title: Text(l10n.statusLabel),
                  subtitle: Text(
                    _status?.isActive == true
                        ? l10n.statusActive
                        : l10n.statusInactive,
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push('/premium'),
                    child: Text(l10n.viewAction),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.autoRenewTitle),
                  subtitle: Text(l10n.autoRenewSubtitle),
                  value: _status?.autoRenew ?? false,
                  onChanged: (_) => _toggleAutoRenew(),
                ),
              ],
            ),
    );
  }
}
