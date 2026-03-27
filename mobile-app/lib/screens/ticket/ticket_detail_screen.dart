import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/theme.dart';

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

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _position = widget.ticket.position;
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
        setState(() {
          _position = data['position'] ?? _position;
          _tempsEstime = data['tempsEstime'] ?? _tempsEstime;
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

  // QR code = juste le numéro de ticket, simple à scanner
  String get _qrData => _ticket.numero;

  String get _ordinal {
    if (_position == 1) return '1er';
    return '${_position}ème';
  }

  @override
  void dispose() {
    if (_ticket.serviceId != null) SocketService().leaveService(_ticket.serviceId!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnCours = _ticket.statut == 'en_cours';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Mon Ticket'),
        backgroundColor: const Color(0xFF00695C),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFileStatus),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Carte ticket principale
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(children: [
                // Header gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00695C), Color(0xFF004D40)],
                    ),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Icon(Icons.access_time, color: Colors.white54, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                            color: isEnCours
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(isEnCours ? 'EN COURS' : 'EN ATTENTE',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 48),
                    ]),
                    const SizedBox(height: 12),
                    Text(_ticket.numero,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 42, fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 16),
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 140,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Présentez ce QR code au guichet',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
                ),

                // Bord festonné
                Container(
                  height: 24,
                  color: Colors.white,
                  child: Stack(children: [
                    Positioned(left: -12, top: -12, child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF0F4F8), shape: BoxShape.circle))),
                    Positioned(right: -12, top: -12, child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF0F4F8), shape: BoxShape.circle))),
                  ]),
                ),

                // Infos client
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(children: [
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.person_outline,
                        label: 'Nom', value: _ticket.clientNom ?? '—'),
                    _InfoRow(icon: Icons.business_outlined,
                        label: 'Établissement', value: _ticket.etablissementNom ?? '—'),
                    _InfoRow(icon: Icons.layers_outlined,
                        label: 'Service', value: _ticket.serviceNom ?? '—'),
                    _InfoRow(icon: Icons.calendar_today_outlined,
                        label: 'Date', value: _formatDate(_ticket.createdAt)),
                    _InfoRow(icon: Icons.access_time_outlined,
                        label: 'Heure', value: _formatTime(_ticket.createdAt)),
                  ]),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Position en file
          if (!isEnCours) Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 10)]),
            child: Column(children: [
              const Text('Votre position', style: TextStyle(
                  color: WaqtiTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(_ordinal,
                  style: const TextStyle(color: Color(0xFF00695C),
                      fontSize: 44, fontWeight: FontWeight.bold)),
              Text('sur $_position personne(s) dans la file',
                  style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _position > 0 ? 1 / _position : 0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0F2F1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer_outlined, size: 18,
                    color: WaqtiTheme.textSecondary),
                const SizedBox(width: 6),
                Text('Temps estimé avant votre tour',
                    style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Text('± $_tempsEstime minutes',
                  style: const TextStyle(color: Color(0xFFE65100),
                      fontSize: 22, fontWeight: FontWeight.bold)),
              if (_ticketEnCoursNumero != null) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.circle, color: Color(0xFF66BB6A), size: 10),
                  const SizedBox(width: 6),
                  Text('En cours de traitement : $_ticketEnCoursNumero',
                      style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13)),
                ]),
              ],
            ]),
          ),

          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.notifications_active,
                    color: WaqtiTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_message!,
                    style: const TextStyle(color: WaqtiTheme.primary,
                        fontWeight: FontWeight.w600))),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // Boutons action
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text('Signaler retard'),
                onPressed: () async {
                  try {
                    await ApiService().signalRetard(_ticket.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Retard signalé'),
                            backgroundColor: WaqtiTheme.success));
                  } catch (_) {}
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: WaqtiTheme.danger,
                    side: const BorderSide(color: WaqtiTheme.danger)),
                onPressed: _cancel,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static const _months = ['jan','fév','mar','avr','mai','jun',
      'jul','aoû','sep','oct','nov','déc'];
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: WaqtiTheme.textSecondary),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label,
            style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 12))),
        Expanded(child: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.right)),
      ]),
    );
  }
}
