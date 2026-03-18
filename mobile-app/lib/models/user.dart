class User {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final String role;
  final String statut;
  final String? photo;
  final String? nni;

  User({required this.id, required this.nom, required this.email, required this.telephone, required this.role, required this.statut, this.photo, this.nni});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'] ?? '', nom: json['nom'] ?? '', email: json['email'] ?? '',
    telephone: json['telephone'] ?? '', role: json['role'] ?? 'client',
    statut: json['statut'] ?? '', photo: json['photo'], nni: json['nni'],
  );
}
