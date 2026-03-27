import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override State<QrScannerScreen> createState() => _State();
}

class _State extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  String? _lastResult;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw == _lastResult) return;

    setState(() { _processing = true; _lastResult = raw; });
    await _ctrl.stop();

    // QR code = numéro de ticket (ex: WQ260325-9755)
    final numero = raw.trim().toUpperCase();
    if (!numero.startsWith('WQ')) {
      _showResult(false, 'QR code invalide', 'Ce QR code ne correspond pas à un ticket WaQti.');
      setState(() { _processing = false; _lastResult = null; });
      await _ctrl.start();
      return;
    }

    try {
      final res = await ApiService().validerPresenceByNumero(numero);
      final client = res.data['client'];
      _showResult(true, 'Présence validée !',
          'Ticket $numero\n${client['nom'] ?? ''}');
    } catch (e) {
      final msg = e.toString().contains('404')
          ? 'Ticket introuvable ou déjà traité.'
          : 'Erreur de connexion. Réessayez.';
      _showResult(false, 'Erreur', msg);
    }
  }

  void _showResult(bool success, String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
                color: success ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                shape: BoxShape.circle),
            child: Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? WaqtiTheme.success : WaqtiTheme.danger,
                size: 42),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: WaqtiTheme.textSecondary),
              textAlign: TextAlign.center),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() { _processing = false; _lastResult = null; });
                _ctrl.start();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: success ? WaqtiTheme.success : WaqtiTheme.primary),
              child: Text(success ? 'Scanner suivant' : 'Réessayer'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner le ticket client'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(children: [
        // Scanner
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),

        // Overlay avec fenêtre de scan
        Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Pointez la caméra vers le QR code du client',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                // Coins
                Positioned(top: 0, left: 0, child: _Corner()),
                Positioned(top: 0, right: 0, child: Transform.rotate(
                    angle: 1.5708, child: _Corner())),
                Positioned(bottom: 0, left: 0, child: Transform.rotate(
                    angle: -1.5708, child: _Corner())),
                Positioned(bottom: 0, right: 0, child: Transform.rotate(
                    angle: 3.14159, child: _Corner())),
                // Ligne de scan animée
                if (!_processing) const Center(child: _ScanLine()),
                if (_processing) const Center(child: CircularProgressIndicator(
                    color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Validation automatique à la détection',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Corner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: WaqtiTheme.primary, width: 4),
          left: BorderSide(color: WaqtiTheme.primary, width: 4),
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: -100, end: 100).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          height: 2, width: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              WaqtiTheme.primary.withOpacity(0.8),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    );
  }
}
