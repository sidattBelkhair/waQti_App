class ApiConfig {
  // ============================================================
  // CHANGE ICI selon l'environnement :
  // ============================================================

  // ✅ PRODUCTION (Render) — pour partager avec tes amis
  static const String baseUrl = 'https://waqti-app.onrender.com/api';

  // 🖥️  Dev local (émulateur Android)
  // static const String baseUrl = 'http://172.20.10.2:5000/api';

  // 📱 Dev local (appareil physique — remplace par ton IP WiFi)
  // static const String baseUrl = 'http://192.168.1.XXX:5000/api';

  // ============================================================
  static const Duration timeout = Duration(seconds: 30);
}
