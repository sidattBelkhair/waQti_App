class Ticket {
  final String id, numero, mode, statut;
  final String? etablissementNom, serviceNom;
  final int position, tempsEstime, priorite;
  final bool retardSignale;
  final DateTime createdAt;

  Ticket({required this.id, required this.numero, required this.mode, required this.statut,
    this.etablissementNom, this.serviceNom, required this.position, required this.tempsEstime,
    required this.priorite, required this.retardSignale, required this.createdAt});

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['_id'] ?? '', numero: json['numero'] ?? '',
    mode: json['mode'] ?? 'distance', statut: json['statut'] ?? 'en_attente',
    etablissementNom: json['etablissement'] is Map ? json['etablissement']['nom'] : null,
    serviceNom: json['service'] is Map ? json['service']['nom'] : null,
    position: json['position'] ?? 0, tempsEstime: json['tempsEstime'] ?? 0,
    priorite: json['priorite'] ?? 4, retardSignale: json['retardSignale'] ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}
