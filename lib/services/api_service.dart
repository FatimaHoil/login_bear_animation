import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8081';

  static String? _token;

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  // Iniciar sesión en Spring Boot y guardar el JWT
  static Future<void> login(String email, String password) async {
    try {
      print('API: intentando conectar con Spring Boot');

      final url = Uri.parse('$baseUrl/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      print('API: respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! Map || data['accessToken'] == null) {
          throw Exception('No se recibió accessToken');
        }

        _token = data['accessToken'].toString();

        print('API: token recibido correctamente');
        print('API: ¿Hay token?: $hasToken');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _token = null;
      print('API LOGIN ERROR: $e');
      rethrow;
    }
  }

  // Obtener productos utilizando el JWT
  static Future<List<dynamic>> getProducts() async {
    print('PRODUCTOS: comprobando token');
    print('PRODUCTOS: ¿Hay token?: $hasToken');

    if (!hasToken) {
      throw Exception('No hay un token de acceso');
    }

    final url = Uri.parse('$baseUrl/products');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    print('PRODUCTOS: respuesta del servidor: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        print('PRODUCTOS: ${data.length} productos recibidos');
        return data;
      }

      throw Exception('La respuesta no contiene una lista de productos');
    }

    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // Cerrar sesión y eliminar el token
  static void logout() {
    print('API: cerrando sesión y eliminando token');
    _token = null;
  }
}
