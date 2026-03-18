import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../models/ticket.dart';
import '../../config/theme.dart';

class TicketTrackingScreen extends StatefulWidget {
  const TicketTrackingScreen({super.key});
  @override State<TicketTrackingScreen> createState() => _State();
}

class _State extends State<TicketTrackingScreen> {
  List<Ticket> _tickets = [];
  // ticketId -> {position, tempsEstime, message}
  final Map<String, Map<String, dynamic>> _updates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _setupSocket();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getMesTickets();
      setState(() {
        _tickets = (res.data['tickets'] as List)
            .map((t) => Ticket.fromJson(t))
            .toList();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _setupSocket() {
    SocketService().onFileUpdated = (data) {
      final ticketId = data['ticketId']?.toString();
      if (ticketId == null) return;
      setState(() {
        _updates[ticketId] = {
          ..._updates[ticketId] ?? {},
          'position': data['position'],
          'tempsEstime': data['tempsEstime'],
        };
      });
    };

    SocketService().onTourApproche = (data) {
      final ticketId = data['ticketId']?.toString();
      if (ticketId == null) return;
      setState(() {
        _updates[ticketId] = {
          ..._updates[ticketId] ?? {},
          'message': 'Vous etes le prochain !',
        };
      });
      _showAlert('Votre tour approche !', 'Preparez-vous a vous presenter.');
    };

    SocketService().onVotreTour = (data) {
      final ticketId = data['ticketId']?.toString();
      if (ticketId == null) return;
      setState(() {
        _updates[ticketId] = {
          ..._updates[ticketId] ?? {},
          'message': "C'est votre tour ! Guichet ${data['guichet']}",
        };
      });
      _showAlert("C'est votre tour !", "Rendez-vous au guichet ${data['guichet']}.");
      _load();
    };
  }

  void _showAlert(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.notifications_active, color: WaqtiTheme.primary),
          const SizedBox(width: 8),
          Text(title),
        ]),
        content: Text(body, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> _cancel(Ticket ticket) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler le ticket ?'),
        content: Text('Voulez-vous annuler le ticket ${ticket.numero} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui, annuler',
                  style: TextStyle(color: WaqtiTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().cancelTicket(ticket.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tickets'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) => _TicketCard(
                      ticket: _tickets[i],
                      update: _updates[_tickets[i].id],
                      onCancel: () => _cancel(_tickets[i]),
                      onRetard: () async {
                        try {
                          await ApiService().signalRetard(_tickets[i].id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Retard signale, votre place est conservee'),
                                    backgroundColor: WaqtiTheme.success));
                          }
                        } catch (_) {}
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.confirmation_number_outlined,
            size: 80, color: Color(0xFFCBD5E1)),
        SizedBox(height: 16),
        Text('Aucun ticket actif',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Recherchez un etablissement\npour prendre un ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WaqtiTheme.textSecondary)),
      ]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final Map<String, dynamic>? update;
  final VoidCallback onCancel;
  final VoidCallback onRetard;

  const _TicketCard({
    required this.ticket,
    required this.update,
    required this.onCancel,
    required this.onRetard,
  });

  @override
  Widget build(BuildContext context) {
    final position = update?['position'] ?? ticket.position;
    final tempsEstime = update?['tempsEstime'] ?? ticket.tempsEstime;
    final message = update?['message'] as String?;
    final isEnCours = ticket.statut == 'en_cours';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isEnCours ? WaqtiTheme.success : WaqtiTheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ticket.numero,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text(isEnCours ? 'En cours' : 'En attente',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.business, size: 16, color: WaqtiTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${ticket.etablissementNom ?? ''} — ${ticket.serviceNom ?? ''}',
                  style: const TextStyle(color: WaqtiTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 12),

            if (!isEnCours)
              Row(children: [
                Expanded(child: _InfoBox(
                    icon: Icons.format_list_numbered, label: 'Position',
                    value: '$position', color: WaqtiTheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: _InfoBox(
                    icon: Icons.timer, label: 'Attente estimee',
                    value: '~$tempsEstime min', color: WaqtiTheme.warning)),
              ]),

            if (message != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: WaqtiTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.notifications_active,
                      color: WaqtiTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message,
                      style: const TextStyle(color: WaqtiTheme.primary))),
                ]),
              ),
            ],

            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: const Text('Retard'),
                  onPressed: onRetard,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: WaqtiTheme.danger,
                      side: const BorderSide(color: WaqtiTheme.danger)),
                  onPressed: onCancel,
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBox(
      {required this.icon, required this.label,
       required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
