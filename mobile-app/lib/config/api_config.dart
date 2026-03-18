class ApiConfig {
  // Changez cette URL selon votre environnement
  // Emulateur Android: 10.0.2.2
  // Appareil physique: votre IP locale (ex: 192.168.1.x)
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
    static const String baseUrl = 'http://localhost:5000/api';

  // Pour appareil physique, decommentez et changez l'IP:
  // static const String baseUrl = 'http://192.168.1.XXX:5000/api';

  static const Duration timeout = Duration(seconds: 30);
}
