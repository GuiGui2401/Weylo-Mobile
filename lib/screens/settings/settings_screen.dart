import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentLanguage =
        authProvider.currentUser?.settings?.language ?? 'fr';
    final languageLabel = currentLanguage == 'fr'
        ? l10n.languageFrench
        : l10n.languageEnglish;
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // Account section
          _buildSectionHeader(l10n.accountSection),
          if (user != null)
            _buildSettingItem(
              icon: Icons.badge_outlined,
              title: l10n.accountInfo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountInfoScreen(user: user),
                  ),
                );
              },
            ),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: l10n.editProfile,
            onTap: () => context.push('/edit-profile'),
          ),
          _buildSettingItem(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.wallet,
            onTap: () => context.push('/wallet'),
          ),
          _buildSettingItem(
            icon: Icons.manage_accounts_outlined,
            title: l10n.accountManagementHeader,
            onTap: () => context.push('/privacy'),
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            onTap: () => context.push('/notifications'),
          ),

          const Divider(),

          // Appearance section
          _buildSectionHeader(l10n.appearanceSection),
          _buildSettingItem(
            icon: Icons.dark_mode_outlined,
            title: l10n.darkMode,
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: AppColors.secondary,
              activeTrackColor: AppColors.primary.withOpacity(0.5),
            ),
          ),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: l10n.language,
            subtitle: languageLabel,
            onTap: () => _showLanguageDialog(context),
          ),

          const Divider(),

          // Premium section
          _buildSectionHeader(l10n.premiumSection),
          _buildSettingItem(
            icon: Icons.star_outline,
            title: l10n.weyloPremium,
            subtitle: l10n.premiumSubtitle,
            onTap: () => context.push('/premium'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.upgrade,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildSettingItem(
            icon: Icons.subscriptions_outlined,
            title: l10n.mySubscriptions,
            subtitle: l10n.subscriptionsSubtitle,
            onTap: () => context.push('/subscriptions'),
          ),
          _buildSettingItem(
            icon: Icons.tune_outlined,
            title: l10n.premiumSettings,
            onTap: () => context.push('/premium-settings'),
          ),
          _buildSettingItem(
            icon: Icons.bar_chart_outlined,
            title: l10n.earnings,
            subtitle: l10n.earningsSubtitle,
            onTap: () => context.push('/earnings'),
          ),

          const Divider(),

          // Support section
          _buildSectionHeader(l10n.supportSection),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: l10n.help,
            onTap: () => context.push('/help'),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: l10n.about,
            onTap: () => context.push('/about'),
          ),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: l10n.termsOfUse,
            onTap: () => context.push('/terms'),
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () => context.push('/privacy-policy'),
          ),

          const Divider(),

          // Logout
          _buildSettingItem(
            icon: Icons.logout,
            title: l10n.logout,
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              l10n.appVersion('1.0.0'),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, user) {
    return UserInfoCard(
      user: user,
      onEdit: () => context.push('/edit-profile'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final currentLanguage =
        context.read<AuthProvider>().currentUser?.settings?.language ?? 'fr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageFrench),
              trailing: currentLanguage == 'fr'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateLanguage(context, 'fr');
                localeProvider.setLocale(const Locale('fr'));
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageEnglish),
              trailing: currentLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateLanguage(context, 'en');
                localeProvider.setLocale(const Locale('en'));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _updateLanguage(BuildContext context, String language) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<AuthProvider>().updateSettings({'language': language});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              language == 'fr'
                  ? l10n.languageChangedToFrench
                  : l10n.languageChangedToEnglish,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: Text(
              l10n.logoutButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountInfoScreen extends StatelessWidget {
  final dynamic user;

  const AccountInfoScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountInfoTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          UserInfoCard(user: user, onEdit: () => context.push('/edit-profile')),
        ],
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onEdit;

  const UserInfoCard({super.key, required this.user, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              l10n.firstName,
              user.firstName,
              isEditable: true,
            ),
            if (user.lastName != null && user.lastName!.isNotEmpty)
              _buildInfoRow(
                context,
                l10n.lastName,
                user.lastName,
                isEditable: true,
              ),
            _buildInfoRow(context, l10n.username, '@${user.username}'),
            if (user.email != null && user.email!.isNotEmpty)
              _buildInfoRow(context, l10n.email, user.email),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildInfoRow(context, l10n.phone, user.phone),
            _buildInfoRow(
              context,
              l10n.bio,
              (user.bio != null && user.bio!.isNotEmpty)
                  ? user.bio
                  : l10n.notProvided,
              isEditable: true,
            ),
            if (user.createdAt != null)
              _buildInfoRow(
                context,
                l10n.signupDate,
                Helpers.formatDate(user.createdAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isEditable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: isEditable ? onEdit : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isEditable) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
