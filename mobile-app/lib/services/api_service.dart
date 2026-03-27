import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.timeout,
    receiveTimeout: ApiConfig.timeout,
    headers: {'Content-Type': 'application/json'},
  ));

  Future<void> init() async {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('accessToken');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');
      if (refreshToken == null) return false;
      final res = await Dio().post('${ApiConfig.baseUrl}/auth/refresh-token',
        data: {'refreshToken': refreshToken});
      await prefs.setString('accessToken', res.data['accessToken']);
      return true;
    } catch (_) { return false; }
  }

  Future<Response> register(String nom, String tel, String mdp, String role) =>
    _dio.post('/auth/register', data: {'nom': nom, 'telephone': tel, 'motDePasse': mdp, 'role': role});
  Future<Response> getMyEtablissement() => _dio.get('/auth/my-etablissement');
  Future<Response> getMesTickets() => _dio.get('/tickets/mes-tickets');
  Future<Response> login(String identifier, String mdp) =>
    _dio.post('/auth/login', data: {'identifier': identifier, 'motDePasse': mdp});
  Future<Response> verifyOTP(String userId, String code) =>
    _dio.post('/auth/verify-otp', data: {'userId': userId, 'code': code});
  Future<Response> getProfile() => _dio.get('/auth/profile');
  Future<Response> updateProfile(Map<String, dynamic> data) => _dio.put('/auth/profile', data: data);
  Future<Response> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final rt = prefs.getString('refreshToken');
    return _dio.post('/auth/logout', data: {'refreshToken': rt});
  }
  Future<Response> forgotPassword(String tel) =>
    _dio.post('/auth/forgot-password', data: {'telephone': tel});
  Future<Response> resetPassword(String token, String newPassword) =>
    _dio.post('/auth/reset-password', data: {'token': token, 'newPassword': newPassword});
  Future<Response> registerEtablissement(Map<String, dynamic> data) =>
    _dio.post('/auth/register-etablissement', data: data);
  Future<Response> searchEtablissements({String? nom, String? type, String? ville, double? lat, double? lng}) =>
    _dio.get('/etablissements', queryParameters: {
      'nom': nom, 'type': type, 'ville': ville,
      'lat': lat?.toString(), 'lng': lng?.toString(),
    }..removeWhere((k, v) => v == null));
  Future<Response> getEtablissement(String id) => _dio.get('/etablissements/$id');
  Future<Response> getServices(String etabId) => _dio.get('/etablissements/$etabId/services');
  Future<Response> getPersonnel(String etabId) => _dio.get('/etablissements/$etabId/personnel');
  Future<Response> getAvis(String etabId) => _dio.get('/etablissements/$etabId/avis');
  Future<Response> postAvis(String etabId, int note, String commentaire, String ticketId) =>
    _dio.post('/etablissements/$etabId/avis', data: {'note': note, 'commentaire': commentaire, 'ticketId': ticketId});
  Future<Response> createTicket(String etabId, String serviceId, String mode, int priorite) =>
    _dio.post('/tickets', data: {'etablissementId': etabId, 'serviceId': serviceId, 'mode': mode, 'priorite': priorite});
  Future<Response> createTicketRDV(String etabId, String serviceId, String date, String creneau) =>
    _dio.post('/tickets/rdv', data: {'etablissementId': etabId, 'serviceId': serviceId, 'date': date, 'creneau': creneau});
  Future<Response> cancelTicket(String id) => _dio.delete('/tickets/$id/annuler');
  Future<Response> signalRetard(String id) => _dio.post('/tickets/$id/signaler-retard');
  Future<Response> validerPresence(String id) => _dio.post('/tickets/$id/valider-presence');
  Future<Response> validerPresenceByNumero(String numero) => _dio.post('/tickets/scan/$numero/valider');
  Future<Response> getFileStatus(String serviceId) => _dio.get('/files/$serviceId');
  Future<Response> getPosition(String serviceId) => _dio.get('/files/$serviceId/position');
  Future<Response> appelSuivant(String serviceId, int guichet) =>
    _dio.post('/files/$serviceId/appeler-suivant', data: {'guichet': guichet});
  Future<Response> marquerAbsent(String serviceId) =>
    _dio.post('/files/$serviceId/absent');
  Future<Response> createService(String etabId, Map<String, dynamic> data) =>
    _dio.post('/etablissements/$etabId/services', data: data);
  Future<Response> deleteService(String etabId, String serviceId) =>
    _dio.delete('/etablissements/$etabId/services/$serviceId');
  Future<Response> getEtablissementTickets() => _dio.get('/tickets/etablissement');
  Future<Response> updateEtablissement(String id, Map<String, dynamic> data) =>
    _dio.put('/etablissements/$id', data: data);
  Future<Response> deleteEtablissement(String id) =>
    _dio.delete('/etablissements/$id');

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', access);
    await prefs.setString('refreshToken', refresh);
  }
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
}