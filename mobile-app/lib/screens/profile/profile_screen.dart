import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditDialog(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    final nomCtrl = TextEditingController(text: user.nom);
    final nniCtrl = TextEditingController(text: user.nni ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('edit_profile')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nomCtrl,
            decoration: InputDecoration(
                labelText: context.tr('full_name'),
                prefixIcon: const Icon(Icons.person_outline, color: WaqtiTheme.primary)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nniCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: context.tr('nni'),
                prefixIcon: const Icon(Icons.badge_outlined, color: WaqtiTheme.primary)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().updateProfile({
                  'nom': nomCtrl.text.trim(),
                  'nni': nniCtrl.text.trim(),
                });
                await auth.refreshProfile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.tr('profile_updated')),
                      backgroundColor: WaqtiTheme.success));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${context.tr("error")}: $e'),
                      backgroundColor: WaqtiTheme.danger));
                }
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final user = auth.user;
    if (user == null) return const Center(child: Text('Non connecté'));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: localeProvider.toggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(localeProvider.isArabic ? 'FR' : 'AR',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(gradient: WaqtiTheme.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 16),
          Text(user.nom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: WaqtiTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Text(user.role, style: const TextStyle(color: WaqtiTheme.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WaqtiTheme.border)),
            child: Column(children: [
              _InfoTile(icon: Icons.phone_outlined, label: context.tr('phone'), value: user.telephone),
              const Divider(height: 1),
              _InfoTile(icon: Icons.badge_outlined, label: context.tr('nni'), value: user.nni ?? context.tr('nni_placeholder')),
              const Divider(height: 1),
              _InfoTile(icon: Icons.circle_outlined, label: context.tr('status'), value: user.statut),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.tr('edit_profile')),
              onPressed: () => _showEditDialog(context, auth),
            )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(context.tr('logout')),
              style: ElevatedButton.styleFrom(backgroundColor: WaqtiTheme.danger),
              onPressed: () async { await auth.logout(); },
            )),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: WaqtiTheme.primary, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ]),
      ]),
    );
  }
}
