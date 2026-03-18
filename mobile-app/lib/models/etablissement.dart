class Etablissement {
  final String id, nom, type, description, telephone, statut;
  final String? email, photo;
  final Adresse adresse;
  final double noteMoyenne;
  final int nombreAvis;
  final Map<String, Horaire> horaires;

  Etablissement({required this.id, required this.nom, required this.type, required this.description,
    required this.telephone, required this.statut, this.email, this.photo,
    required this.adresse, required this.noteMoyenne, required this.nombreAvis, required this.horaires});

  factory Etablissement.fromJson(Map<String, dynamic> json) {
    Map<String, Horaire> h = {};
    if (json['horaires'] != null) {
      (json['horaires'] as Map<String, dynamic>).forEach((k, v) {
        h[k] = Horaire.fromJson(v);
      });
    }
    return Etablissement(
      id: json['_id'] ?? '', nom: json['nom'] ?? '', type: json['type'] ?? '',
      description: json['description'] ?? '', telephone: json['telephone'] ?? '',
      statut: json['statut'] ?? '', email: json['email'], photo: json['photo'],
      adresse: Adresse.fromJson(json['adresse'] ?? {}),
      noteMoyenne: (json['noteMoyenne'] ?? 0).toDouble(),
      nombreAvis: json['nombreAvis'] ?? 0, horaires: h,
    );
  }
}

class Adresse {
  final String rue, ville;
  final double lat, lng;
  Adresse({required this.rue, required this.ville, required this.lat, required this.lng});
  factory Adresse.fromJson(Map<String, dynamic> json) {
    final coords = json['coordonnees']?['coordinates'] ?? [0, 0];
    return Adresse(rue: json['rue'] ?? '', ville: json['ville'] ?? '', lng: (coords[0] ?? 0).toDouble(), lat: (coords[1] ?? 0).toDouble());
  }
}

class Horaire {
  final bool ouvert;
  final String? debut, fin;
  Horaire({required this.ouvert, this.debut, this.fin});
  factory Horaire.fromJson(Map<String, dynamic> json) => Horaire(ouvert: json['ouvert'] ?? false, debut: json['debut'], fin: json['fin']);
}
