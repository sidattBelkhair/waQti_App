import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

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
    // Pré-remplir le champ si le code est disponible (mode dev)
    if (widget.devOtp != null) {
      _otpCtrl.text = widget.devOtp!;
    }
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
      appBar: AppBar(title: const Text('Vérification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.sms_outlined,
                  size: 40, color: WaqtiTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Code de vérification',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Un code à 6 chiffres a été envoyé par SMS',
                textAlign: TextAlign.center,
                style: TextStyle(color: WaqtiTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(
              _timerText,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _countdown > 0
                      ? WaqtiTheme.primary
                      : WaqtiTheme.danger),
            ),

            // ── Bandeau dev : code visible ──
            if (widget.devOtp != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCA28))),
                child: Row(children: [
                  const Icon(Icons.bug_report_outlined,
                      color: Color(0xFFF57F17), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode test — Code : ${widget.devOtp}',
                      style: const TextStyle(
                          color: Color(0xFFF57F17),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                  counterText: '', hintText: '000000'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || _countdown <= 0) ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Vérifier',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _countdown <= 0 ? _resend : null,
              child: const Text('Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}
