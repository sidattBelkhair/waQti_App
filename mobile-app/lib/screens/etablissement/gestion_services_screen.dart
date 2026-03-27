import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/service.dart';
import '../../config/theme.dart';

class GestionServicesScreen extends StatefulWidget {
  final String etabId;
  final String etabNom;
  const GestionServicesScreen({super.key, required this.etabId, required this.etabNom});
  @override State<GestionServicesScreen> createState() => _State();
}

class _State extends State<GestionServicesScreen> {
  List<Service> _services = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getServices(widget.etabId);
      setState(() {
        _services = (res.data['services'] as List)
            .map((s) => Service.fromJson(s))
            .toList();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _createService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateServiceDialog(),
    );
    if (result == null) return;
    try {
      await ApiService().createService(widget.etabId, result);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Service "${result['nom']}" cree'),
            backgroundColor: WaqtiTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le service ?'),
        content: Text('Supprimer "${service.nom}" ? Cette action est irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: WaqtiTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().deleteService(widget.etabId, service.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Service "${service.nom}" supprime'),
            backgroundColor: WaqtiTheme.warning));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'), backgroundColor: WaqtiTheme.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Services'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createService,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau service'),
        backgroundColor: WaqtiTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _services.length,
                    itemBuilder: (_, i) => _ServiceCard(
                      service: _services[i],
                      onDelete: () => _deleteService(_services[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.layers_outlined, size: 80, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('Aucun service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Creez vos services pour que les clients puissent prendre des tickets.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WaqtiTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createService,
            icon: const Icon(Icons.add),
            label: const Text('Creer mon premier service'),
          ),
        ]),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onDelete;
  const _ServiceCard({required this.service, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: WaqtiTheme.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.layers, color: WaqtiTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.nom,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (service.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(service.description,
                    style: const TextStyle(color: WaqtiTheme.textSecondary, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 14, color: WaqtiTheme.textSecondary),
                const SizedBox(width: 4),
                Text('Duree estimee : ${service.dureeEstimee} min',
                    style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
              ]),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: WaqtiTheme.danger),
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog();
  @override State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  double _duree = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau service'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
                labelText: 'Nom du service *',
                hintText: 'ex: Caisse, Depot, Renseignements...',
                prefixIcon: Icon(Icons.label_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: Icon(Icons.notes)),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Duree estimee par client',
                style: TextStyle(fontSize: 13, color: WaqtiTheme.textSecondary)),
            Text('${_duree.toInt()} min',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: WaqtiTheme.primary, fontSize: 15)),
          ]),
          Slider(
            value: _duree,
            min: 2, max: 60,
            divisions: 29,
            activeColor: WaqtiTheme.primary,
            onChanged: (v) => setState(() => _duree = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_nomCtrl.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'nom': _nomCtrl.text.trim(),
              'description': _descCtrl.text.trim(),
              'dureeEstimee': _duree.toInt(),
            });
          },
          child: const Text('Creer'),
        ),
      ],
    );
  }
}
