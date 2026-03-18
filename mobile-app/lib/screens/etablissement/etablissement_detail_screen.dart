import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/etablissement.dart';
import '../../models/service.dart';
import '../../config/theme.dart';
import '../ticket/create_ticket_screen.dart';

class EtablissementDetailScreen extends StatefulWidget {
  final String etabId;
  const EtablissementDetailScreen({super.key, required this.etabId});
  @override State<EtablissementDetailScreen> createState() => _State();
}

class _State extends State<EtablissementDetailScreen> {
  Etablissement? _etab;
  List<Service> _services = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ApiService();
      final etabRes = await api.getEtablissement(widget.etabId);
      final servRes = await api.getServices(widget.etabId);
      _etab = Etablissement.fromJson(etabRes.data['etablissement']);
      _services = (servRes.data['services'] as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) { debugPrint('Erreur: $e'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_etab == null) return const Scaffold(body: Center(child: Text('Etablissement non trouve')));
    final e = _etab!;

    return Scaffold(
      appBar: AppBar(title: Text(e.nom)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            color: WaqtiTheme.primary,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(e.type, style: const TextStyle(color: Colors.white))),
              const SizedBox(height: 12),
              Text(e.nom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              if (e.description.isNotEmpty) ...[const SizedBox(height: 4), Text(e.description, style: const TextStyle(color: Colors.white70))],
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text('${e.adresse.rue}, ${e.adresse.ville}', style: const TextStyle(color: Colors.white70)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${e.noteMoyenne}/5 (${e.nombreAvis} avis)', style: const TextStyle(color: Colors.white)),
              ]),
            ]),
          ),

          // Horaires
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Horaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...e.horaires.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(entry.value.ouvert ? '${entry.value.debut} - ${entry.value.fin}' : 'Ferme',
                    style: TextStyle(color: entry.value.ouvert ? WaqtiTheme.success : WaqtiTheme.danger)),
                ]),
              )),
            ]),
          ),

          const Divider(),

          // Services
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Services (${_services.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._services.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(s.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.description}\nDuree estimee: ${s.dureeEstimee} min'),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CreateTicketScreen(etabId: e.id, etabNom: e.nom, serviceId: s.id, serviceNom: s.nom))),
                    child: const Text('Prendre ticket'),
                  ),
                ),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
