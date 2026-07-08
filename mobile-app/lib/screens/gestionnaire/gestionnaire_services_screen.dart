import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';

class GestionnaireServicesScreen extends StatefulWidget {
  const GestionnaireServicesScreen({super.key});
  @override State<GestionnaireServicesScreen> createState() => _State();
}

class _State extends State<GestionnaireServicesScreen> {
  List<Map<String, dynamic>> _services = [];
  Map<String, int> _enAttente = {};
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
            .then((r) => r.data is Map ? r.data as Map<String, dynamic> : <String, dynamic>{})
            .catchError((_) => <String, dynamic>{})),
      );

      final enAttenteMap = <String, int>{};
      for (var i = 0; i < svcs.length; i++) {
        final fileRaw = statuses[i]['file'];
        final fileData = fileRaw is Map ? Map<String, dynamic>.from(fileRaw) : <String, dynamic>{};
        final tickets = fileData['tickets'];
        enAttenteMap[svcs[i]['_id'] as String] = tickets is List ? tickets.length : 0;
      }

      setState(() {
        _services = svcs;
        _enAttente = enAttenteMap;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggleActif(Map<String, dynamic> service, bool actif) async {
    final id = service['_id'] as String;
    setState(() => service['actif'] = actif);
    try {
      await ApiService().updateService(_etabId!, id, {'actif': actif});
    } catch (e) {
      setState(() => service['actif'] = !actif);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
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
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
            padding: const EdgeInsets.fromLTRB(20, 50, 12, 20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr('g_my_services'),
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(context.tr('g_open_close_hint'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
            ]),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else if (_etabId == null)
          SliverFillRemaining(hasScrollBody: false, child: _buildNoEtab())
        else if (_services.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ServiceCard(
                  service: _services[i],
                  enAttente: _enAttente[_services[i]['_id']] ?? 0,
                  onToggle: (v) => _toggleActif(_services[i], v),
                  onDelete: () => _confirmDelete(_services[i]),
                ),
                childCount: _services.length,
              ),
            ),
          ),
      ]),
      floatingActionButton: _etabId != null
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un service'),
            )
          : null,
    );
  }

  Widget _buildNoEtab() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.business_outlined,
                size: 64, color: WaqtiTheme.textSecondary),
            const SizedBox(height: 16),
            Text(context.tr('g_no_etab'),
                style: const TextStyle(
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
          ]),
        ),
      );
}

// ─── Service Card ──────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final int enAttente;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.enAttente,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nom = service['nom'] as String? ?? '';
    final actif = service['actif'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaqtiTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: WaqtiTheme.primaryLight,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.layers_outlined, color: WaqtiTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Text('$enAttente ${context.tr('g_waiting')}',
                style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 12.5)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: WaqtiTheme.danger, size: 19),
          onPressed: onDelete,
          visualDensity: VisualDensity.compact,
        ),
        Switch(value: actif, activeColor: WaqtiTheme.success, onChanged: onToggle),
      ]),
    );
  }
}
