import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class GestionnaireTicketsScreen extends StatefulWidget {
  const GestionnaireTicketsScreen({super.key});
  @override State<GestionnaireTicketsScreen> createState() => _State();
}

class _State extends State<GestionnaireTicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getEtablissementTickets();
      setState(() => _tickets = List<Map<String, dynamic>>.from(res.data['tickets'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(
        title: const Text('Tickets clients'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
                    itemBuilder: (_, i) => _TicketCard(ticket: _tickets[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.confirmation_number_outlined, size: 64, color: WaqtiTheme.textSecondary),
      SizedBox(height: 16),
      Text('Aucun ticket validé aujourd\'hui',
          style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 15)),
    ]),
  );
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final numero = ticket['numero'] ?? '';
    final statut = ticket['statut'] ?? '';
    final client = ticket['utilisateur'];
    final service = ticket['service'];
    final clientNom = client?['nom'] ?? 'Inconnu';
    final clientTel = client?['telephone'] ?? '';
    final serviceNom = service?['nom'] ?? '';
    final updatedAt = ticket['updatedAt'] != null
        ? DateTime.tryParse(ticket['updatedAt'])
        : null;
    final heure = updatedAt != null
        ? '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}'
        : '';

    Color statutColor;
    IconData statutIcon;
    String statutLabel;
    switch (statut) {
      case 'en_cours':
        statutColor = WaqtiTheme.primary;
        statutIcon = Icons.play_circle_outline;
        statutLabel = 'En cours';
        break;
      case 'termine':
        statutColor = WaqtiTheme.success;
        statutIcon = Icons.check_circle_outline;
        statutLabel = 'Terminé';
        break;
      case 'absent':
        statutColor = WaqtiTheme.warning;
        statutIcon = Icons.person_off_outlined;
        statutLabel = 'Absent';
        break;
      default:
        statutColor = WaqtiTheme.textSecondary;
        statutIcon = Icons.circle_outlined;
        statutLabel = statut;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        // Statut icon
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: statutColor.withOpacity(0.1),
              shape: BoxShape.circle),
          child: Icon(statutIcon, color: statutColor, size: 22),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(numero,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                    fontFamily: 'monospace')),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(statutLabel,
                  style: TextStyle(color: statutColor, fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(clientNom,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Row(children: [
            Text(serviceNom,
                style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
            if (clientTel.isNotEmpty) ...[
              const Text(' · ',
                  style: TextStyle(color: WaqtiTheme.textSecondary)),
              Text(clientTel,
                  style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
            ],
          ]),
        ])),
        // Heure
        if (heure.isNotEmpty)
          Text(heure,
              style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
      ]),
    );
  }
}
