import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/pulsing_dot.dart';
import '../etablissement/qr_scanner_screen.dart';
import 'gestionnaire_display_screen.dart';

class GestionnaireFileScreen extends StatefulWidget {
  const GestionnaireFileScreen({super.key});
  @override State<GestionnaireFileScreen> createState() => _State();
}

class _State extends State<GestionnaireFileScreen> {
  Map<String, dynamic>? _etab;
  List<Map<String, dynamic>> _services = [];
  String? _selectedServiceId;
  Map<String, dynamic>? _fileData;
  bool _loading = true;
  bool _actionLoading = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (_selectedServiceId != null) SocketService().leaveService(_selectedServiceId!);
    super.dispose();
  }

  Map<String, dynamic>? get _selectedService => _services
      .cast<Map<String, dynamic>?>()
      .firstWhere((s) => s?['_id'] == _selectedServiceId, orElse: () => null);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final etabRes = await ApiService().getMyEtablissement();
      _etab = etabRes.data['etablissement'] as Map<String, dynamic>?;
      if (_etab == null || _etab!['statut'] != 'actif') {
        setState(() => _loading = false);
        return;
      }
      final svcRes = await ApiService().getServices(_etab!['_id'] as String);
      _services = List<Map<String, dynamic>>.from(svcRes.data['services'] ?? []);
      if (_services.isNotEmpty) {
        _selectedServiceId ??= _services.first['_id'] as String;
        SocketService().joinService(_selectedServiceId!);
        SocketService().onFileUpdated = (_) => _loadFileStatus();
        await _loadFileStatus();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadFileStatus() async {
    if (_selectedServiceId == null) return;
    try {
      final res = await ApiService().getFileStatus(_selectedServiceId!);
      if (mounted) setState(() => _fileData = res.data['file'] as Map<String, dynamic>?);
    } catch (_) {}
  }

  void _selectService(String id) {
    if (id == _selectedServiceId) return;
    if (_selectedServiceId != null) SocketService().leaveService(_selectedServiceId!);
    setState(() {
      _selectedServiceId = id;
      _fileData = null;
    });
    SocketService().joinService(id);
    _loadFileStatus();
  }

  Future<void> _callNext() async {
    if (_selectedServiceId == null || _paused) return;
    setState(() => _actionLoading = true);
    try {
      final res = await ApiService().appelSuivant(_selectedServiceId!, 1);
      HapticFeedback.mediumImpact();
      final numero = res.data['client']?['numero'] ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$numero ${context.tr('g_called_snackbar')}'),
            backgroundColor: WaqtiTheme.success));
      }
      await _loadFileStatus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('g_queue_empty')),
            backgroundColor: WaqtiTheme.warning));
      }
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  Future<void> _markAbsent() async {
    if (_selectedServiceId == null) return;
    try {
      await ApiService().marquerAbsent(_selectedServiceId!);
      HapticFeedback.lightImpact();
    } catch (_) {}
    await _callNext();
  }

  void _togglePause() => setState(() => _paused = !_paused);

  void _openDisplay() {
    if (_selectedServiceId == null) return;
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => GestionnaireDisplayScreen(
        serviceId: _selectedServiceId!,
        etabNom: _etab?['nom'] ?? '',
      ),
    ));
  }

  void _openScanner() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()))
        .then((_) => _loadFileStatus());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_etab == null || _etab!['statut'] != 'actif') {
      return Scaffold(
        backgroundColor: WaqtiTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_etab == null ? Icons.business_outlined : Icons.hourglass_bottom,
                  size: 64, color: WaqtiTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                  _etab == null
                      ? context.tr('g_no_etab')
                      : context.tr('g_pending_validation'),
                  style: const TextStyle(fontSize: 16, color: WaqtiTheme.textSecondary),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }

    final ticketEnCours = _fileData?['ticketEnCours'];
    final ticketEnCoursMap = ticketEnCours is Map ? Map<String, dynamic>.from(ticketEnCours) : null;
    final tickets = (_fileData?['tickets'] as List?)
            ?.map((t) => Map<String, dynamic>.from(t as Map))
            .toList() ??
        [];
    tickets.sort((a, b) {
      final pa = a['priorite'] as int? ?? 4;
      final pb = b['priorite'] as int? ?? 4;
      if (pa != pb) return pa.compareTo(pb);
      final ca = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final cb = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return ca.compareTo(cb);
    });

    return Scaffold(
      backgroundColor: WaqtiTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadFileStatus,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(delegate: SliverChildListDelegate([
              if (_services.length > 1) _buildServiceChips(),
              _CurrentTicketCard(
                numero: ticketEnCoursMap?['numero'] as String?,
                serviceNom: _selectedService?['nom'] as String? ?? '',
              ),
              const SizedBox(height: 14),
              _buildCallNextButton(),
              const SizedBox(height: 10),
              _buildSecondaryActions(ticketEnCoursMap != null),
              const SizedBox(height: 24),
              Text(context.tr('g_next_tickets'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (tickets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(context.tr('g_no_tickets_waiting'),
                        style: const TextStyle(color: WaqtiTheme.textSecondary)),
                  ),
                )
              else
                ...tickets.map((t) => _NextTicketCard(ticket: t)),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 50, 12, 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_etab?['nom'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const PulsingDot(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    '${context.tr('g_guichet')} 1 · ${_selectedService?['nom'] ?? ''} · ${context.tr('g_live')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          onPressed: _openScanner,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadFileStatus,
        ),
      ]),
    );
  }

  Widget _buildServiceChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _services.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = _services[i];
            final selected = s['_id'] == _selectedServiceId;
            return GestureDetector(
              onTap: () => _selectService(s['_id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? WaqtiTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? WaqtiTheme.primary : WaqtiTheme.border),
                ),
                child: Center(
                  child: Text(s['nom'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : WaqtiTheme.textSecondary)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCallNextButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _paused ? null : WaqtiTheme.primaryGradient,
          color: _paused ? WaqtiTheme.border : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 20)),
          onPressed: (_actionLoading || _paused) ? null : _callNext,
          child: _actionLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr('g_call_next'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _paused ? WaqtiTheme.textSecondary : Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(bool hasEnCours) {
    return Row(children: [
      Expanded(
        child: _SecondaryButton(
          icon: Icons.person_off_outlined,
          label: context.tr('g_absent'),
          onTap: hasEnCours ? _markAbsent : null,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _SecondaryButton(
          icon: _paused ? Icons.play_arrow : Icons.pause,
          label: _paused ? context.tr('g_resume') : context.tr('g_pause'),
          active: _paused,
          onTap: _togglePause,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _SecondaryButton(
          icon: Icons.tv_outlined,
          label: context.tr('g_screen_room'),
          onTap: _openDisplay,
        ),
      ),
    ]);
  }
}

class _CurrentTicketCard extends StatelessWidget {
  final String? numero;
  final String serviceNom;
  const _CurrentTicketCard({required this.numero, required this.serviceNom});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: WaqtiTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        Text(context.tr('g_current_ticket').toUpperCase(),
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Text(numero ?? '—',
            style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.bold, height: 1.0)),
        const SizedBox(height: 8),
        Text(numero == null ? context.tr('g_no_ticket_current') : serviceNom,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _SecondaryButton({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: active ? WaqtiTheme.warning : WaqtiTheme.border, width: active ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, size: 20,
              color: disabled ? WaqtiTheme.border : (active ? WaqtiTheme.warning : WaqtiTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled ? WaqtiTheme.border : (active ? WaqtiTheme.warning : WaqtiTheme.textSecondary))),
        ]),
      ),
    );
  }
}

class _NextTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _NextTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final numero = ticket['numero'] as String? ?? '';
    final priorite = ticket['priorite'] as int? ?? 4;
    final createdAt = DateTime.tryParse(ticket['createdAt'] ?? '');
    final heure = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaqtiTheme.border),
      ),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Text(numero, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WaqtiTheme.navy)),
            if (priorite != 4) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                child: Text(context.tr('g_priority_badge'),
                    style: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.bold, color: WaqtiTheme.warning)),
              ),
            ],
          ]),
        ),
        Text(heure, style: const TextStyle(fontSize: 12, color: WaqtiTheme.textSecondary)),
      ]),
    );
  }
}
