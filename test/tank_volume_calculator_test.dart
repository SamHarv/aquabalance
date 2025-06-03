import 'package:flutter_test/flutter_test.dart';
import 'package:aquabalance/logic/tank_volume_calculator.dart';

void main() {
  // Unit tests for TankVolumeCalculator class

  group('Volume Calculation Tests', () {
    final tankVolumeCalculator = TankVolumeCalculator();
    group('calculateRectVolume', () {
      test('calculates volume correctly for standard values', () {
        // 2m x 3m x 4m = 24m³ = 24,000 litres
        expect(
          tankVolumeCalculator.calculateRectVolume(2.0, 3.0, 4.0),
          equals(24000),
        );
      });

      test('calculates volume correctly for decimal values', () {
        // 1.5m x 2.5m x 3.5m = 13.125m³ = 13,125 litres
        expect(
          tankVolumeCalculator.calculateRectVolume(1.5, 2.5, 3.5),
          equals(13125),
        );
      });

      test('returns zero when any dimension is zero', () {
        expect(
          tankVolumeCalculator.calculateRectVolume(0.0, 5.0, 10.0),
          equals(0),
        );
        expect(
          tankVolumeCalculator.calculateRectVolume(5.0, 0.0, 10.0),
          equals(0),
        );
        expect(
          tankVolumeCalculator.calculateRectVolume(5.0, 10.0, 0.0),
          equals(0),
        );
      });

      test('handles very small values', () {
        // 0.1m x 0.1m x 0.1m = 0.001m³ = 1 litre
        expect(
          tankVolumeCalculator.calculateRectVolume(0.1, 0.1, 0.1),
          equals(1),
        );
      });

      test('handles very large values', () {
        // 100m x 100m x 100m = 1,000,000m³ = 1,000,000,000 litres
        expect(
          tankVolumeCalculator.calculateRectVolume(100.0, 100.0, 100.0),
          equals(1000000000),
        );
      });

      test('rounds correctly for fractional litres', () {
        // Testing rounding behavior
        // 0.1m x 0.1m x 0.0501m = 0.000501m³ = 0.501 litres ≈ 1 litre (rounded)
        expect(
          tankVolumeCalculator.calculateRectVolume(0.1, 0.1, 0.0501),
          equals(1),
        );
        // 0.1m x 0.1m x 0.0499m = 0.000499m³ = 0.499 litres ≈ 0 litres (rounded)
        expect(
          tankVolumeCalculator.calculateRectVolume(0.1, 0.1, 0.0499),
          equals(0),
        );
      });
    });

    group('calculateCircVolume', () {
      test('calculates volume correctly for standard values', () {
        // Diameter 2m (radius 1m), height 1m
        // π × 1² × 1 = 3.14m³ = 3,140 litres
        expect(
          tankVolumeCalculator.calculateCircVolume(2.0, 1.0),
          equals(3140),
        );
      });

      test('calculates volume correctly for larger cylinder', () {
        // Diameter 10m (radius 5m), height 4m
        // 3.14 × 5² × 4 = 3.14 × 25 × 4 = 314m³ = 314,000 litres
        expect(
          tankVolumeCalculator.calculateCircVolume(10.0, 4.0),
          equals(314000),
        );
      });

      test('returns zero when diameter is zero', () {
        expect(tankVolumeCalculator.calculateCircVolume(0.0, 10.0), equals(0));
      });

      test('returns zero when height is zero', () {
        expect(tankVolumeCalculator.calculateCircVolume(10.0, 0.0), equals(0));
      });

      test('handles decimal values correctly', () {
        // Diameter 3m (radius 1.5m), height 2m
        // 3.14 × 1.5² × 2 = 3.14 × 2.25 × 2 = 14.13m³ = 14,130 litres
        expect(
          tankVolumeCalculator.calculateCircVolume(3.0, 2.0),
          equals(14130),
        );
      });

      test('handles very small values', () {
        // Diameter 0.2m (radius 0.1m), height 0.1m
        // 3.14 × 0.1² × 0.1 = 0.00314m³ = 3.14 litres ≈ 3 litres (rounded)
        expect(tankVolumeCalculator.calculateCircVolume(0.2, 0.1), equals(3));
      });

      test('handles rounding for fractional litres', () {
        // Testing edge cases for rounding
        // Diameter ≈ 0.8m, height 1m gives volume ≈ 0.5024m³ ≈ 502.4 litres ≈ 502 litres
        expect(tankVolumeCalculator.calculateCircVolume(0.8, 1.0), equals(502));
      });
    });

    group('cubicMToLitres', () {
      test('converts whole numbers correctly', () {
        expect(tankVolumeCalculator.cubicMToLitres(1.0), equals(1000));
        expect(tankVolumeCalculator.cubicMToLitres(5.0), equals(5000));
        expect(tankVolumeCalculator.cubicMToLitres(10.0), equals(10000));
      });

      test('converts decimal values correctly', () {
        expect(tankVolumeCalculator.cubicMToLitres(0.5), equals(500));
        expect(tankVolumeCalculator.cubicMToLitres(1.5), equals(1500));
        expect(tankVolumeCalculator.cubicMToLitres(2.75), equals(2750));
      });

      test('handles zero correctly', () {
        expect(tankVolumeCalculator.cubicMToLitres(0.0), equals(0));
      });

      test('handles very small values', () {
        expect(tankVolumeCalculator.cubicMToLitres(0.001), equals(1));
        expect(
          tankVolumeCalculator.cubicMToLitres(0.0001),
          equals(0),
        ); // Rounds down
      });

      test('handles very large values', () {
        expect(tankVolumeCalculator.cubicMToLitres(1000.0), equals(1000000));
        expect(
          tankVolumeCalculator.cubicMToLitres(1000000.0),
          equals(1000000000),
        );
      });

      test('rounds correctly at boundaries', () {
        // Testing rounding behavior
        expect(
          tankVolumeCalculator.cubicMToLitres(0.0005),
          equals(1),
        ); // 0.5 litres rounds to 1
        expect(
          tankVolumeCalculator.cubicMToLitres(0.0004),
          equals(0),
        ); // 0.4 litres rounds to 0
        expect(
          tankVolumeCalculator.cubicMToLitres(1.4995),
          equals(1500),
        ); // 1499.5 rounds to 1500
        expect(
          tankVolumeCalculator.cubicMToLitres(1.4994),
          equals(1499),
        ); // 1499.4 rounds to 1499
      });
    });

    group('Integration Tests', () {
      test('rectangular volume calculation chain works correctly', () {
        // Verifying the full calculation chain
        final volume = tankVolumeCalculator.calculateRectVolume(2.0, 3.0, 4.0);
        expect(volume, equals(24000));

        // Verify intermediate calculation
        const expectedCubicMeters = 2.0 * 3.0 * 4.0; // 24.0
        expect(
          tankVolumeCalculator.cubicMToLitres(expectedCubicMeters),
          equals(volume),
        );
      });

      test('circular volume calculation chain works correctly', () {
        // Verifying the full calculation chain
        final volume = tankVolumeCalculator.calculateCircVolume(4.0, 5.0);
        expect(volume, equals(62800));

        // Verify intermediate calculation
        const radius = 4.0 / 2; // 2.0
        const expectedCubicMeters = 3.14 * radius * radius * 5.0; // 62.8
        expect(
          tankVolumeCalculator.cubicMToLitres(expectedCubicMeters),
          equals(volume),
        );
      });
    });
  });
}
