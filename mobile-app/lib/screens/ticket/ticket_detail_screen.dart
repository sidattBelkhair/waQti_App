import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/theme.dart';
import '../../widgets/pulsing_dot.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});
  @override State<TicketDetailScreen> createState() => _State();
}

class _State extends State<TicketDetailScreen> {
  late Ticket _ticket;
  int _position = 0;
  int _tempsEstime = 0;
  String? _message;
  String? _ticketEnCoursNumero;
  int _lastPosition = 0;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _position = widget.ticket.position;
    _lastPosition = widget.ticket.position;
    _tempsEstime = widget.ticket.tempsEstime;
    _setupSocket();
    _loadFileStatus();
  }

  Future<void> _loadFileStatus() async {
    try {
      final res = await ApiService().getFileStatus(_ticket.serviceId ?? '');
      final file = res.data['file'];
      final enCours = file['ticketEnCours'];
      setState(() {
        _ticketEnCoursNumero = enCours is Map ? enCours['numero'] : null;
      });
    } catch (_) {}
  }

  void _setupSocket() {
    if (_ticket.serviceId != null) {
      SocketService().joinService(_ticket.serviceId!);
    }
    SocketService().onFileUpdated = (data) {
      if (data['ticketId']?.toString() == _ticket.id) {
        final newPos = data['position'] ?? _position;
        final advanced = newPos < _lastPosition && _lastPosition > 0;
        setState(() {
          _position = newPos;
          _tempsEstime = data['tempsEstime'] ?? _tempsEstime;
          if (advanced && newPos > 1) _message = 'La file avance — vous êtes maintenant ${_ordinal(newPos)} !';
          _lastPosition = newPos;
        });
      }
      _loadFileStatus();
    };
    SocketService().onTourApproche = (data) {
      if (data['ticketId']?.toString() == _ticket.id) {
        setState(() => _message = 'Vous êtes le prochain !');
        _showAlert('Votre tour approche !', 'Préparez-vous à vous présenter au guichet.');
      }
    };
    SocketService().onVotreTour = (data) {
      if (data['ticketId']?.toString() == _ticket.id) {
        setState(() => _message = "C'est votre tour ! Guichet ${data['guichet']}");
        _showAlert("C'est votre tour !", "Rendez-vous au guichet ${data['guichet']}.");
      }
    };
  }

  void _showAlert(String title, String body) {
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.notifications_active, color: WaqtiTheme.primary),
        const SizedBox(width: 8), Text(title),
      ]),
      content: Text(body),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Annuler le ticket ?'),
      content: Text('Annuler ${_ticket.numero} ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui', style: TextStyle(color: WaqtiTheme.danger))),
      ],
    ));
    if (ok != true) return;
    try {
      await ApiService().cancelTicket(_ticket.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  Future<void> _signalerRetard() async {
    try {
      await ApiService().signalRetard(_ticket.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Retard signalé, votre place est conservée'),
            backgroundColor: WaqtiTheme.success));
      }
    } catch (_) {}
  }

  // QR code = juste le numéro de ticket, simple à scanner
  String get _qrData => _ticket.numero;

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Présentez ce QR code au guichet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            QrImageView(data: _qrData, version: QrVersions.auto, size: 200),
            const SizedBox(height: 16),
            Text(_ticket.numero,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  String _ordinal([int? pos]) {
    final p = pos ?? _position;
    if (p == 1) return '1er';
    return '${p}ème';
  }

  String get _departureLabel {
    final eta = DateTime.now().add(Duration(minutes: _tempsEstime));
    return '${eta.hour.toString().padLeft(2, '0')}h${eta.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    if (_ticket.serviceId != null) SocketService().leaveService(_ticket.serviceId!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnCours = _ticket.statut == 'en_cours';
    final personnesDevant = _position > 0 ? _position - 1 : 0;

    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(
        title: const Text('Mon Ticket'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFileStatus),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Indicateur connexion ──
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const PulsingDot(),
              const SizedBox(width: 8),
              Text(
                SocketService().isConnected ? 'Connecté · Mise à jour en direct' : 'Connexion en cours…',
                style: const TextStyle(
                    color: WaqtiTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ]),
          ),

          // ── Ticket héro ──
          _HeroTicket(
            numero: _ticket.numero,
            etabNom: _ticket.etablissementNom ?? '',
            isEnCours: isEnCours,
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Afficher mon QR code'),
              onPressed: _showQrDialog,
            ),
          ),

          if (isEnCours) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: WaqtiTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.check_circle, color: WaqtiTheme.success),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("C'est votre tour ! Présentez-vous au guichet.",
                      style: TextStyle(color: WaqtiTheme.success, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 8),
            // ── Stats côte à côte ──
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: 'Personnes devant',
                  value: '$personnesDevant',
                  color: WaqtiTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Minutes estimées',
                  value: '$_tempsEstime',
                  color: WaqtiTheme.warning,
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Progression de la file ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border.fromBorderSide(BorderSide(color: WaqtiTheme.border))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Progression de la file',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: Stack(children: [
                      Container(color: WaqtiTheme.border),
                      FractionallySizedBox(
                        widthFactor: (_position > 0 ? 1 / _position : 1.0).clamp(0.03, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                      'En cours : ${_ticketEnCoursNumero != null ? 'N°$_ticketEnCoursNumero' : '—'}',
                      style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 12)),
                  Text('Partez vers $_departureLabel',
                      style: const TextStyle(
                          color: WaqtiTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ],

          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.notifications_active, color: WaqtiTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_message!,
                    style: const TextStyle(color: WaqtiTheme.primary, fontWeight: FontWeight.w600))),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          if (!isEnCours)
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 16),
              label: const Text('Signaler un retard'),
              onPressed: _signalerRetard,
            ),
          const SizedBox(height: 4),

          // ── Bouton annuler (ghost) ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler le ticket'),
              style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: WaqtiTheme.danger,
                  side: const BorderSide(color: WaqtiTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _cancel,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Ticket héro ────────────────────────────────────────────────
class _HeroTicket extends StatelessWidget {
  final String numero;
  final String etabNom;
  final bool isEnCours;
  const _HeroTicket({required this.numero, required this.etabNom, required this.isEnCours});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          gradient: WaqtiTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isEnCours ? 'EN COURS' : 'VOTRE TICKET',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 14),
          Text(numero,
              style: const TextStyle(
                  color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold, height: 1.0)),
          const SizedBox(height: 10),
          Text(etabNom,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
      // Encoches circulaires
      Positioned(
        left: -12, top: 0, bottom: 0,
        child: Center(child: Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: WaqtiTheme.background, shape: BoxShape.circle))),
      ),
      Positioned(
        right: -12, top: 0, bottom: 0,
        child: Center(child: Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: WaqtiTheme.background, shape: BoxShape.circle))),
      ),
    ]);
  }
}

// ─── Stat card ──────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: WaqtiTheme.border))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 12)),
    ]),
  );
}
