import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../etablissement/register_etablissement_screen.dart';

class GestionnaireEtablissementScreen extends StatefulWidget {
  const GestionnaireEtablissementScreen({super.key});
  @override State<GestionnaireEtablissementScreen> createState() => _State();
}

class _State extends State<GestionnaireEtablissementScreen> {
  Map<String, dynamic>? _etab;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getMyEtablissement();
      setState(() => _etab = res.data['etablissement']);
    } catch (_) {
      setState(() => _etab = null);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_etab == null) return _buildNoEtab();
    if (_etab!['statut'] == 'en_attente') return _buildEnAttente();
    return _buildEtab();
  }

  // ─── Pas encore d'établissement ───────────────────────────
  Widget _buildNoEtab() {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(title: const Text('Mon Établissement')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: WaqtiTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.add_business, size: 50, color: WaqtiTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Aucun établissement',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Créez votre établissement pour commencer à gérer votre file d\'attente et accueillir vos clients.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_business),
                label: const Text('Créer mon établissement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const RegisterEtablissementScreen()))
                    .then((_) => _load()),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── En attente de validation ──────────────────────────────
  Widget _buildEnAttente() {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      appBar: AppBar(title: const Text('Mon Établissement')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_bottom,
                  size: 48, color: WaqtiTheme.warning),
            ),
            const SizedBox(height: 24),
            Text(_etab!['nom'] ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('En attente de validation',
                  style: TextStyle(color: WaqtiTheme.warning,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Un administrateur va examiner votre dossier.\nVous pourrez gérer vos services une fois votre établissement validé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WaqtiTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier le statut'),
              onPressed: _load,
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Établissement actif ───────────────────────────────────
  Widget _buildEtab() {
    final nom = _etab!['nom'] ?? '';
    final type = _etab!['type'] ?? '';
    final adresse = _etab!['adresse'] ?? {};
    final ville = adresse['ville'] ?? '';
    final rue = adresse['rue'] ?? '';
    final tel = _etab!['telephone'] ?? '';
    // email removed
    final note = (_etab!['noteMoyenne'] ?? 0.0).toDouble();
    final avis = _etab!['nombreAvis'] ?? 0;
    final statut = _etab!['statut'] ?? '';

    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: WaqtiTheme.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Modifier',
                  onPressed: () => _showEditDialog(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [WaqtiTheme.primary, WaqtiTheme.primaryDark],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(type.toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: statut == 'actif'
                                ? const Color(0xFF66BB6A) : Colors.orange,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(statut == 'actif' ? '● ACTIF' : statut.toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(nom, style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text('$rue, $ville',
                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    ]),
                  ]),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Stats rapides
                  Row(children: [
                    _StatCard(Icons.star_rounded, '${note.toStringAsFixed(1)}/5',
                        'Note moyenne', Colors.amber),
                    const SizedBox(width: 12),
                    _StatCard(Icons.rate_review_outlined, '$avis',
                        'Avis clients', WaqtiTheme.primary),
                  ]),
                  const SizedBox(height: 20),

                  // Informations
                  const Text('Informations',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _InfoRow(Icons.phone_outlined, 'Téléphone', tel),
                    _InfoRow(Icons.location_city_outlined, 'Ville', ville),
                    _InfoRow(Icons.place_outlined, 'Adresse', rue),
                  ]),
                  const SizedBox(height: 20),

                  // Actions
                  const Text('Actions rapides',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Modifier\nl\'établissement',
                        color: WaqtiTheme.primary,
                        onTap: _showEditDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Supprimer\nl\'établissement',
                        color: WaqtiTheme.danger,
                        onTap: _confirmDelete,
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final nomCtrl = TextEditingController(text: _etab!['nom'] ?? '');
    final telCtrl = TextEditingController(text: _etab!['telephone'] ?? '');
    final rueCtrl = TextEditingController(
        text: _etab!['adresse']?['rue'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier l\'établissement'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom',
                    prefixIcon: Icon(Icons.business_outlined))),
            const SizedBox(height: 12),
            TextField(controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextField(controller: rueCtrl,
                decoration: const InputDecoration(labelText: 'Adresse / Rue',
                    prefixIcon: Icon(Icons.place_outlined))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().updateEtablissement(_etab!['_id'], {
                  'nom': nomCtrl.text.trim(),
                  'telephone': telCtrl.text.trim(),
                  'adresse': {
                    ...((_etab!['adresse'] as Map?) ?? {}),
                    'rue': rueCtrl.text.trim(),
                  },
                });
                await _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Établissement mis à jour'),
                        backgroundColor: WaqtiTheme.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'),
                        backgroundColor: WaqtiTheme.danger));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'établissement ?'),
        content: Text(
            'Supprimer "${_etab!['nom']}" supprimera aussi tous ses services. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WaqtiTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().deleteEtablissement(_etab!['_id']);
      setState(() => _etab = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'),
              backgroundColor: WaqtiTheme.danger));
    }
  }
}

// ─── Widgets locaux ────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatCard(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(
            color: WaqtiTheme.textSecondary, fontSize: 12)),
      ]),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0)))),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: WaqtiTheme.primary),
      const SizedBox(width: 12),
      SizedBox(width: 90, child: Text(label,
          style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13))),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          textAlign: TextAlign.right)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color,
            fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}
