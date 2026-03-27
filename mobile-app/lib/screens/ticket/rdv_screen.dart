import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ticket.dart';
import '../../config/theme.dart';
import '../home/home_screen.dart';
import 'ticket_detail_screen.dart';

class RdvScreen extends StatefulWidget {
  final String etabId, etabNom, serviceId, serviceNom;
  const RdvScreen({super.key, required this.etabId, required this.etabNom,
      required this.serviceId, required this.serviceNom});
  @override State<RdvScreen> createState() => _State();
}

class _State extends State<RdvScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedCreneau;
  bool _loading = false;

  static const _creneaux = [
    '08:00','08:30','09:00','09:30','10:00','10:30',
    '11:00','11:30','13:00','13:30','14:00','14:30',
    '15:00','15:30','16:00','16:30',
  ];

  // Creneaux désactivés (simulé - heures passées ou indisponibles)
  Set<String> get _disabled {
    final now = DateTime.now();
    if (_selectedDate.day == now.day) {
      return _creneaux.where((c) {
        final parts = c.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return h < now.hour || (h == now.hour && m <= now.minute);
      }).toSet();
    }
    return {'12:00', '14:00'}; // Simuler quelques indispos
  }

  Future<void> _confirm() async {
    if (_selectedCreneau == null) return;
    setState(() => _loading = true);
    try {
      final dateStr = '${_selectedDate.year}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';
      final res = await ApiService().createTicketRDV(
          widget.etabId, widget.serviceId, dateStr, _selectedCreneau!);
      if (mounted) {
        final t = Ticket.fromJson(res.data['ticket']);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t)),
          (route) => route.isFirst,
        );
        homeTabNotifier.value = 1;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(title: const Text('Prendre un rendez-vous')),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Info établissement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE2E8F0)))),
                child: Column(children: [
                  _InfoRdvRow('Établissement', widget.etabNom),
                  const Divider(height: 16),
                  _InfoRdvRow('Service', widget.serviceNom),
                ]),
              ),
              const SizedBox(height: 20),

              // Calendrier
              const Text('Sélectionnez une date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE2E8F0)))),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  onDateChanged: (d) => setState(() {
                    _selectedDate = d;
                    _selectedCreneau = null;
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Créneaux horaires
              const Text('Créneaux horaires',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _creneaux.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, childAspectRatio: 2.4,
                    crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemBuilder: (_, i) {
                  final c = _creneaux[i];
                  final disabled = _disabled.contains(c);
                  final selected = _selectedCreneau == c;
                  return GestureDetector(
                    onTap: disabled ? null : () => setState(() => _selectedCreneau = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: disabled ? const Color(0xFFF1F5F9)
                            : selected ? WaqtiTheme.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: disabled ? const Color(0xFFE2E8F0)
                              : selected ? WaqtiTheme.primary
                              : const Color(0xFFCBD5E1),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(c, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: disabled ? const Color(0xFFCBD5E1)
                              : selected ? Colors.white
                              : WaqtiTheme.textPrimary,
                          decoration: disabled ? TextDecoration.lineThrough : null,
                        )),
                      ),
                    ),
                  );
                },
              ),

              if (_selectedCreneau != null) ...[
                const SizedBox(height: 24),
                // Récapitulatif
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: WaqtiTheme.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                      border: const Border.fromBorderSide(
                          BorderSide(color: WaqtiTheme.primary))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.event_available, color: WaqtiTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Rendez-vous',
                          style: TextStyle(color: WaqtiTheme.primary,
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                    const SizedBox(height: 12),
                    _InfoRdvRow('Établissement', widget.etabNom),
                    const SizedBox(height: 4),
                    _InfoRdvRow('Service', widget.serviceNom),
                    const SizedBox(height: 4),
                    _InfoRdvRow('Date', _formatDate(_selectedDate)),
                    const SizedBox(height: 4),
                    _InfoRdvRow('Heure', _selectedCreneau!),
                  ]),
                ),
              ],
              const SizedBox(height: 100),
            ]),
          ),
        ),

        // Bouton confirmer fixe en bas
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12,
                blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Column(children: [
            if (_selectedCreneau == null)
              const Text('Sélectionnez un créneau pour confirmer',
                  style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_loading ? 'Confirmation...' : 'Confirmer le rendez-vous',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: (_loading || _selectedCreneau == null) ? null : _confirm,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Vous recevrez un SMS de rappel 1h avant votre rendez-vous',
                style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 11),
                textAlign: TextAlign.center),
          ]),
        ),
      ]),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['janvier','février','mars','avril','mai','juin',
        'juillet','août','septembre','octobre','novembre','décembre'];
    const days = ['lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'];
    final wd = d.weekday - 1;
    return '${days[wd]} ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _InfoRdvRow extends StatelessWidget {
  final String label, value;
  const _InfoRdvRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(
          color: WaqtiTheme.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13)),
    ],
  );
}
