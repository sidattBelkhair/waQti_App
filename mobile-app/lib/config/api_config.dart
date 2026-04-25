class ApiConfig {
  // ============================================================
  // DÉCOMMENTE la ligne selon où tu testes :
  // ============================================================

  // 💻 Linux desktop (flutter run sans téléphone)
  static const String baseUrl = 'http://localhost:5000/api';

  // 📱 Téléphone Android sur même WiFi
  // static const String baseUrl = 'http://192.168.3.78:5000/api';

  // ✅ Production Render (pour APK final)
  // static const String baseUrl = 'https://waqti-app.onrender.com/api';

  // ============================================================
  static const Duration timeout = Duration(seconds: 90);
}
