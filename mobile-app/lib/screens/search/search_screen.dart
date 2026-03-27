import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/etablissement.dart';
import '../../config/theme.dart';
import '../etablissement/etablissement_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<_EtabWithMeta> _results = [];
  bool _loading = false;
  bool _locating = false;
  String? _selectedCategory;
  Position? _userPosition;
  _SortMode _sortMode = _SortMode.distance;

  static const _categories = [
    {'key': 'hopital',    'label': 'Hôpitaux',      'icon': Icons.local_hospital,        'color': Color(0xFFE53935)},
    {'key': 'banque',     'label': 'Banques',        'icon': Icons.account_balance,       'color': Color(0xFF1565C0)},
    {'key': 'ambassade',  'label': 'Ambassades',     'icon': Icons.flag,                  'color': Color(0xFF6A1B9A)},
    {'key': 'mairie',     'label': 'État civil',     'icon': Icons.gavel,                 'color': Color(0xFF00838F)},
    {'key': 'poste',      'label': 'Poste',          'icon': Icons.local_post_office,     'color': Color(0xFFEF6C00)},
    {'key': 'telecom',    'label': 'Télécom',        'icon': Icons.phone_android,         'color': Color(0xFF2E7D32)},
    {'key': 'universite', 'label': 'Universités',    'icon': Icons.school,                'color': Color(0xFF558B2F)},
    {'key': 'autre',      'label': 'Administration', 'icon': Icons.account_balance_wallet,'color': Color(0xFF4527A0)},
  ];

  @override
  void initState() {
    super.initState();
    _getLocationThenFetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Géolocalisation ─────────────────────────────────────────
  Future<void> _getLocationThenFetch() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _locating = false); _fetch(); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        setState(() => _locating = false);
        _fetch();
        return;
      }

      _userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8));
    } catch (_) {}
    setState(() => _locating = false);
    _fetch();
  }

  // ── Calcul distance en km (formule Haversine) ───────────────
  double? _distanceKm(Etablissement e) {
    if (_userPosition == null) return null;
    final eLat = e.adresse.lat;
    final eLng = e.adresse.lng;
    if (eLat == 0 && eLng == 0) return null; // coordonnées non renseignées
    const R = 6371.0;
    final dLat = _toRad(eLat - _userPosition!.latitude);
    final dLon = _toRad(eLng - _userPosition!.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(_userPosition!.latitude)) *
            cos(_toRad(eLat)) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ── Fetch établissements ────────────────────────────────────
  Future<void> _fetch({String? query, String? type}) async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().searchEtablissements(
        nom: (query != null && query.isNotEmpty) ? query : null,
        type: type,
        lat: _userPosition?.latitude,
        lng: _userPosition?.longitude,
      );
      final etabs = (res.data['etablissements'] as List)
          .map((e) => Etablissement.fromJson(e))
          .toList();

      // Charger les stats de file pour chaque établissement
      final metaList = await Future.wait(etabs.map((e) async {
        int totalQueue = 0;
        try {
          final svcRes = await ApiService().getServices(e.id);
          final svcs = svcRes.data['services'] as List? ?? [];
          for (final svc in svcs) {
            try {
              final f = await ApiService().getFileStatus(svc['_id'] as String);
              totalQueue += (f.data['file']['totalEnAttente'] as int? ?? 0);
            } catch (_) {}
          }
        } catch (_) {}
        return _EtabWithMeta(
          etab: e,
          distanceKm: _distanceKm(e),
          totalQueue: totalQueue,
        );
      }));

      // Tri
      _sortResults(metaList);

      if (mounted) setState(() => _results = metaList);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _sortResults(List<_EtabWithMeta> list) {
    list.sort((a, b) {
      if (_sortMode == _SortMode.distance) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      } else {
        return a.totalQueue.compareTo(b.totalQueue);
      }
    });
  }

  void _onCategoryTap(String key) {
    final newCat = _selectedCategory == key ? null : key;
    setState(() => _selectedCategory = newCat);
    _fetch(query: _searchCtrl.text, type: newCat);
  }

  void _onSearchChanged(String v) =>
      _fetch(query: v, type: _selectedCategory);

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _selectedCategory = null);
    _fetch();
  }

  bool get _isFiltered =>
      _searchCtrl.text.isNotEmpty || _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AuthProvider>().user?.nom.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            snap: true,
            backgroundColor: WaqtiTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [WaqtiTheme.primary, WaqtiTheme.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Bonjour, $userName',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('Trouvez votre établissement',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_locating)
                      const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white70))
                    else if (_userPosition != null)
                      const Icon(Icons.my_location,
                          color: Colors.white70, size: 16),
                  ]),
                ]),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un établissement...',
                    prefixIcon: const Icon(Icons.search,
                        color: WaqtiTheme.primary),
                    suffixIcon: _isFiltered
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: WaqtiTheme.textSecondary),
                            onPressed: _clearFilters)
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          ),

          // ── Domaines ──
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Domaines',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WaqtiTheme.textPrimary)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final cat = _categories[i];
                  return _CategoryCard(
                    label: cat['label'] as String,
                    icon: cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    selected: _selectedCategory == cat['key'],
                    onTap: () => _onCategoryTap(cat['key'] as String),
                  );
                },
                childCount: _categories.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
            ),
          ),

          // ── Titre résultats + tri ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: Text(
                    _selectedCategory != null
                        ? (_categories.firstWhere((c) =>
                                c['key'] == _selectedCategory)['label']
                            as String)
                        : 'Tous les établissements',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WaqtiTheme.textPrimary),
                  ),
                ),
                if (!_loading) ...[
                  Text('${_results.length} résultat(s)',
                      style: const TextStyle(
                          color: WaqtiTheme.textSecondary,
                          fontSize: 12)),
                  const SizedBox(width: 8),
                  // Bouton tri
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortMode = _sortMode == _SortMode.distance
                            ? _SortMode.queue
                            : _SortMode.distance;
                        _sortResults(_results);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: WaqtiTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(
                          _sortMode == _SortMode.distance
                              ? Icons.near_me
                              : Icons.people_outline,
                          size: 14,
                          color: WaqtiTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortMode == _SortMode.distance
                              ? 'Plus proche'
                              : 'Moins d\'attente',
                          style: const TextStyle(
                              fontSize: 11,
                              color: WaqtiTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),
          ),

          // ── Liste ──
          if (_loading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_results.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.search_off,
                      size: 64, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text('Aucun établissement trouvé',
                      style:
                          TextStyle(color: WaqtiTheme.textSecondary)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _EtabCard(
                    meta: _results[i],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EtablissementDetailScreen(
                                etabId: _results[i].etab.id))),
                  ),
                  childCount: _results.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Data class ────────────────────────────────────────────────
enum _SortMode { distance, queue }

class _EtabWithMeta {
  final Etablissement etab;
  final double? distanceKm;
  final int totalQueue;
  const _EtabWithMeta(
      {required this.etab,
      required this.distanceKm,
      required this.totalQueue});
}

// ─── Category Card ─────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryCard(
      {required this.label,
      required this.icon,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
              width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(icon,
              color: selected ? Colors.white : color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : WaqtiTheme.textPrimary)),
        ]),
      ),
    );
  }
}

// ─── Etablissement Card ────────────────────────────────────────
class _EtabCard extends StatelessWidget {
  final _EtabWithMeta meta;
  final VoidCallback onTap;
  const _EtabCard({required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = meta.etab;
    final dist = meta.distanceKm;
    final queue = meta.totalQueue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: WaqtiTheme.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(_iconForType(e.type),
                color: WaqtiTheme.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(e.nom,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('${e.adresse.ville} · ${_typeLabel(e.type)}',
                  style: const TextStyle(
                      color: WaqtiTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                    '${e.noteMoyenne.toStringAsFixed(1)} (${e.nombreAvis})',
                    style: const TextStyle(
                        fontSize: 11,
                        color: WaqtiTheme.textSecondary)),
                const SizedBox(width: 10),
                // ── Distance ──
                if (dist != null) ...[
                  const Icon(Icons.near_me,
                      size: 13, color: WaqtiTheme.primary),
                  const SizedBox(width: 3),
                  Text(
                    dist < 1
                        ? '${(dist * 1000).round()} m'
                        : '${dist.toStringAsFixed(1)} km',
                    style: const TextStyle(
                        fontSize: 11,
                        color: WaqtiTheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                ],
                // ── File d'attente ──
                const Icon(Icons.people_outline,
                    size: 13, color: WaqtiTheme.textSecondary),
                const SizedBox(width: 3),
                Text('$queue en attente',
                    style: TextStyle(
                        fontSize: 11,
                        color: queue == 0
                            ? WaqtiTheme.success
                            : queue < 5
                                ? WaqtiTheme.warning
                                : WaqtiTheme.danger,
                        fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right,
              color: WaqtiTheme.textSecondary),
        ]),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'hopital':    return Icons.local_hospital;
      case 'banque':     return Icons.account_balance;
      case 'ambassade':  return Icons.flag;
      case 'mairie':     return Icons.gavel;
      case 'poste':      return Icons.local_post_office;
      case 'telecom':    return Icons.phone_android;
      case 'universite': return Icons.school;
      default:           return Icons.business;
    }
  }

  String _typeLabel(String type) {
    const m = {
      'hopital': 'Hôpital', 'banque': 'Banque',
      'ambassade': 'Ambassade', 'mairie': 'Mairie',
      'poste': 'Poste', 'telecom': 'Télécom',
      'universite': 'Université', 'autre': 'Administration',
    };
    return m[type] ?? type;
  }
}
