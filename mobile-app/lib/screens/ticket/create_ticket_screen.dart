import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../home/home_screen.dart';
import '../../models/ticket.dart';
import 'ticket_detail_screen.dart';

class CreateTicketScreen extends StatefulWidget {
  final String etabId, etabNom, serviceId, serviceNom;
  final int? nbPersonnes;
  final int? tempsEstime;
  const CreateTicketScreen({
    super.key,
    required this.etabId,
    required this.etabNom,
    required this.serviceId,
    required this.serviceNom,
    this.nbPersonnes,
    this.tempsEstime,
  });
  @override State<CreateTicketScreen> createState() => _State();
}

// Priorité : valeurs métier existantes (1=urgent .. 4=normal). L'UI n'expose
// que 3 choix, conformes au parcours cible.
const _priorites = [
  (label: 'Normal', value: 4, icon: Icons.person_outline),
  (label: 'Personne âgée', value: 2, icon: Icons.elderly),
  (label: 'Femme enceinte', value: 3, icon: Icons.pregnant_woman),
];

class _State extends State<CreateTicketScreen> {
  int _priorite = 4;
  bool _loading = false;
  bool _loadingStats = false;
  int? _nbPersonnes;
  int? _tempsEstime;

  @override
  void initState() {
    super.initState();
    _nbPersonnes = widget.nbPersonnes;
    _tempsEstime = widget.tempsEstime;
    if (_nbPersonnes == null || _tempsEstime == null) _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final res = await ApiService().getFileStatus(widget.serviceId);
      final nb = res.data['file']['totalEnAttente'] as int? ?? 0;
      setState(() {
        _nbPersonnes = nb;
        _tempsEstime = 10 * (nb == 0 ? 1 : nb);
      });
    } catch (_) {
      setState(() {
        _nbPersonnes = 0;
        _tempsEstime = 0;
      });
    }
    setState(() => _loadingStats = false);
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().createTicket(widget.etabId, widget.serviceId, 'distance', _priorite);
      if (mounted) {
        final ticket = res.data['ticket'];
        final t = Ticket.fromJson(ticket);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t)),
          (route) => route.isFirst,
        );
        homeTabNotifier.value = 1;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(title: const Text('Confirmer le ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Récapitulatif ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: const Border.fromBorderSide(BorderSide(color: WaqtiTheme.border))),
            child: Column(children: [
              _RecapRow(label: 'Établissement', value: widget.etabNom),
              const Divider(height: 20, color: WaqtiTheme.border),
              _RecapRow(label: 'Service', value: widget.serviceNom),
              const Divider(height: 20, color: WaqtiTheme.border),
              _RecapRow(
                  label: 'Personnes en attente',
                  value: _loadingStats ? '…' : '${_nbPersonnes ?? 0}'),
              const Divider(height: 20, color: WaqtiTheme.border),
              _RecapRow(
                label: 'Temps estimé',
                value: _loadingStats ? '…' : '~${_tempsEstime ?? 0} min',
                valueColor: WaqtiTheme.warning,
              ),
            ]),
          ),
          const SizedBox(height: 28),

          const Text('Priorité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: _priorites.map((p) {
            final selected = _priorite == p.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p == _priorites.last ? 0 : 10),
                child: GestureDetector(
                  onTap: () => setState(() => _priorite = p.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? WaqtiTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected ? WaqtiTheme.primary : WaqtiTheme.border,
                          width: selected ? 2 : 1),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(p.icon, size: 22,
                          color: selected ? WaqtiTheme.primary : WaqtiTheme.textSecondary),
                      const SizedBox(height: 6),
                      Text(p.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? WaqtiTheme.primary : WaqtiTheme.textSecondary)),
                    ]),
                  ),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: WaqtiTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: _loading ? const SizedBox.shrink() : const Icon(Icons.confirmation_number),
                label: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmer mon ticket',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _loading ? null : _create,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _RecapRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 14)),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? WaqtiTheme.textPrimary)),
    ],
  );
}
