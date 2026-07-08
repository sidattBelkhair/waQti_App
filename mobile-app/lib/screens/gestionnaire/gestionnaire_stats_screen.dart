import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import 'gestionnaire_tickets_screen.dart';

class GestionnaireStatsScreen extends StatefulWidget {
  const GestionnaireStatsScreen({super.key});
  @override State<GestionnaireStatsScreen> createState() => _State();
}

class _State extends State<GestionnaireStatsScreen> {
  bool _loading = true;
  bool _noEtab = false;
  int _servis = 0, _enAttente = 0, _tempsMoyen = 0, _absents = 0;

  static const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  static const _mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getGestionnaireStatsToday();
      final stats = res.data['stats'] as Map<String, dynamic>;
      setState(() {
        _servis = stats['servis'] as int? ?? 0;
        _enAttente = stats['enAttente'] as int? ?? 0;
        _tempsMoyen = stats['tempsMoyenMinutes'] as int? ?? 0;
        _absents = stats['absents'] as int? ?? 0;
        _noEtab = false;
      });
    } catch (_) {
      setState(() => _noEtab = true);
    }
    setState(() => _loading = false);
  }

  String get _todayLabel {
    final now = DateTime.now();
    return '${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
              padding: const EdgeInsets.fromLTRB(20, 50, 12, 20),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr('g_stats_title'),
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_todayLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: context.tr('g_history'),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GestionnaireTicketsScreen())),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_noEtab)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(context.tr('g_no_etab'),
                        style: const TextStyle(color: WaqtiTheme.textSecondary)),
                  ),
                )
              else ...[
                Row(children: [
                  Expanded(child: _StatCard(
                      value: '$_servis', label: context.tr('g_served'), color: WaqtiTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                      value: '$_enAttente', label: context.tr('g_waiting'), color: WaqtiTheme.primary)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatCard(
                      value: '$_tempsMoyen', label: context.tr('g_avg_time'), color: WaqtiTheme.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                      value: '$_absents', label: context.tr('g_absents_label'), color: WaqtiTheme.danger)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: WaqtiTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: WaqtiTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(context.tr('g_stats_note'),
                          style: const TextStyle(color: WaqtiTheme.primary, fontSize: 13)),
                    ),
                  ]),
                ),
              ],
            ])),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaqtiTheme.border)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 12)),
    ]),
  );
}
