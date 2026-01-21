import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _syncApiUrlKey = 'sync_api_url';

  Future<String?> get _baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncApiUrlKey);
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncApiUrlKey, url);
  }

  Future<http.Response> post(String path, dynamic body) async {
    final baseUrl = await _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API Base URL not configured');
    }

    final url = Uri.parse('$baseUrl$path');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? queryParameters}) async {
    final baseUrl = await _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API Base URL not configured');
    }

    final url = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    return await http.get(url, headers: {'Content-Type': 'application/json'});
  }
}
