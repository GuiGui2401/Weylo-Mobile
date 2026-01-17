import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentLanguage = authProvider.currentUser?.settings?.language ?? 'fr';
    final languageLabel = currentLanguage == 'fr' ? 'Français' : 'English';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramtres'),
      ),
      body: ListView(
        children: [
          // Account section
          _buildSectionHeader('Compte'),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Modifier le profil',
            onTap: () => context.push('/edit-profile'),
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Confidentialité',
            onTap: () => context.push('/privacy'),
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),

          const Divider(),

          // Appearance section
          _buildSectionHeader('Apparence'),
          _buildSettingItem(
            icon: Icons.dark_mode_outlined,
            title: 'Mode sombre',
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
            title: 'Langue',
            subtitle: languageLabel,
            onTap: () => _showLanguageDialog(context),
          ),

          const Divider(),

          // Premium section
          _buildSectionHeader('Premium'),
          _buildSettingItem(
            icon: Icons.star_outline,
            title: 'Weylo Premium',
            subtitle: 'Dbloquez des fonctionnalits exclusives',
            onTap: () => context.push('/premium'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'UPGRADE',
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
            title: 'Mes abonnements',
            subtitle: 'Pass Premium et abonnements cibls',
            onTap: () => context.push('/subscriptions'),
          ),
          _buildSettingItem(
            icon: Icons.tune_outlined,
            title: 'Rglages Premium',
            onTap: () => context.push('/premium-settings'),
          ),
          _buildSettingItem(
            icon: Icons.bar_chart_outlined,
            title: 'Revenus',
            subtitle: 'Creator Fund et revenus pub',
            onTap: () => context.push('/earnings'),
          ),

          const Divider(),

          // Support section
          _buildSectionHeader('Support'),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Aide',
            onTap: () => context.push('/help'),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: ' propos',
            onTap: () => context.push('/about'),
          ),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => context.push('/terms'),
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => context.push('/privacy-policy'),
          ),

          const Divider(),

          // Logout
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Dconnexion',
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'Weylo v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
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
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = context.read<AuthProvider>().currentUser?.settings?.language ?? 'fr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: const Text('Français'),
              trailing: currentLanguage == 'fr'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateLanguage(context, 'fr');
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: currentLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateLanguage(context, 'en');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _updateLanguage(BuildContext context, String language) async {
    try {
      await context.read<AuthProvider>().updateSettings({'language': language});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language == 'fr'
                ? 'Langue changée en Français'
                : 'Language changed to English'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dconnexion'),
        content: const Text('tes-vous sr de vouloir vous dconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: const Text(
              'Dconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
