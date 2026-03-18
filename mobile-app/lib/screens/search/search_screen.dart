import 'package:flutter/material.dart';
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
  List<Etablissement> _results = [];
  bool _loading = false;
  String _selectedType = '';

  final _types = ['', 'hopital', 'banque', 'ambassade', 'mairie', 'poste', 'telecom'];
  final _typeLabels = {'': 'Tous', 'hopital': 'Hopital', 'banque': 'Banque', 'ambassade': 'Ambassade', 'mairie': 'Mairie', 'poste': 'Poste', 'telecom': 'Telecom'};

  @override
  void initState() { super.initState(); _search(); }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().searchEtablissements(
        nom: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
        type: _selectedType.isNotEmpty ? _selectedType : null,
      );
      _results = (res.data['etablissements'] as List).map((e) => Etablissement.fromJson(e)).toList();
    } catch (e) { debugPrint('Erreur recherche: $e'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WaQti'), actions: [
        IconButton(icon: const Icon(Icons.map_outlined), onPressed: () {}),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(controller: _searchCtrl,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Rechercher un etablissement...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.tune), onPressed: _search),
            )),
        ),
        SizedBox(height: 40,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _types.map((t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_typeLabels[t] ?? t),
                selected: _selectedType == t,
                onSelected: (_) { setState(() => _selectedType = t); _search(); },
                selectedColor: WaqtiTheme.primary, labelStyle: TextStyle(color: _selectedType == t ? Colors.white : null),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
              ? const Center(child: Text('Aucun etablissement trouve', style: TextStyle(color: WaqtiTheme.textSecondary)))
              : ListView.builder(
                  itemCount: _results.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final e = _results[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(backgroundColor: WaqtiTheme.primaryLight,
                          child: Icon(_getIcon(e.type), color: WaqtiTheme.primary)),
                        title: Text(e.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text('${e.type} • ${e.adresse.ville}', style: const TextStyle(color: WaqtiTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(' ${e.noteMoyenne}/5 (${e.nombreAvis} avis)'),
                          ]),
                        ]),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EtablissementDetailScreen(etabId: e.id))),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'hopital': return Icons.local_hospital;
      case 'banque': return Icons.account_balance;
      case 'ambassade': return Icons.flag;
      case 'mairie': return Icons.location_city;
      case 'poste': return Icons.mail;
      case 'telecom': return Icons.phone_android;
      default: return Icons.business;
    }
  }
}
