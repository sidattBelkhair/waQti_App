class Service {
  final String id, nom, description;
  final int dureeEstimee;
  final bool actif;
  final List<Guichet> guichets;

  Service({required this.id, required this.nom, required this.description, required this.dureeEstimee, required this.actif, required this.guichets});

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['_id'] ?? '', nom: json['nom'] ?? '', description: json['description'] ?? '',
    dureeEstimee: json['dureeEstimee'] ?? 10, actif: json['actif'] ?? true,
    guichets: (json['guichets'] as List?)?.map((g) => Guichet.fromJson(g)).toList() ?? [],
  );
}

class Guichet {
  final int numero;
  final String statut;
  Guichet({required this.numero, required this.statut});
  factory Guichet.fromJson(Map<String, dynamic> json) => Guichet(numero: json['numero'] ?? 0, statut: json['statut'] ?? 'ferme');
}
