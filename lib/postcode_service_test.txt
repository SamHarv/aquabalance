import 'package:flutter_test/flutter_test.dart';
import 'package:water_tank_insights/logic/services/postcode_service.dart';

void main() {
  group('PostcodesService', () {
    group('length property', () {
      test('should return the correct number of available postcodes', () {
        // Act
        final length = PostcodesService.length;

        // Assert
        expect(length, equals(178));
        expect(length, greaterThan(0));
      });
    });

    group('getAvailablePostcodes', () {
      test('should return all postcodes as strings', () {
        // Act
        final postcodes = PostcodesService.getAvailablePostcodes();

        // Assert
        expect(postcodes, isA<List<String>>());
        expect(postcodes.length, equals(PostcodesService.length));
        expect(postcodes.isNotEmpty, isTrue);
      });

      test('should return postcodes in string format', () {
        // Act
        final postcodes = PostcodesService.getAvailablePostcodes();

        // Assert
        for (final postcode in postcodes) {
          expect(postcode, isA<String>());
          expect(int.tryParse(postcode), isNotNull);
          expect(postcode.length, equals(4));
        }
      });

      test('should include known postcodes', () {
        // Act
        final postcodes = PostcodesService.getAvailablePostcodes();

        // Assert
        expect(postcodes, contains('5000')); // Adelaide CBD
        expect(postcodes, contains('5001')); // Adelaide
        expect(postcodes, contains('5006')); // North Adelaide
        expect(postcodes, contains('5950')); // Last postcode in list
      });

      test('should not contain duplicates', () {
        // Act
        final postcodes = PostcodesService.getAvailablePostcodes();

        // Assert
        final uniquePostcodes = postcodes.toSet();
        expect(postcodes.length, equals(uniquePostcodes.length));
      });

      test('should be sorted in ascending order', () {
        // Act
        final postcodes = PostcodesService.getAvailablePostcodes();

        // Assert
        final sortedPostcodes = List<String>.from(postcodes)
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        expect(postcodes, equals(sortedPostcodes));
      });
    });

    group('isValidPostcode', () {
      test('should return true for valid postcodes', () {
        // Arrange
        final validPostcodes = ['5000', '5001', '5006', '5950'];

        // Act & Assert
        for (final postcode in validPostcodes) {
          final result = PostcodesService.isValidPostcode(postcode);
          expect(result, isTrue, reason: 'Postcode $postcode should be valid');
        }
      });

      test('should return false for invalid postcodes', () {
        // Arrange
        final invalidPostcodes = ['0000', '9999', '1234', '5002'];

        // Act & Assert
        for (final postcode in invalidPostcodes) {
          final result = PostcodesService.isValidPostcode(postcode);
          expect(
            result,
            isFalse,
            reason: 'Postcode $postcode should be invalid',
          );
        }
      });

      test('should return false for non-numeric strings', () {
        // Arrange
        final nonNumericPostcodes = ['abcd', '50a0', 'test', ''];

        // Act & Assert
        for (final postcode in nonNumericPostcodes) {
          final result = PostcodesService.isValidPostcode(postcode);
          expect(
            result,
            isFalse,
            reason: 'Non-numeric postcode $postcode should be invalid',
          );
        }
      });

      test('should return false for postcodes with incorrect length', () {
        // Arrange
        final incorrectLengthPostcodes = ['500', '50000', '1', '123456'];

        // Act & Assert
        for (final postcode in incorrectLengthPostcodes) {
          final result = PostcodesService.isValidPostcode(postcode);
          expect(
            result,
            isFalse,
            reason:
                'Postcode $postcode with incorrect length should be invalid',
          );
        }
      });

      test('should handle edge cases', () {
        // Test various edge cases
        expect(PostcodesService.isValidPostcode(''), isFalse);
        expect(PostcodesService.isValidPostcode(' '), isFalse);
        expect(PostcodesService.isValidPostcode('null'), isFalse);
        expect(PostcodesService.isValidPostcode('0'), isFalse);
        expect(PostcodesService.isValidPostcode('-5000'), isFalse);
        expect(PostcodesService.isValidPostcode('5000.0'), isFalse);
        expect(PostcodesService.isValidPostcode('5000 '), isTrue);
        expect(PostcodesService.isValidPostcode(' 5000'), isTrue);
      });

      test('should validate all available postcodes', () {
        // Arrange
        final availablePostcodes = PostcodesService.getAvailablePostcodes();

        // Act & Assert
        for (final postcode in availablePostcodes) {
          final result = PostcodesService.isValidPostcode(postcode);
          expect(
            result,
            isTrue,
            reason: 'Available postcode $postcode should be valid',
          );
        }
      });

      test('should handle null safety', () {
        // Test that the method doesn't crash with edge inputs
        expect(() => PostcodesService.isValidPostcode(''), returnsNormally);
        expect(() => PostcodesService.isValidPostcode('abc'), returnsNormally);
        expect(
          () => PostcodesService.isValidPostcode('12345'),
          returnsNormally,
        );
      });
    });

    group('searchPostcodes', () {
      test('should return all postcodes when prefix is empty', () {
        // Act
        final result = PostcodesService.searchPostcodes('');

        // Assert
        expect(result, equals(PostcodesService.getAvailablePostcodes()));
      });

      test('should filter postcodes by prefix correctly', () {
        // Test various prefixes
        final testCases = {
          '50': ['5000', '5001', '5005'], // Should include these
          '51': ['5106', '5107', '5108'], // Should include these
          '59': ['5942', '5950'], // Should include these
          '52': ['5201', '5202', '5203'], // Should include these
        };

        testCases.forEach((prefix, expectedToInclude) {
          final result = PostcodesService.searchPostcodes(prefix);

          expect(result, isA<List<String>>());

          // Check that all results start with the prefix
          for (final postcode in result) {
            expect(
              postcode.startsWith(prefix),
              isTrue,
              reason: 'Postcode $postcode should start with prefix $prefix',
            );
          }

          // Check that expected postcodes are included
          for (final expectedPostcode in expectedToInclude) {
            if (PostcodesService.isValidPostcode(expectedPostcode)) {
              expect(
                result,
                contains(expectedPostcode),
                reason:
                    'Expected postcode $expectedPostcode should be in results for prefix $prefix',
              );
            }
          }
        });
      });

      test('should return empty list for non-matching prefix', () {
        // Arrange
        final nonMatchingPrefixes = ['1', '2', '3', '4', '6', '7', '8', '9'];

        // Act & Assert
        for (final prefix in nonMatchingPrefixes) {
          final result = PostcodesService.searchPostcodes(prefix);
          expect(
            result,
            isEmpty,
            reason: 'Prefix $prefix should return no results',
          );
        }
      });

      test('should handle specific prefix searches', () {
        // Test specific prefixes
        final result500 = PostcodesService.searchPostcodes('500');
        expect(result500, contains('5000'));
        expect(result500, contains('5001'));
        expect(result500.every((p) => p.startsWith('500')), isTrue);

        final result510 = PostcodesService.searchPostcodes('510');
        expect(result510.every((p) => p.startsWith('510')), isTrue);

        final result595 = PostcodesService.searchPostcodes('595');
        expect(result595, contains('5950'));
        expect(result595.every((p) => p.startsWith('595')), isTrue);
      });

      test('should maintain sorted order in results', () {
        // Test that results are still sorted
        final prefixes = ['50', '51', '52', '53', '58'];

        for (final prefix in prefixes) {
          final result = PostcodesService.searchPostcodes(prefix);

          if (result.isNotEmpty) {
            final sortedResult = List<String>.from(result)
              ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
            expect(
              result,
              equals(sortedResult),
              reason: 'Results for prefix $prefix should be sorted',
            );
          }
        }
      });

      test('should handle full postcode as prefix', () {
        // Test searching with a complete postcode
        final fullPostcodes = ['5000', '5001', '5950'];

        for (final postcode in fullPostcodes) {
          if (PostcodesService.isValidPostcode(postcode)) {
            final result = PostcodesService.searchPostcodes(postcode);
            expect(
              result,
              contains(postcode),
              reason:
                  'Searching for full postcode $postcode should include itself',
            );
            expect(result.every((p) => p.startsWith(postcode)), isTrue);
          }
        }
      });

      test('should handle longer prefixes that match no postcodes', () {
        // Test prefixes longer than 4 characters
        final longPrefixes = ['50000', '123456', '50001'];

        for (final prefix in longPrefixes) {
          final result = PostcodesService.searchPostcodes(prefix);
          expect(
            result,
            isEmpty,
            reason: 'Long prefix $prefix should return no results',
          );
        }
      });

      test('should handle non-numeric prefixes', () {
        // Test non-numeric prefixes
        final nonNumericPrefixes = ['a', 'abc', '5a', 'test'];

        for (final prefix in nonNumericPrefixes) {
          final result = PostcodesService.searchPostcodes(prefix);
          expect(
            result,
            isEmpty,
            reason: 'Non-numeric prefix $prefix should return no results',
          );
        }
      });

      test('should verify specific Adelaide region postcodes', () {
        // Test specific Adelaide area postcodes
        final result50 = PostcodesService.searchPostcodes('50');

        // Check for key Adelaide postcodes
        expect(result50, contains('5000')); // Adelaide CBD
        expect(result50, contains('5006')); // North Adelaide
        expect(result50, contains('5008')); // Brompton
        expect(result50, contains('5010')); // Bowden
        expect(result50, contains('5031')); // Campbelltown
        expect(result50, contains('5034')); // Fullarton
        expect(result50, contains('5062')); // Brown Hill Creek
        expect(result50, contains('5082')); // Prospect
      });

      test('should handle case sensitivity', () {
        // Since postcodes are numeric, case shouldn't matter, but test robustness
        final result = PostcodesService.searchPostcodes('50');
        expect(result, isA<List<String>>());
        expect(result.isNotEmpty, isTrue);
      });

      test('should perform efficiently with different prefix lengths', () {
        // Test performance with different prefix lengths
        final prefixes = ['5', '50', '500', '5000'];

        for (final prefix in prefixes) {
          final stopwatch = Stopwatch()..start();
          final result = PostcodesService.searchPostcodes(prefix);
          stopwatch.stop();

          expect(result, isA<List<String>>());
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason: 'Search for prefix $prefix should complete quickly',
          );
        }
      });
    });

    group('Postcode data integrity', () {
      test('should contain only South Australian postcodes', () {
        // South Australian postcodes start with 5
        final postcodes = PostcodesService.getAvailablePostcodes();

        for (final postcode in postcodes) {
          expect(
            postcode.startsWith('5'),
            isTrue,
            reason: 'All postcodes should start with 5 for South Australia',
          );
        }
      });

      test('should have reasonable postcode ranges', () {
        // Test that postcodes are within expected SA ranges
        final postcodes = PostcodesService.getAvailablePostcodes();

        for (final postcode in postcodes) {
          final postcodeInt = int.parse(postcode);
          expect(postcodeInt, greaterThanOrEqualTo(5000));
          expect(postcodeInt, lessThanOrEqualTo(5999));
        }
      });

      test('should include major Adelaide postcodes', () {
        // Test for major Adelaide area postcodes
        final majorPostcodes = ['5000', '5001', '5006', '5008', '5031', '5061'];
        final availablePostcodes = PostcodesService.getAvailablePostcodes();

        for (final majorPostcode in majorPostcodes) {
          expect(
            availablePostcodes,
            contains(majorPostcode),
            reason: 'Should include major Adelaide postcode $majorPostcode',
          );
        }
      });

      test('should not contain obviously invalid postcodes', () {
        // Test that obviously invalid postcodes are not included
        final invalidPostcodes = [
          '0000',
          '1000',
          '2000',
          '3000',
          '4000',
          '6000',
        ];
        final availablePostcodes = PostcodesService.getAvailablePostcodes();

        for (final invalidPostcode in invalidPostcodes) {
          expect(
            availablePostcodes,
            isNot(contains(invalidPostcode)),
            reason: 'Should not include invalid postcode $invalidPostcode',
          );
        }
      });
    });

    group('Static method behavior', () {
      test('should be callable without instantiation', () {
        // Test that all methods are static and can be called without creating an instance
        expect(() => PostcodesService.length, returnsNormally);
        expect(() => PostcodesService.getAvailablePostcodes(), returnsNormally);
        expect(() => PostcodesService.isValidPostcode('5000'), returnsNormally);
        expect(() => PostcodesService.searchPostcodes('50'), returnsNormally);
      });

      test('should return consistent results across calls', () {
        // Test that multiple calls return the same results
        final postcodes1 = PostcodesService.getAvailablePostcodes();
        final postcodes2 = PostcodesService.getAvailablePostcodes();
        expect(postcodes1, equals(postcodes2));

        final search1 = PostcodesService.searchPostcodes('50');
        final search2 = PostcodesService.searchPostcodes('50');
        expect(search1, equals(search2));

        final valid1 = PostcodesService.isValidPostcode('5000');
        final valid2 = PostcodesService.isValidPostcode('5000');
        expect(valid1, equals(valid2));
      });
    });
  });
}
