import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class MakkaApiException implements Exception {
  final int statusCode;
  final String message;
  MakkaApiException(this.statusCode, this.message);
  @override
  String toString() => 'HTTP $statusCode: $message';
}

/// Shared REST client used by customer, admin and courier experiences.
/// Store the returned token securely in production (e.g. flutter_secure_storage).
class MakkaApi {
  String? _token;
  Map<String, dynamic>? currentUser;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}/$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  dynamic _decode(http.Response response) {
    dynamic body;
    try { body = response.body.isEmpty ? null : jsonDecode(response.body); }
    catch (_) { body = response.body; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map ? (body['message'] ?? 'حدث خطأ في الاتصال') : 'حدث خطأ في الاتصال';
      throw MakkaApiException(response.statusCode, message.toString());
    }
    return body;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await http.post(_uri('login'), headers: _headers,
      body: jsonEncode({'email': email, 'password': password}));
    final data = Map<String, dynamic>.from(_decode(r) as Map);
    _token = data['token']?.toString();
    currentUser = Map<String, dynamic>.from(data['user'] as Map);
    return currentUser!;
  }

  Future<void> logout() async {
    if (_token != null) {
      final r = await http.post(_uri('logout'), headers: _headers);
      _decode(r);
    }
    _token = null;
    currentUser = null;
  }

  Future<List<Map<String, dynamic>>> products({String? search, String? category}) async {
    final q = <String, String>{};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (category != null && category.isNotEmpty) q['category'] = category;
    final r = await http.get(_uri('products', q.isEmpty ? null : q), headers: _headers);
    final data = _decode(r);
    final rows = data is Map && data['data'] is List ? data['data'] as List : data as List;
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createOrder({required String address,
      String? notes, required List<Map<String, int>> items}) async {
    final r = await http.post(_uri('orders'), headers: _headers,
      body: jsonEncode({'address': address, 'notes': notes, 'items': items}));
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  Future<List<Map<String, dynamic>>> myOrders() async => _paginated('orders/my');
  Future<List<Map<String, dynamic>>> adminOrders() async => _paginated('admin/orders');
  Future<List<Map<String, dynamic>>> courierOrders() async => _paginated('courier/orders');
  Future<List<Map<String, dynamic>>> couriers() async {
    final r = await http.get(_uri('admin/couriers'), headers: _headers);
    final data = _decode(r) as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> _paginated(String path) async {
    final r = await http.get(_uri(path), headers: _headers);
    final data = _decode(r) as Map;
    return (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> assignOrder(int orderId, int courierId) async {
    final r = await http.post(_uri('admin/orders/$orderId/assign'), headers: _headers,
      body: jsonEncode({'courier_id': courierId}));
    return Map<String, dynamic>.from(_decode(r) as Map);
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final r = await http.patch(_uri('courier/orders/$orderId/status'), headers: _headers,
      body: jsonEncode({'status': status}));
    return Map<String, dynamic>.from(_decode(r) as Map);
  }
}
