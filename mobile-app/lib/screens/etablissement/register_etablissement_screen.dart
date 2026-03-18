import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class RegisterEtablissementScreen extends StatefulWidget {
  const RegisterEtablissementScreen({super.key});
  @override State<RegisterEtablissementScreen> createState() => _State();
}

class _State extends State<RegisterEtablissementScreen> {
  final _nomCtrl = TextEditingController();
  final _rueCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _telCtrl = TextEditingController(text: '+222');
  final _emailCtrl = TextEditingController();
  String _type = 'banque';
  bool _loading = false;
  bool _success = false;

  final _types = {
    'banque': 'Banque',
    'hopital': 'Hopital',
    'mairie': 'Mairie',
    'ambassade': 'Ambassade',
    'poste': 'Poste',
    'telecom': 'Telecom',
    'universite': 'Universite',
    'autre': 'Autre',
  };

  Future<void> _submit() async {
    if (_nomCtrl.text.isEmpty || _rueCtrl.text.isEmpty ||
        _villeCtrl.text.isEmpty || _telCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Remplissez tous les champs obligatoires')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().registerEtablissement({
        'nom': _nomCtrl.text.trim(),
        'type': _type,
        'adresse': {'rue': _rueCtrl.text.trim(), 'ville': _villeCtrl.text.trim()},
        'telephone': _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
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
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessView();

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer mon etablissement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
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
                  'Apres soumission, un administrateur validera votre etablissement avant qu\'il soit visible par les clients.',
                  style: TextStyle(color: WaqtiTheme.primary, fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          const Text('Informations generales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom de l\'etablissement *',
                  prefixIcon: Icon(Icons.business))),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
                labelText: 'Type d\'etablissement *',
                prefixIcon: Icon(Icons.category)),
            items: _types.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 24),

          const Text('Adresse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
              controller: _rueCtrl,
              decoration: const InputDecoration(
                  labelText: 'Rue / Quartier *',
                  prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 16),
          TextField(
              controller: _villeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Ville *',
                  prefixIcon: Icon(Icons.location_city))),
          const SizedBox(height: 24),

          const Text('Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Telephone *',
                  prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 16),
          TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email))),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_loading ? 'Envoi...' : 'Soumettre pour validation',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _loading ? null : _submit,
            ),
          ),
        ]),
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
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: WaqtiTheme.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Demande envoyee !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Votre etablissement est en attente de validation.\nUn administrateur va examiner votre dossier et l\'activer.',
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
