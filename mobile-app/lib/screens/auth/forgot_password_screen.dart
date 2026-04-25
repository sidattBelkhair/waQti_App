import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _State();
}

class _State extends State<ForgotPasswordScreen> {
  final _telCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _telCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final tel = _telCtrl.text.trim();
    if (tel.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entrez un numéro valide')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService().forgotPassword(tel);
      final devToken = res.data['devToken'] as String?;

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
                telephone: tel, devToken: devToken)));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('404')
            ? 'Numéro introuvable'
            : 'Erreur. Réessayez.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: WaqtiTheme.danger));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.lock_reset,
                  size: 36, color: WaqtiTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Réinitialiser le mot de passe',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Entrez votre numéro de téléphone. Vous recevrez un code par SMS.',
              style: TextStyle(color: WaqtiTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Envoyer le code',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
