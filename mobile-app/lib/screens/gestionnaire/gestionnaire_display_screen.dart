import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';

/// Mode "écran salle" : plein écran, destiné à une tablette posée en salle
/// d'attente. Affiche le ticket en cours et les prochains numéros.
class GestionnaireDisplayScreen extends StatefulWidget {
  final String serviceId;
  final String etabNom;
  const GestionnaireDisplayScreen({super.key, required this.serviceId, required this.etabNom});
  @override State<GestionnaireDisplayScreen> createState() => _State();
}

class _State extends State<GestionnaireDisplayScreen> {
  String? _numeroEnCours;
  List<String> _prochains = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SocketService().joinService(widget.serviceId);
    SocketService().onFileUpdated = (_) => _load();
    _load();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SocketService().leaveService(widget.serviceId);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getFileStatus(widget.serviceId);
      final file = res.data['file'];
      final enCours = file['ticketEnCours'];
      final tickets = (file['tickets'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _numeroEnCours = enCours is Map ? enCours['numero'] as String? : null;
          _prochains = tickets
              .take(3)
              .map((t) => (t as Map)['numero'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
        child: SafeArea(
          child: Stack(children: [
            Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(widget.etabNom,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(context.tr('g_current_ticket').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.w600)),
                Text(_numeroEnCours ?? '—',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 120, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 36),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final n in _prochains)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16)),
                        child: Text(n,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ]),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
                tooltip: context.tr('g_close_display'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
