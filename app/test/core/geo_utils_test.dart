import 'package:flutter_test/flutter_test.dart';
import 'package:buzzoff/core/geo/geo_utils.dart';

void main() {
  group('haversine', () {
    test('returns 0 for same point', () {
      final d = GeoUtils.haversine(32.0, 34.0, 32.0, 34.0);
      expect(d, 0.0);
    });

    test('calculates known distance Tel Aviv to Jerusalem (~54km)', () {
      // Tel Aviv: 32.0853, 34.7818
      // Jerusalem: 31.7683, 35.2137
      final d = GeoUtils.haversine(32.0853, 34.7818, 31.7683, 35.2137);
      expect(d, closeTo(54000, 2000)); // ~54km ± 2km
    });

    test('calculates short distance (~100m)', () {
      // ~100m apart at lat 32
      final d = GeoUtils.haversine(32.0, 34.0, 32.0009, 34.0);
      expect(d, closeTo(100, 10));
    });

    test('is symmetric', () {
      final d1 = GeoUtils.haversine(32.0, 34.0, 32.1, 34.1);
      final d2 = GeoUtils.haversine(32.1, 34.1, 32.0, 34.0);
      expect(d1, closeTo(d2, 0.01));
    });
  });

  group('bearing', () {
    test('due north returns ~0', () {
      final b = GeoUtils.bearing(32.0, 34.0, 33.0, 34.0);
      expect(b, closeTo(0, 1));
    });

    test('due east returns ~90', () {
      final b = GeoUtils.bearing(32.0, 34.0, 32.0, 35.0);
      expect(b, closeTo(90, 2));
    });

    test('due south returns ~180', () {
      final b = GeoUtils.bearing(32.0, 34.0, 31.0, 34.0);
      expect(b, closeTo(180, 1));
    });

    test('due west returns ~270', () {
      final b = GeoUtils.bearing(32.0, 34.0, 32.0, 33.0);
      expect(b, closeTo(270, 2));
    });

    test('returns value between 0 and 360', () {
      final b = GeoUtils.bearing(32.0, 34.0, 31.5, 33.5);
      expect(b, greaterThanOrEqualTo(0));
      expect(b, lessThan(360));
    });
  });

  group('angleDiff', () {
    test('same heading returns 0', () {
      expect(GeoUtils.angleDiff(90, 90), 0);
    });

    test('opposite headings return 180', () {
      expect(GeoUtils.angleDiff(0, 180), 180);
    });

    test('handles wrap-around', () {
      expect(GeoUtils.angleDiff(350, 10), 20);
      expect(GeoUtils.angleDiff(10, 350), 20);
    });
  });

  group('isSameLane', () {
    test('null camera heading returns true (safe default)', () {
      expect(GeoUtils.isSameLane(90, null, 90), isTrue);
    });

    test('same direction is same lane', () {
      expect(GeoUtils.isSameLane(180, 180, 90), isTrue);
    });

    test('similar direction within tolerance is same lane', () {
      expect(GeoUtils.isSameLane(170, 200, 90), isTrue);
    });

    test('opposite direction is not same lane', () {
      expect(GeoUtils.isSameLane(0, 180, 90), isFalse);
    });

    test('opposite direction with wrap-around is not same lane', () {
      expect(GeoUtils.isSameLane(10, 200, 90), isFalse);
    });

    test('perpendicular direction at boundary', () {
      // 90° diff is exactly at the boundary → same lane
      expect(GeoUtils.isSameLane(0, 90, 90), isTrue);
      // 91° diff is just past → not same lane
      expect(GeoUtils.isSameLane(0, 91, 90), isFalse);
    });
  });

  group('isAhead', () {
    test('camera directly ahead is detected', () {
      expect(GeoUtils.isAhead(0, 0, 45), isTrue);
    });

    test('camera slightly to the right is detected', () {
      expect(GeoUtils.isAhead(90, 110, 45), isTrue);
    });

    test('camera behind is not detected', () {
      expect(GeoUtils.isAhead(0, 180, 45), isFalse);
    });

    test('camera at exact tolerance boundary is detected', () {
      expect(GeoUtils.isAhead(0, 45, 45), isTrue);
    });

    test('camera just beyond tolerance is not detected', () {
      expect(GeoUtils.isAhead(0, 46, 45), isFalse);
    });

    test('handles wrap-around at 360/0 boundary', () {
      // heading 350, camera bearing 10 → difference is 20
      expect(GeoUtils.isAhead(350, 10, 45), isTrue);
    });

    test('handles wrap-around the other direction', () {
      // heading 10, camera bearing 350 → difference is 20
      expect(GeoUtils.isAhead(10, 350, 45), isTrue);
    });
  });
}
