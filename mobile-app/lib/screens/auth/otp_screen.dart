import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class OTPScreen extends StatefulWidget {
  final String userId;
  const OTPScreen({super.key, required this.userId});
  @override State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  int _countdown = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) setState(() => _countdown--);
      else t.cancel();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(widget.userId, _otpCtrl.text);
    setState(() => _loading = false);

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!), backgroundColor: WaqtiTheme.danger));
    }
  }

  String get _timerText {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms_outlined, size: 64, color: WaqtiTheme.primary),
            const SizedBox(height: 24),
            const Text('Code de verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Un code a 6 chiffres a ete envoye par SMS', textAlign: TextAlign.center, style: TextStyle(color: WaqtiTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(_timerText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _countdown > 0 ? WaqtiTheme.primary : WaqtiTheme.danger)),
            const SizedBox(height: 32),
            TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 16, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(counterText: '', hintText: '000000')),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: _loading || _countdown <= 0 ? null : _verify,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verifier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 16),
            TextButton(onPressed: _countdown <= 0 ? () { setState(() => _countdown = 300); } : null,
              child: const Text('Renvoyer le code')),
          ],
        ),
      ),
    );
  }
}
