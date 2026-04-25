import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/etablissement.dart';
import '../../models/service.dart';
import '../../config/theme.dart';
import '../ticket/create_ticket_screen.dart';
import '../ticket/rdv_screen.dart';

class EtablissementDetailScreen extends StatefulWidget {
  final String etabId;
  const EtablissementDetailScreen({super.key, required this.etabId});
  @override State<EtablissementDetailScreen> createState() => _State();
}

class _State extends State<EtablissementDetailScreen> {
  Etablissement? _etab;
  List<Service> _services = [];
  final Map<String, Map<String, dynamic>> _fileStat = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getEtablissement(widget.etabId),
        api.getServices(widget.etabId),
      ]);

      _etab = Etablissement.fromJson(results[0].data['etablissement']);
      _services = (results[1].data['services'] as List)
          .map((s) => Service.fromJson(s))
          .toList();

      await Future.wait(_services.map((s) async {
        try {
          final f = await api.getFileStatus(s.id);
          _fileStat[s.id] = {
            'total': f.data['file']['totalEnAttente'] ?? 0,
          };
        } catch (_) {
          _fileStat[s.id] = {'total': 0};
        }
      }));
    } catch (e) {
      debugPrint('Erreur chargement établissement: $e');
    }
    setState(() => _loading = false);
  }

  void _goToTicket(Service s) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateTicketScreen(
            etabId: _etab!.id, etabNom: _etab!.nom,
            serviceId: s.id, serviceNom: s.nom)));
  }

  void _goToRdv(Service s) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => RdvScreen(
            etabId: _etab!.id, etabNom: _etab!.nom,
            serviceId: s.id, serviceNom: s.nom)));
  }

  /// Affiche un bottom sheet pour choisir un service, puis navigue.
  void _pickServiceThen({required bool isRdv}) {
    if (_services.isEmpty) return;
    if (_services.length == 1) {
      isRdv ? _goToRdv(_services.first) : _goToTicket(_services.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(
            isRdv ? 'Choisir un service pour le RDV'
                  : 'Choisir un service pour le ticket',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._services.map((s) {
            final nb = _fileStat[s.id]?['total'] as int? ?? 0;
            return ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: WaqtiTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_iconForService(s.nom),
                    color: WaqtiTheme.primary, size: 20),
              ),
              title: Text(s.nom,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(isRdv ? 'Prendre un rendez-vous'
                  : '$nb personne(s) en attente'),
              trailing: const Icon(Icons.chevron_right,
                  color: WaqtiTheme.textSecondary),
              onTap: () {
                Navigator.pop(context);
                isRdv ? _goToRdv(s) : _goToTicket(s);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_etab == null) {
      return const Scaffold(
          body: Center(child: Text('Établissement introuvable')));
    }
    final e = _etab!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: WaqtiTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [WaqtiTheme.primary, Color(0xFF00897B)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_typeLabel(e.type).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 8),
                    Text(e.nom,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                            '${e.adresse.rue}, ${e.adresse.ville}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                          '${e.noteMoyenne.toStringAsFixed(1)}/5',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(' (${e.nombreAvis} avis)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ]),
                ),
              ),
            ),

            // ── Titre services ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(children: [
                  const Text('Services disponibles',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: WaqtiTheme.textPrimary)),
                  const Spacer(),
                  if (_services.isNotEmpty)
                    Text('${_services.length} service(s)',
                        style: const TextStyle(
                            color: WaqtiTheme.textSecondary, fontSize: 13)),
                ]),
              ),
            ),

            // ── Liste des services ──
            _services.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        const Icon(Icons.layers_outlined,
                            size: 56, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        const Text('Aucun service disponible',
                            style: TextStyle(
                                color: WaqtiTheme.textSecondary)),
                      ]),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final s = _services[i];
                          final nb =
                              _fileStat[s.id]?['total'] as int? ?? 0;
                          final tps = s.dureeEstimee * (nb == 0 ? 1 : nb);
                          return _ServiceCard(
                            service: s,
                            nbPersonnes: nb,
                            tempsEstime: tps,
                            onTicket: () => _goToTicket(s),
                            onRdv: () => _goToRdv(s),
                          );
                        },
                        childCount: _services.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),

      // ── Boutons fixes en bas ──
      bottomNavigationBar: _services.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ],
              ),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Prendre un ticket',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: WaqtiTheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                    onPressed: () => _pickServiceThen(isRdv: false),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('RDV',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: WaqtiTheme.primary,
                      side: const BorderSide(
                          color: WaqtiTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  onPressed: () => _pickServiceThen(isRdv: true),
                ),
              ]),
            ),
    );
  }

  String _typeLabel(String type) {
    const labels = {
      'hopital': 'Hôpital',
      'banque': 'Banque',
      'ambassade': 'Ambassade',
      'mairie': 'Mairie',
      'poste': 'Poste',
      'telecom': 'Télécom',
      'universite': 'Université',
      'autre': 'Administration',
    };
    return labels[type] ?? type;
  }
}

// ─── Service Card ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Service service;
  final int nbPersonnes;
  final int tempsEstime;
  final VoidCallback onTicket;
  final VoidCallback onRdv;

  const _ServiceCard({
    required this.service,
    required this.nbPersonnes,
    required this.tempsEstime,
    required this.onTicket,
    required this.onRdv,
  });

  @override
  Widget build(BuildContext context) {
    final tempsColor = tempsEstime <= 15
        ? WaqtiTheme.success
        : tempsEstime <= 30
            ? WaqtiTheme.warning
            : WaqtiTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info ligne
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_iconForService(service.nom),
                  color: WaqtiTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(service.nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (service.description.isNotEmpty)
                  Text(service.description,
                      style: const TextStyle(
                          color: WaqtiTheme.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$nbPersonnes en attente',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: WaqtiTheme.textSecondary)),
              Text('~$tempsEstime min',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tempsColor)),
            ]),
          ]),
        ),

        // Boutons par service
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                label: const Text('Ticket',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: WaqtiTheme.primary,
                    side: const BorderSide(color: WaqtiTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: onTicket,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('RDV',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00897B),
                    side: const BorderSide(color: Color(0xFF00897B)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: onRdv,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

IconData _iconForService(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('urgent')) return Icons.emergency;
  if (n.contains('consult') || n.contains('général')) return Icons.medical_services;
  if (n.contains('dent')) return Icons.health_and_safety;
  if (n.contains('maternit') || n.contains('pédiat')) return Icons.child_care;
  if (n.contains('labo')) return Icons.science;
  if (n.contains('pharmacie')) return Icons.medication;
  if (n.contains('caisse') || n.contains('retrait') || n.contains('paiement')) return Icons.payments;
  if (n.contains('credit') || n.contains('prêt')) return Icons.credit_card;
  if (n.contains('compte')) return Icons.account_balance;
  if (n.contains('visa')) return Icons.card_travel;
  if (n.contains('acte') || n.contains('état civil')) return Icons.description;
  if (n.contains('colis')) return Icons.inventory_2;
  if (n.contains('inscription')) return Icons.school;
  if (n.contains('abonnement') || n.contains('sim')) return Icons.sim_card;
  return Icons.layers;
}
