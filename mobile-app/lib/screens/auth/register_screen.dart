import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController(text: '+222');
  final _mdpCtrl = TextEditingController();
  bool _loading = false;
  String _role = 'client';

  Future<void> _register() async {
    if (_nomCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _telCtrl.text.length < 8 || _mdpCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Remplissez tous les champs (mot de passe min 6 caracteres)')));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final (userId, devOtp) = await auth.register(
        _nomCtrl.text.trim(), _emailCtrl.text.trim(),
        _telCtrl.text.trim(), _mdpCtrl.text, _role);
    setState(() => _loading = false);

    if (userId != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => OTPScreen(userId: userId, devOtp: devOtp)));
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!), backgroundColor: WaqtiTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 16),
          TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 16),
          TextField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Telephone', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 16),
          TextField(
              controller: _mdpCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Mot de passe (min 6 car.)',
                  prefixIcon: Icon(Icons.lock_outline))),
          const SizedBox(height: 24),

          // Selecteur de role
          const Text('Je suis :',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _RoleCard(
              icon: Icons.person,
              label: 'Client',
              selected: _role == 'client',
              onTap: () => setState(() => _role = 'client'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _RoleCard(
              icon: Icons.business_center,
              label: 'Gestionnaire',
              selected: _role == 'gestionnaire',
              onTap: () => setState(() => _role = 'gestionnaire'),
            )),
          ]),
          if (_role == 'gestionnaire') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: WaqtiTheme.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous pourrez enregistrer votre etablissement apres la connexion.',
                    style: TextStyle(color: WaqtiTheme.primary, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Creer mon compte',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? WaqtiTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? WaqtiTheme.primary : const Color(0xFFE2E8F0),
              width: 2),
        ),
        child: Column(children: [
          Icon(icon,
              color: selected ? Colors.white : WaqtiTheme.textSecondary,
              size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : WaqtiTheme.textSecondary)),
        ]),
      ),
    );
  }
}
