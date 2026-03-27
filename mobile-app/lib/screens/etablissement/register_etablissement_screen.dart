import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class RegisterEtablissementScreen extends StatefulWidget {
  const RegisterEtablissementScreen({super.key});
  @override State<RegisterEtablissementScreen> createState() => _State();
}

class _State extends State<RegisterEtablissementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _rueCtrl = TextEditingController();
  final _telCtrl = TextEditingController(text: '+222');
  final _emailCtrl = TextEditingController();

  String _type = 'banque';
  String? _ville;
  bool _loading = false;
  bool _success = false;
  Set<String> _selectedServices = {};

  // ─── Villes de Mauritanie ──────────────────────────────────
  static const _villes = [
    'Nouakchott',
    'Nouadhibou',
    'Zouerate',
    'Kiffa',
    'Kaédi',
    'Rosso',
    'Atar',
    'Tidjikja',
    'Néma',
    'Aleg',
    'Akjoujt',
    'Sélibaby',
    'Boutilimit',
    'Aïoun el-Atrouss',
    'Tichit',
    'Chinguetti',
    'Ouadane',
    'Bir Moghrein',
    'Fdérik',
    'Guerou',
    'Mbout',
  ];

  // ─── Types d'établissements ────────────────────────────────
  static const _types = {
    'banque':     'Banque',
    'hopital':    'Hôpital',
    'mairie':     'Mairie / État civil',
    'ambassade':  'Ambassade / Consulat',
    'poste':      'Poste',
    'telecom':    'Télécom',
    'universite': 'Université',
    'autre':      'Administration',
  };

  // ─── Services prédéfinis par domaine ──────────────────────
  static const _servicesByType = {
    'hopital': [
      'Urgences',
      'Consultation générale',
      'Consultation spécialisée',
      'Maternité / Pédiatrie',
      'Laboratoire',
      'Radiologie',
      'Pharmacie',
      'Chirurgie',
      'Cardiologie',
      'Ophtalmologie',
    ],
    'banque': [
      'Caisse / Retrait',
      'Dépôt / Virement',
      'Ouverture de compte',
      'Crédit / Prêt',
      'Service client',
      'Change de devises',
      'Chèques et virements',
    ],
    'ambassade': [
      'Demande de visa',
      'Légalisation de documents',
      'Service consulaire',
      'Passeport / Nationalité',
      'Attestation d\'état civil',
    ],
    'mairie': [
      'Acte de naissance',
      'Carte nationale d\'identité',
      'Certificat de résidence',
      'Permis de construire',
      'Enregistrement foncier',
      'Acte de mariage',
    ],
    'poste': [
      'Envoi de colis',
      'Retrait de colis',
      'Mandat postal',
      'Abonnement',
      'Service courrier',
    ],
    'telecom': [
      'Assistance technique',
      'Abonnement / Forfait',
      'Réclamation',
      'Activation SIM',
      'Paiement facture',
    ],
    'universite': [
      'Inscription / Réinscription',
      'Scolarité / Diplômes',
      'Service pédagogique',
      'Bibliothèque',
      'Bourse / Aide sociale',
    ],
    'autre': [
      'Service général',
      'Information',
      'Réclamation',
      'Rendez-vous administratif',
    ],
  };

  List<String> get _availableServices =>
      _servicesByType[_type] ?? _servicesByType['autre']!;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ville == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez une ville'),
          backgroundColor: WaqtiTheme.warning));
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez au moins un service'),
          backgroundColor: WaqtiTheme.warning));
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Créer l'établissement
      final res = await ApiService().registerEtablissement({
        'nom': _nomCtrl.text.trim(),
        'type': _type,
        'adresse': {'rue': _rueCtrl.text.trim(), 'ville': _ville},
        'telephone': _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      final etabId = res.data['etablissement']?['_id'];
      if (etabId != null && etabId is String) {
        // 2. Créer les services sélectionnés
        await Future.wait(_selectedServices.map((nom) =>
            ApiService().createService(etabId, {'nom': nom}).catchError((_) {})));
      }

      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _rueCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessView();

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer mon établissement')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Bannière info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: WaqtiTheme.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Après soumission, un administrateur validera votre établissement avant qu\'il soit visible.',
                    style: TextStyle(color: WaqtiTheme.primary, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Informations générales ──
            _SectionTitle('Informations générales'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement *',
                  prefixIcon: Icon(Icons.business)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 16),

            // Domaine — dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                  labelText: 'Domaine *',
                  prefixIcon: Icon(Icons.category)),
              items: _types.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  _selectedServices = {};
                });
              },
            ),
            const SizedBox(height: 24),

            // ── Services prédéfinis ──
            _SectionTitle('Services proposés'),
            const SizedBox(height: 4),
            Text(
              'Sélectionnez les services pour "${_types[_type]}"',
              style: const TextStyle(
                  fontSize: 13, color: WaqtiTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: _availableServices.map((svc) {
                  final selected = _selectedServices.contains(svc);
                  return CheckboxListTile(
                    dense: true,
                    value: selected,
                    title: Text(svc,
                        style: const TextStyle(fontSize: 14)),
                    activeColor: WaqtiTheme.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedServices.add(svc);
                        } else {
                          _selectedServices.remove(svc);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (_selectedServices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_selectedServices.length} service(s) sélectionné(s)',
                style: const TextStyle(
                    color: WaqtiTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 24),

            // ── Adresse ──
            _SectionTitle('Adresse'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _rueCtrl,
              decoration: const InputDecoration(
                  labelText: 'Rue / Quartier *',
                  prefixIcon: Icon(Icons.location_on)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 16),

            // Ville — dropdown Mauritanie
            DropdownButtonFormField<String>(
              value: _ville,
              decoration: const InputDecoration(
                  labelText: 'Ville *',
                  prefixIcon: Icon(Icons.location_city)),
              hint: const Text('Sélectionnez une ville'),
              items: _villes
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _ville = v),
              validator: (v) =>
                  (v == null) ? 'Sélectionnez une ville' : null,
            ),
            const SizedBox(height: 24),

            // ── Contact ──
            _SectionTitle('Contact'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone)),
              validator: (v) =>
                  (v == null || v.trim().length < 8)
                      ? 'Numéro invalide'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(
                    _loading ? 'Envoi en cours...' : 'Soumettre pour validation',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _loading ? null : _submit,
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: WaqtiTheme.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Demande envoyée !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Votre établissement et ses services sont en attente de validation.\nUn administrateur va examiner votre dossier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
}
