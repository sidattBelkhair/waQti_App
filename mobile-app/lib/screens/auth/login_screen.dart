import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    final tel = _telCtrl.text.trim();
    if (tel.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final (userId, devOtp) = await auth.login(tel, _passwordCtrl.text);
    setState(() => _loading = false);

    if (userId != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => OTPScreen(userId: userId, devOtp: devOtp)));
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!), backgroundColor: WaqtiTheme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              Text(context.tr('app_name'), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(context.tr('app_subtitle'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.read<LocaleProvider>().toggle(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.language, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(context.watch<LocaleProvider>().isArabic ? 'Français' : 'العربية',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: WaqtiTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(context.tr('login'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: WaqtiTheme.textPrimary)),
                        Text(context.tr('login_subtitle'), style: const TextStyle(color: WaqtiTheme.textSecondary)),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _telCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.tr('phone'),
                            hintText: context.tr('phone_hint'),
                            prefixIcon: const Icon(Icons.phone_outlined, color: WaqtiTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: context.tr('password'),
                            prefixIcon: const Icon(Icons.lock_outline, color: WaqtiTheme.primary),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: WaqtiTheme.textSecondary),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: Text(context.tr('forgot_password'), style: const TextStyle(color: WaqtiTheme.primary)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: WaqtiTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(context.tr('sign_in')),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(context.tr('no_account'), style: const TextStyle(color: WaqtiTheme.textSecondary)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: Text(context.tr('create_account'), style: const TextStyle(fontWeight: FontWeight.bold, color: WaqtiTheme.primary)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
