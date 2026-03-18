import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../models/service.dart';
import '../../config/theme.dart';
import 'register_etablissement_screen.dart';

class EtablissementDashboardScreen extends StatefulWidget {
  const EtablissementDashboardScreen({super.key});
  @override State<EtablissementDashboardScreen> createState() => _State();
}

class _State extends State<EtablissementDashboardScreen> {
  Map<String, dynamic>? _etab;
  List<Service> _services = [];
  Service? _selectedService;
  Map<String, dynamic>? _fileData;
  bool _loading = true;
  bool _calling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getMyEtablissement();
      _etab = res.data['etablissement'];

      if (_etab!['statut'] == 'actif') {
        final sRes = await ApiService().getServices(_etab!['_id']);
        _services = (sRes.data['services'] as List)
            .map((s) => Service.fromJson(s))
            .toList();
        if (_services.isNotEmpty) {
          _selectedService = _services.first;
          await _loadFile();
          _setupSocket();
        }
      }
    } catch (_) {
      _etab = null;
    }
    setState(() => _loading = false);
  }

  Future<void> _loadFile() async {
    if (_selectedService == null) return;
    try {
      final res = await ApiService().getFileStatus(_selectedService!.id);
      setState(() => _fileData = res.data['file']);
    } catch (_) {
      setState(() => _fileData = null);
    }
  }

  void _setupSocket() {
    if (_selectedService == null) return;
    SocketService().joinService(_selectedService!.id);
    SocketService().onFileUpdated = (_) => _loadFile();
  }

  Future<void> _appelSuivant() async {
    if (_selectedService == null) return;
    setState(() => _calling = true);
    try {
      final res = await ApiService().appelSuivant(_selectedService!.id, 1);
      final client = res.data['client'];
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.campaign, color: WaqtiTheme.primary),
              SizedBox(width: 8),
              Text('Client appele'),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(client['numero'] ?? '',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: WaqtiTheme.primary)),
              const SizedBox(height: 4),
              Text(client['nom'] ?? '',
                  style: const TextStyle(color: WaqtiTheme.textSecondary)),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      }
      await _loadFile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().contains('File vide')
                ? 'La file est vide'
                : 'Erreur : $e'),
            backgroundColor: WaqtiTheme.warning));
      }
    }
    setState(() => _calling = false);
  }

  @override
  void dispose() {
    if (_selectedService != null) SocketService().leaveService(_selectedService!.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_etab == null) return _buildNoEtab();
    if (_etab!['statut'] == 'en_attente') return _buildEnAttente();
    return _buildDashboard();
  }

  Widget _buildNoEtab() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Etablissement')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.store_outlined, size: 80, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 20),
            const Text('Aucun etablissement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Enregistrez votre etablissement pour commencer a gerer votre file d\'attente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text('Enregistrer mon etablissement',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterEtablissementScreen()))
                    .then((_) => _load()),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEnAttente() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Etablissement')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_empty,
                  color: WaqtiTheme.warning, size: 48),
            ),
            const SizedBox(height: 24),
            Text(_etab!['nom'] ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('En attente de validation',
                  style: TextStyle(
                      color: WaqtiTheme.warning, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Votre etablissement est en cours d\'examen par un administrateur. Il sera active bientot.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Verifier le statut'),
              onPressed: _load,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final tickets = _fileData?['tickets'] as List? ?? [];
    final enAttente = tickets.length;
    final ticketEnCours = _fileData?['ticketEnCours'];
    final clientsTraites = _fileData?['stats']?['clientsTraites'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_etab!['nom'] ?? 'Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFile)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Sélecteur de service (si plusieurs)
            if (_services.length > 1) ...[
              DropdownButtonFormField<Service>(
                value: _selectedService,
                decoration: const InputDecoration(
                    labelText: 'Service', prefixIcon: Icon(Icons.layers)),
                items: _services.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s.nom))).toList(),
                onChanged: (s) {
                  if (_selectedService != null)
                    SocketService().leaveService(_selectedService!.id);
                  setState(() { _selectedService = s; _fileData = null; });
                  _loadFile();
                  _setupSocket();
                },
              ),
              const SizedBox(height: 16),
            ],

            // Stats rapides
            Row(children: [
              _StatCard(icon: Icons.people, label: 'En attente',
                  value: '$enAttente', color: WaqtiTheme.primary),
              const SizedBox(width: 12),
              _StatCard(icon: Icons.check_circle, label: 'Traites aujourd\'hui',
                  value: '$clientsTraites', color: WaqtiTheme.success),
            ]),
            const SizedBox(height: 16),

            // Ticket en cours
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ticket en cours',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: WaqtiTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  ticketEnCours != null
                      ? Row(children: [
                          const Icon(Icons.confirmation_number,
                              color: WaqtiTheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            ticketEnCours is Map
                                ? (ticketEnCours['numero'] ?? '—')
                                : '—',
                            style: const TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: WaqtiTheme.primary),
                          ),
                        ])
                      : const Text('Aucun ticket en cours',
                          style: TextStyle(color: WaqtiTheme.textSecondary)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton appeler suivant
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: _calling
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.campaign, size: 26),
                label: Text(
                    _calling ? 'Appel en cours...' : 'Appeler le suivant',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: (_calling || enAttente == 0) ? null : _appelSuivant,
                style: ElevatedButton.styleFrom(
                    backgroundColor: enAttente > 0
                        ? WaqtiTheme.primary
                        : WaqtiTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // Liste file d'attente
            if (enAttente > 0) ...[
              Text('File d\'attente ($enAttente)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tickets.take(5).toList().asMap().entries.map((e) {
                final t = e.value;
                final num = t is Map ? (t['numero'] ?? '—') : '—';
                final prio = t is Map ? (t['priorite'] ?? 4) : 4;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: const Border.fromBorderSide(
                          BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: WaqtiTheme.primaryLight,
                      child: Text('${e.key + 1}',
                          style: const TextStyle(color: WaqtiTheme.primary,
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(num,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    _PriorityBadge(priorite: prio),
                  ]),
                );
              }),
              if (enAttente > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${enAttente - 5} autres en attente',
                      style: const TextStyle(
                          color: WaqtiTheme.textSecondary, fontSize: 13)),
                ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: const [
                    Icon(Icons.done_all, color: WaqtiTheme.success, size: 48),
                    SizedBox(height: 8),
                    Text('File vide — aucun client en attente',
                        style: TextStyle(color: WaqtiTheme.textSecondary)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon, required this.label,
       required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                color: WaqtiTheme.textSecondary, fontSize: 13)),
      ]),
    ),
  );
}

class _PriorityBadge extends StatelessWidget {
  final int priorite;
  const _PriorityBadge({required this.priorite});

  @override
  Widget build(BuildContext context) {
    const labels = {1: 'Urgent', 2: 'Agee', 3: 'Enceinte', 4: 'Normal'};
    const colors = {
      1: WaqtiTheme.danger,
      2: WaqtiTheme.warning,
      3: Color(0xFF7B1FA2),
      4: WaqtiTheme.textSecondary,
    };
    final color = colors[priorite] ?? WaqtiTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(labels[priorite] ?? 'Normal',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
