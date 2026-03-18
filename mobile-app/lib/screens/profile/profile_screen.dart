import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Center(child: Text('Non connecte'));

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          CircleAvatar(radius: 50, backgroundColor: WaqtiTheme.primary,
            child: Text(user.nom.isNotEmpty ? user.nom[0] : '?', style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Text(user.nom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user.role, style: const TextStyle(color: WaqtiTheme.textSecondary)),
          const SizedBox(height: 32),
          _InfoTile(icon: Icons.email, label: 'Email', value: user.email),
          _InfoTile(icon: Icons.phone, label: 'Telephone', value: user.telephone),
          _InfoTile(icon: Icons.badge, label: 'NNI', value: user.nni ?? 'Non renseigne'),
          _InfoTile(icon: Icons.circle, label: 'Statut', value: user.statut),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(icon: const Icon(Icons.edit), label: const Text('Modifier le profil'), onPressed: () {})),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Se deconnecter'),
              style: ElevatedButton.styleFrom(backgroundColor: WaqtiTheme.danger),
              onPressed: () async {
                await auth.logout();
              },
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
