import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_identifierCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final (userId, devOtp) = await auth.login(_identifierCtrl.text.trim(), _passwordCtrl.text);
    setState(() => _loading = false);

    if (userId != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => OTPScreen(userId: userId, devOtp: devOtp)));
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: WaqtiTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: WaqtiTheme.primary, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.access_time, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('WaQti', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: WaqtiTheme.textPrimary)),
              const Text('Mon Temps', style: TextStyle(fontSize: 16, color: WaqtiTheme.textSecondary)),
              const SizedBox(height: 48),
              TextField(controller: _identifierCtrl, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email ou Telephone', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(controller: _passwordCtrl, obscureText: _obscure,
                decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: const Text('Mot de passe oublié ?'))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Pas de compte ? ', style: TextStyle(color: WaqtiTheme.textSecondary)),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Creer un compte')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
