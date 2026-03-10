import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:buzzoff/services/pack_api_client.dart';

void main() {
  group('PackApiClient', () {
    test('getCountries parses country list from API', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/countries');
        return http.Response(
          jsonEncode([
            {
              'code': 'IL',
              'name': 'Israel',
              'name_local': null,
              'speed_unit': 'kmh',
              'pack_version': 3,
              'camera_count': 147,
            },
            {
              'code': 'DE',
              'name': 'Germany',
              'name_local': 'Deutschland',
              'speed_unit': 'kmh',
              'pack_version': 1,
              'camera_count': 2341,
            },
          ]),
          200,
        );
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      final countries = await client.getCountries();

      expect(countries.length, 2);
      expect(countries[0].code, 'IL');
      expect(countries[0].name, 'Israel');
      expect(countries[0].packVersion, 3);
      expect(countries[0].cameraCount, 147);
      expect(countries[1].code, 'DE');
      expect(countries[1].nameLocal, 'Deutschland');
    });

    test('getPackMeta parses metadata from API', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/packs/IL/meta');
        return http.Response(
          jsonEncode({
            'country_code': 'IL',
            'version': 3,
            'camera_count': 147,
            'file_size_bytes': 48128,
            'checksum_sha256': 'abc123def456',
          }),
          200,
        );
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      final meta = await client.getPackMeta('IL');

      expect(meta.countryCode, 'IL');
      expect(meta.version, 3);
      expect(meta.cameraCount, 147);
      expect(meta.fileSizeBytes, 48128);
      expect(meta.checksumSha256, 'abc123def456');
    });

    test('downloadPack returns bytes from API', () async {
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/packs/IL/data');
        return http.Response.bytes(testBytes, 200);
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      final bytes = await client.downloadPack('IL');

      expect(bytes, testBytes);
    });

    test('getCountries throws on non-200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      expect(() => client.getCountries(), throwsException);
    });

    test('getPackMeta throws on non-200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      expect(() => client.getPackMeta('IL'), throwsException);
    });

    test('downloadPack throws on non-200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final client = PackApiClient(client: mockClient, baseUrl: 'http://test');
      expect(() => client.downloadPack('IL'), throwsException);
    });
  });
}
