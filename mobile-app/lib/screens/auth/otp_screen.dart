import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';

class OTPScreen extends StatefulWidget {
  final String userId;
  final String? devOtp; // code visible en mode test (non-production)
  const OTPScreen({super.key, required this.userId, this.devOtp});
  @override State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  int _countdown = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(widget.userId, _otpCtrl.text);
    setState(() => _loading = false);

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.error!), backgroundColor: WaqtiTheme.danger));
    }
  }

  Future<void> _resend() async {
    // TODO: appeler /api/auth/resend-otp si tu l'implémentes
    setState(() => _countdown = 300);
  }

  String get _timerText {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('otp_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(gradient: WaqtiTheme.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.sms_outlined, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(context.tr('otp_title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(context.tr('otp_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: WaqtiTheme.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _countdown > 60 ? WaqtiTheme.primaryLight : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _timerText,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _countdown > 60 ? WaqtiTheme.primary : WaqtiTheme.warning),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(counterText: '', hintText: '——————'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: WaqtiTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  onPressed: (_loading || _countdown <= 0) ? null : _verify,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('otp_verify')),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _countdown <= 0 ? _resend : null,
              child: Text(context.tr('otp_resend'),
                  style: TextStyle(color: _countdown <= 0 ? WaqtiTheme.primary : WaqtiTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
