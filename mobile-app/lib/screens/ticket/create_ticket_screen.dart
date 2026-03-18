import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import 'ticket_tracking_screen.dart';

class CreateTicketScreen extends StatefulWidget {
  final String etabId, etabNom, serviceId, serviceNom;
  const CreateTicketScreen({super.key, required this.etabId, required this.etabNom, required this.serviceId, required this.serviceNom});
  @override State<CreateTicketScreen> createState() => _State();
}

class _State extends State<CreateTicketScreen> {
  String _mode = 'distance';
  int _priorite = 4;
  bool _loading = false;

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().createTicket(widget.etabId, widget.serviceId, _mode, _priorite);
      if (mounted) {
        final ticket = res.data['ticket'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ticket ${ticket['numero']} cree ! Position: ${ticket['position']}'),
          backgroundColor: WaqtiTheme.success));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre un ticket')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.etabNom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.serviceNom, style: const TextStyle(color: WaqtiTheme.textSecondary)),
          ]))),
          const SizedBox(height: 24),
          const Text('Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...['distance', 'sur_place'].map((m) => RadioListTile<String>(
            title: Text(m == 'distance' ? 'A distance (depuis chez moi)' : 'Sur place'),
            value: m, groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v!),
          )),
          const SizedBox(height: 16),
          const Text('Priorite', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...({'4': 'Normal', '3': 'Femme enceinte', '2': 'Personne agee', '1': 'Urgent'}).entries.map((e) =>
            RadioListTile<int>(
              title: Text(e.value),
              value: int.parse(e.key), groupValue: _priorite,
              onChanged: (v) => setState(() => _priorite = v!),
            )),
          const Spacer(),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.confirmation_number),
              label: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirmer le ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _loading ? null : _create,
            )),
        ]),
      ),
    );
  }
}
