import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/model/country.dart';
import '../core/model/pack_meta.dart';

/// Timeout for API requests. Long enough for Render free-tier cold start (~30–60s).
const Duration _requestTimeout = Duration(seconds: 90);

class PackApiClient {
  final http.Client _client;
  final String _baseUrl;

  PackApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'https://buzzoff-api.onrender.com';

  Future<http.Response> _getWithTimeout(Uri uri, {int retries = 1}) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await _client.get(uri).timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Request timed out', _requestTimeout),
        );
        return response;
      } on TimeoutException {
        if (attempt == retries) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw StateError('Unreachable');
  }

  Future<List<Country>> getCountries() async {
    final response = await _getWithTimeout(
      Uri.parse('$_baseUrl/api/v1/countries'),
      retries: 1,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch countries: ${response.statusCode}');
    }
    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => Country.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PackMeta> getPackMeta(String countryCode) async {
    final response = await _getWithTimeout(
      Uri.parse('$_baseUrl/api/v1/packs/$countryCode/meta'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch pack meta: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PackMeta.fromJson(json);
  }

  Future<Uint8List> downloadPack(String countryCode) async {
    final response = await _getWithTimeout(
      Uri.parse('$_baseUrl/api/v1/packs/$countryCode/data'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to download pack: ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
