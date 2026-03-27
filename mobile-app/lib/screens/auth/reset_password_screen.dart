import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String telephone;
  final String? devToken;
  const ResetPasswordScreen(
      {super.key, required this.telephone, this.devToken});
  @override State<ResetPasswordScreen> createState() => _State();
}

class _State extends State<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void initState() {
    super.initState();
    if (widget.devToken != null) _codeCtrl.text = widget.devToken!;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty) {
      _snack('Entrez le code reçu par SMS');
      return;
    }
    if (_mdpCtrl.text.length < 6) {
      _snack('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    if (_mdpCtrl.text != _confirmCtrl.text) {
      _snack('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService().resetPassword(
          _codeCtrl.text.trim(), _mdpCtrl.text);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: WaqtiTheme.success, size: 42),
              ),
              const SizedBox(height: 16),
              const Text('Mot de passe modifié !',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Vous pouvez maintenant vous connecter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WaqtiTheme.textSecondary)),
            ]),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Se connecter'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains('400')
          ? 'Code invalide ou expiré'
          : 'Erreur. Réessayez.';
      _snack(msg);
    }
    setState(() => _loading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: WaqtiTheme.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Entrez le code reçu par SMS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Envoyé au ${widget.telephone}',
                style: const TextStyle(
                    color: WaqtiTheme.textSecondary, fontSize: 13)),

            // Bandeau dev
            if (widget.devToken != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCA28))),
                child: Row(children: [
                  const Icon(Icons.bug_report_outlined,
                      color: Color(0xFFF57F17), size: 16),
                  const SizedBox(width: 8),
                  Text('Mode test — Code : ${widget.devToken}',
                      style: const TextStyle(
                          color: Color(0xFFF57F17),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Code SMS (8 caractères)',
                  prefixIcon: Icon(Icons.sms_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mdpCtrl,
              obscureText: _obscure1,
              decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                      icon: Icon(_obscure1
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscure1 = !_obscure1))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: _obscure2,
              decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                      icon: Icon(_obscure2
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscure2 = !_obscure2))),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmer',
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
