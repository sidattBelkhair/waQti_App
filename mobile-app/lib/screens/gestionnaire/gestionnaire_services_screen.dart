import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../etablissement/qr_scanner_screen.dart';

class GestionnaireServicesScreen extends StatefulWidget {
  const GestionnaireServicesScreen({super.key});
  @override State<GestionnaireServicesScreen> createState() => _State();
}

class _State extends State<GestionnaireServicesScreen> {
  List<Map<String, dynamic>> _services = [];
  Map<String, Map<String, dynamic>> _fileStatus = {};
  Map<String, dynamic>? _etab;
  String? _etabId;
  bool _loading = true;

  // Services prédéfinis par domaine
  static const _servicesByType = {
    'hopital': [
      'Urgences', 'Consultation générale', 'Consultation spécialisée',
      'Maternité / Pédiatrie', 'Laboratoire', 'Radiologie',
      'Pharmacie', 'Chirurgie', 'Cardiologie', 'Ophtalmologie',
    ],
    'banque': [
      'Caisse / Retrait', 'Dépôt / Virement', 'Ouverture de compte',
      'Crédit / Prêt', 'Service client', 'Change de devises',
      'Chèques et virements',
    ],
    'ambassade': [
      'Demande de visa', 'Légalisation de documents', 'Service consulaire',
      'Passeport / Nationalité', "Attestation d'état civil",
    ],
    'mairie': [
      'Acte de naissance', "Carte nationale d'identité",
      'Certificat de résidence', 'Permis de construire',
      'Enregistrement foncier', 'Acte de mariage',
    ],
    'poste': [
      'Envoi de colis', 'Retrait de colis', 'Mandat postal',
      'Abonnement', 'Service courrier',
    ],
    'telecom': [
      'Assistance technique', 'Abonnement / Forfait', 'Réclamation',
      'Activation SIM', 'Paiement facture',
    ],
    'universite': [
      'Inscription / Réinscription', 'Scolarité / Diplômes',
      'Service pédagogique', 'Bibliothèque', 'Bourse / Aide sociale',
    ],
    'autre': [
      'Service général', 'Information', 'Réclamation',
      'Rendez-vous administratif',
    ],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final etabRes = await ApiService().getMyEtablissement();
      _etab = etabRes.data['etablissement'] as Map<String, dynamic>?;
      if (_etab == null) {
        setState(() => _loading = false);
        return;
      }
      _etabId = _etab!['_id'] as String?;

      final svcRes = await ApiService().getServices(_etabId!);
      final svcs = List<Map<String, dynamic>>.from(
          svcRes.data['services'] ?? []);

      final statuses = await Future.wait(
        svcs.map((s) => ApiService()
            .getFileStatus(s['_id'] as String)
            .then((r) => r.data)
            .catchError((_) => <String, dynamic>{})),
      );

      final statusMap = <String, Map<String, dynamic>>{};
      for (var i = 0; i < svcs.length; i++) {
        final fileData = statuses[i]['file'] as Map? ?? {};
        statusMap[svcs[i]['_id'] as String] =
            Map<String, dynamic>.from(fileData);
      }

      setState(() {
        _services = svcs;
        _fileStatus = statusMap;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _appelSuivant(String serviceId) async {
    try {
      await ApiService().appelSuivant(serviceId, 1);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Client suivant appelé'),
            backgroundColor: WaqtiTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  Future<void> _marquerAbsent(String serviceId) async {
    try {
      await ApiService().marquerAbsent(serviceId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Client marqué absent'),
            backgroundColor: WaqtiTheme.warning));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  /// Affiche un bottom sheet pour ajouter un ou plusieurs services.
  /// Si l'établissement a un type connu, propose les services prédéfinis.
  void _showAddDialog() {
    if (_etabId == null) return;

    final etabType = (_etab?['type'] as String?) ?? 'autre';
    final predefined = _servicesByType[etabType] ?? _servicesByType['autre']!;
    final existingNames =
        _services.map((s) => s['nom'] as String).toSet();

    // Exclure les services déjà créés
    final available =
        predefined.where((s) => !existingNames.contains(s)).toList();

    if (available.isEmpty) {
      // Aucun prédéfini restant → formulaire libre
      _showCustomServiceDialog();
      return;
    }

    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Ajouter des services',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sélectionnez les services à ajouter à votre établissement',
                style: TextStyle(
                    fontSize: 13, color: WaqtiTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  ...available.map((svc) => CheckboxListTile(
                    dense: true,
                    value: selected.contains(svc),
                    title: Text(svc),
                    activeColor: WaqtiTheme.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setS(() =>
                        v! ? selected.add(svc) : selected.remove(svc)),
                  )),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined,
                        color: WaqtiTheme.primary),
                    title: const Text('Nom personnalisé',
                        style: TextStyle(color: WaqtiTheme.primary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCustomServiceDialog();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _createServices(selected.toList());
                          },
                    child: Text('Ajouter (${selected.length})'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showCustomServiceDialog() {
    if (_etabId == null) return;
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau service'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom du service',
                  prefixIcon: Icon(Icons.layers_outlined))),
          const SizedBox(height: 12),
          TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.description_outlined))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final nom = nomCtrl.text.trim();
              if (nom.isEmpty) return;
              Navigator.pop(context);
              await _createServices([nom], description: descCtrl.text.trim());
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _createServices(List<String> noms,
      {String description = ''}) async {
    try {
      await Future.wait(noms.map((nom) =>
          ApiService().createService(_etabId!, {
            'nom': nom,
            if (description.isNotEmpty) 'description': description,
          })));
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(noms.length == 1
                ? 'Service créé'
                : '${noms.length} services créés'),
            backgroundColor: WaqtiTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce service ?'),
        content: Text(
            'Supprimer "${service['nom']}" supprimera aussi tous ses tickets en attente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WaqtiTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || _etabId == null) return;
    try {
      await ApiService().deleteService(_etabId!, service['_id'] as String);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(
        title: const Text('Mes Services'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _etabId == null
              ? _buildNoEtab()
              : _services.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _services.length,
                        itemBuilder: (_, i) => _ServiceCard(
                          service: _services[i],
                          status: _fileStatus[_services[i]['_id']] ?? {},
                          onAppelSuivant: () =>
                              _appelSuivant(_services[i]['_id'] as String),
                          onAbsent: () =>
                              _marquerAbsent(_services[i]['_id'] as String),
                          onScanQR: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const QrScannerScreen()))
                              .then((_) => _load()),
                          onDelete: () => _confirmDelete(_services[i]),
                        ),
                      ),
                    ),
      floatingActionButton: _etabId != null
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un service'),
            )
          : null,
    );
  }

  Widget _buildNoEtab() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.business_outlined,
                size: 64, color: WaqtiTheme.textSecondary),
            SizedBox(height: 16),
            Text("Créez d'abord votre établissement",
                style: TextStyle(
                    fontSize: 16, color: WaqtiTheme.textSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  shape: BoxShape.circle),
              child: const Icon(Icons.layers_outlined,
                  size: 44, color: WaqtiTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Aucun service',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Ajoutez vos services pour que les clients puissent réserver.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary),
            ),
            const SizedBox(height: 80),
          ]),
        ),
      );
}

// ─── Service Card ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> status;
  final VoidCallback onAppelSuivant, onAbsent, onScanQR, onDelete;

  const _ServiceCard({
    required this.service,
    required this.status,
    required this.onAppelSuivant,
    required this.onAbsent,
    required this.onScanQR,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nom = service['nom'] as String? ?? '';
    final duree = service['dureeEstimee'] as int? ?? 15;
    final enAttente = status['totalEnAttente'] as int? ?? 0;
    final enCours = status['ticketEnCours'];
    final hasEnCours = enCours != null;

    final queueColor = enAttente == 0
        ? WaqtiTheme.success
        : enAttente < 5
            ? WaqtiTheme.warning
            : WaqtiTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WaqtiTheme.primary.withOpacity(0.05),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.layers_outlined,
                  color: WaqtiTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$duree min par client',
                    style: const TextStyle(
                        color: WaqtiTheme.textSecondary, fontSize: 12)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: WaqtiTheme.danger, size: 20),
              onPressed: onDelete,
              tooltip: 'Supprimer',
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _StatPill(
              icon: Icons.people_outlined,
              label: '$enAttente en attente',
              color: queueColor,
            ),
            const SizedBox(width: 8),
            if (hasEnCours)
              _StatPill(
                icon: Icons.play_circle_outline,
                label: 'En cours: ${enCours['numero'] ?? ''}',
                color: WaqtiTheme.primary,
              ),
          ]),
        ),

        // Client en cours
        if (hasEnCours)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.person_outlined,
                    size: 16, color: WaqtiTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${(enCours['utilisateur'] as Map?)?['nom'] ?? 'Client'} '
                    '— Ticket ${enCours['numero'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: WaqtiTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ),

        // Boutons d'action
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.skip_next_outlined,
                label: 'Suivant',
                color: WaqtiTheme.primary,
                onTap: onAppelSuivant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                icon: Icons.qr_code_scanner,
                label: 'Scanner',
                color: WaqtiTheme.success,
                onTap: onScanQR,
              ),
            ),
            if (hasEnCours) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.person_off_outlined,
                  label: 'Absent',
                  color: WaqtiTheme.warning,
                  onTap: onAbsent,
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: color.withOpacity(0.25))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
