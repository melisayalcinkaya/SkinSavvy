import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../local/local_store.dart';

/// Sunucu adresi. Verilmezse uygulama cihaz modunda çalışır:
/// `flutter run --dart-define=API_URL=https://skinsavvy-api.onrender.com`
const apiUrl = String.fromEnvironment('API_URL');

class ApiException implements Exception {
  const ApiException(this.status, this.message);

  /// HTTP durum kodu; bağlantı hatasında 0.
  final int status;
  final String message;

  @override
  String toString() => message;
}

/// SkinSavvy API'si için ince bir istemci.
///
/// Erişim token'ı yalnızca bellekte tutulur (15 dk). Refresh token cihazda
/// saklanır; erişim token'ı reddedilince bir kez yenilenip istek tekrarlanır.
/// Aynı anda birden fazla istek 401 alırsa yalnızca bir yenileme yapılır.
class ApiClient {
  ApiClient(this.baseUrl, this._store, {http.Client? client})
    : _http = client ?? http.Client();

  final String baseUrl;
  final LocalStore _store;
  final http.Client _http;

  static const refreshKey = 'api.refreshToken';
  static const timeout = Duration(seconds: 20);

  String? _access;
  Future<bool>? _refreshing;

  String? get refreshToken => _store.read(refreshKey) as String?;
  bool get hasSession => refreshToken != null;

  /// Giriş/kayıt yanıtındaki token'ları saklar ve kullanıcıyı döner.
  Future<Map<String, dynamic>> acceptTokens(Map<String, dynamic> tokens) async {
    _access = tokens['accessToken'] as String?;
    await _store.write(refreshKey, tokens['refreshToken']);
    return Map<String, dynamic>.from(tokens['user'] as Map);
  }

  Future<void> clearSession() async {
    _access = null;
    await _store.remove(refreshKey);
  }

  /// Refresh token ile yeni token çifti alır; başarısızsa oturumu temizler.
  Future<bool> refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final token = refreshToken;
    if (token == null) return false;
    try {
      final data = await send(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': token},
        auth: false,
      );
      await acceptTokens(Map<String, dynamic>.from(data as Map));
      return true;
    } on ApiException catch (e) {
      // Ağ hatasında oturumu silme; yalnızca sunucu reddettiyse.
      if (e.status == 401) await clearSession();
      return false;
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) =>
      send('POST', path, body: body);
  Future<dynamic> put(String path, [Object? body]) =>
      send('PUT', path, body: body);
  Future<dynamic> patch(String path, [Object? body]) =>
      send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => send('DELETE', path);

  Future<dynamic> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    var response = await _once(method, path, body, query, auth);
    if (response.statusCode == 401 && auth && hasSession) {
      if (await refresh()) {
        response = await _once(method, path, body, query, auth);
      }
    }
    final text = utf8.decode(response.bodyBytes);
    final data = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _message(data));
    }
    return data;
  }

  Future<http.Response> _once(
    String method,
    String path,
    Object? body,
    Map<String, String>? query,
    bool auth,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    if (auth && _access != null) {
      request.headers['Authorization'] = 'Bearer $_access';
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        0,
        'Sunucu yanıt vermedi. Ücretsiz sunucu uykudaysa ilk istek bir dakika '
        'kadar sürebilir; biraz sonra tekrar deneyin.',
      );
    } on Exception {
      throw const ApiException(
        0,
        'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  /// FastAPI hata gövdesinden kullanıcıya gösterilecek mesaj.
  static String _message(Object? data) {
    final detail = data is Map ? data['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final msg = (detail.first as Map)['msg'];
      if (msg is String) return msg.replaceFirst('Value error, ', '');
    }
    return 'Beklenmeyen bir hata oluştu.';
  }
}
