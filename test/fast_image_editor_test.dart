import 'dart:typed_data';

import 'package:fast_image_editor/fast_image_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================================
  // ImageFormat
  // ============================================================================

  group('ImageFormat', () {
    test('has jpeg and png values', () {
      expect(ImageFormat.values.length, 2);
      expect(ImageFormat.jpeg, isNotNull);
      expect(ImageFormat.png, isNotNull);
    });

    test('values are distinct', () {
      expect(ImageFormat.jpeg, isNot(ImageFormat.png));
    });

    test('index values are sequential', () {
      expect(ImageFormat.jpeg.index, 0);
      expect(ImageFormat.png.index, 1);
    });
  });

  // ============================================================================
  // EditRegion
  // ============================================================================

  group('EditRegion', () {
    test('default constructor has all zeros', () {
      const region = EditRegion();
      expect(region.top, 0.0);
      expect(region.bottom, 0.0);
      expect(region.left, 0.0);
      expect(region.right, 0.0);
    });

    test('full region has all zeros (applies to entire image)', () {
      expect(EditRegion.full.top, 0.0);
      expect(EditRegion.full.bottom, 0.0);
      expect(EditRegion.full.left, 0.0);
      expect(EditRegion.full.right, 0.0);
    });

    test('named parameters work correctly', () {
      const region = EditRegion(top: 0.3, bottom: 0.2);
      expect(region.top, 0.3);
      expect(region.bottom, 0.2);
      expect(region.left, 0.0);
      expect(region.right, 0.0);
    });

    test('all edges can be set', () {
      const region = EditRegion(
        top: 0.1,
        bottom: 0.2,
        left: 0.3,
        right: 0.4,
      );
      expect(region.top, 0.1);
      expect(region.bottom, 0.2);
      expect(region.left, 0.3);
      expect(region.right, 0.4);
    });

    test('single edge top only', () {
      const region = EditRegion(top: 0.5);
      expect(region.top, 0.5);
      expect(region.bottom, 0.0);
      expect(region.left, 0.0);
      expect(region.right, 0.0);
    });

    test('single edge bottom only', () {
      const region = EditRegion(bottom: 0.7);
      expect(region.top, 0.0);
      expect(region.bottom, 0.7);
    });

    test('single edge left only', () {
      const region = EditRegion(left: 0.4);
      expect(region.left, 0.4);
      expect(region.right, 0.0);
    });

    test('single edge right only', () {
      const region = EditRegion(right: 0.6);
      expect(region.right, 0.6);
      expect(region.left, 0.0);
    });

    test('accepts boundary values 0.0 and 1.0', () {
      const region = EditRegion(top: 0.0, bottom: 1.0, left: 0.0, right: 1.0);
      expect(region.top, 0.0);
      expect(region.bottom, 1.0);
      expect(region.left, 0.0);
      expect(region.right, 1.0);
    });

    test('can be used as const', () {
      const region1 = EditRegion(top: 0.3);
      const region2 = EditRegion(top: 0.3);
      // Both are compile-time constants
      expect(region1.top, region2.top);
    });

    test('full is const', () {
      // Verify full is const-constructable
      const fullRegion = EditRegion.full;
      expect(fullRegion, isNotNull);
    });

    test('symmetric top-bottom region', () {
      const region = EditRegion(top: 0.3, bottom: 0.3);
      expect(region.top, region.bottom);
    });

    test('symmetric left-right region', () {
      const region = EditRegion(left: 0.2, right: 0.2);
      expect(region.left, region.right);
    });
  });

  // ============================================================================
  // NativeEditError
  // ============================================================================

  group('NativeEditError', () {
    test('has 6 error codes', () {
      expect(NativeEditError.values.length, 6);
    });

    test('all error codes are negative', () {
      for (final error in NativeEditError.values) {
        expect(error.code, lessThan(0));
      }
    });

    test('all error codes are unique', () {
      final codes = NativeEditError.values.map((e) => e.code).toSet();
      expect(codes.length, NativeEditError.values.length);
    });

    test('all errors have non-empty descriptions', () {
      for (final error in NativeEditError.values) {
        expect(error.description, isNotEmpty);
      }
    });

    test('error codes are sequential from -1 to -6', () {
      expect(NativeEditError.nullInput.code, -1);
      expect(NativeEditError.invalidDims.code, -2);
      expect(NativeEditError.decodeFailed.code, -3);
      expect(NativeEditError.allocFailed.code, -4);
      expect(NativeEditError.encodeFailed.code, -5);
      expect(NativeEditError.invalidParam.code, -6);
    });

    test('fromCode returns correct error for each code', () {
      expect(NativeEditError.fromCode(-1), NativeEditError.nullInput);
      expect(NativeEditError.fromCode(-2), NativeEditError.invalidDims);
      expect(NativeEditError.fromCode(-3), NativeEditError.decodeFailed);
      expect(NativeEditError.fromCode(-4), NativeEditError.allocFailed);
      expect(NativeEditError.fromCode(-5), NativeEditError.encodeFailed);
      expect(NativeEditError.fromCode(-6), NativeEditError.invalidParam);
    });

    test('fromCode returns null for zero (success code)', () {
      expect(NativeEditError.fromCode(0), isNull);
    });

    test('fromCode returns null for positive codes', () {
      expect(NativeEditError.fromCode(1), isNull);
      expect(NativeEditError.fromCode(100), isNull);
    });

    test('fromCode returns null for unknown negative codes', () {
      expect(NativeEditError.fromCode(-7), isNull);
      expect(NativeEditError.fromCode(-99), isNull);
      expect(NativeEditError.fromCode(-1000), isNull);
    });

    test('descriptions contain meaningful keywords', () {
      expect(NativeEditError.nullInput.description.toLowerCase(),
          contains('null'));
      expect(NativeEditError.invalidDims.description.toLowerCase(),
          contains('dimension'));
      expect(NativeEditError.decodeFailed.description.toLowerCase(),
          contains('decod'));
      expect(NativeEditError.allocFailed.description.toLowerCase(),
          contains('alloc'));
      expect(NativeEditError.encodeFailed.description.toLowerCase(),
          contains('encod'));
      expect(NativeEditError.invalidParam.description.toLowerCase(),
          contains('param'));
    });
  });

  // ============================================================================
  // NativeEditException
  // ============================================================================

  group('NativeEditException', () {
    test('maps known error code correctly', () {
      final exception = NativeEditException(-3);
      expect(exception.nativeCode, -3);
      expect(exception.error, NativeEditError.decodeFailed);
      expect(exception.message, contains('decoding'));
    });

    test('handles unknown error code', () {
      final exception = NativeEditException(-99);
      expect(exception.nativeCode, -99);
      expect(exception.error, isNull);
      expect(exception.message, contains('Unknown'));
    });

    test('toString contains class name and code', () {
      final exception = NativeEditException(-1);
      final str = exception.toString();
      expect(str, contains('NativeEditException'));
      expect(str, contains('-1'));
    });

    test('maps all known error codes', () {
      for (final error in NativeEditError.values) {
        final exception = NativeEditException(error.code);
        expect(exception.error, error);
        expect(exception.nativeCode, error.code);
        expect(exception.message, error.description);
      }
    });

    test('message matches error description for known codes', () {
      final exception = NativeEditException(-4);
      expect(exception.message, NativeEditError.allocFailed.description);
    });

    test('message contains code for unknown errors', () {
      final exception = NativeEditException(-42);
      expect(exception.message, contains('-42'));
    });

    test('implements Exception interface', () {
      final exception = NativeEditException(-1);
      expect(exception, isA<Exception>());
    });

    test('toString format is consistent', () {
      for (final error in NativeEditError.values) {
        final exception = NativeEditException(error.code);
        final str = exception.toString();
        expect(str, startsWith('NativeEditException: '));
        expect(str, contains('code: ${error.code}'));
      }
    });
  });

  // ============================================================================
  // UnsupportedImageFormatException
  // ============================================================================

  group('UnsupportedImageFormatException', () {
    test('has default message', () {
      final exception = UnsupportedImageFormatException(
        bytes: Uint8List.fromList([0, 0, 0, 0]),
      );
      expect(exception.message, contains('Unsupported'));
      expect(exception.message, contains('JPEG'));
      expect(exception.message, contains('PNG'));
      expect(exception.bytes.length, 4);
    });

    test('accepts custom message', () {
      final exception = UnsupportedImageFormatException(
        bytes: Uint8List(0),
        message: 'Custom error',
      );
      expect(exception.message, 'Custom error');
    });

    test('toString contains class name', () {
      final exception = UnsupportedImageFormatException(
        bytes: Uint8List(0),
      );
      expect(exception.toString(), contains('UnsupportedImageFormatException'));
    });

    test('toString contains message', () {
      final exception = UnsupportedImageFormatException(
        bytes: Uint8List(0),
        message: 'Test error message',
      );
      expect(exception.toString(), contains('Test error message'));
    });

    test('preserves input bytes reference', () {
      final inputBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final exception = UnsupportedImageFormatException(bytes: inputBytes);
      expect(exception.bytes, same(inputBytes));
      expect(exception.bytes.length, 5);
    });

    test('implements Exception interface', () {
      final exception = UnsupportedImageFormatException(bytes: Uint8List(0));
      expect(exception, isA<Exception>());
    });

    test('works with empty bytes', () {
      final exception = UnsupportedImageFormatException(bytes: Uint8List(0));
      expect(exception.bytes.length, 0);
      expect(exception.message, isNotEmpty);
    });

    test('works with large byte arrays', () {
      final largeBytes = Uint8List(1024 * 1024); // 1MB
      final exception = UnsupportedImageFormatException(bytes: largeBytes);
      expect(exception.bytes.length, 1024 * 1024);
    });
  });

  // ============================================================================
  // FastImageEditor.detectFormat
  // ============================================================================

  group('FastImageEditor.detectFormat', () {
    group('JPEG detection', () {
      test('detects standard JPEG (APP0/JFIF marker)', () {
        final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        expect(FastImageEditor.detectFormat(jpeg), ImageFormat.jpeg);
      });

      test('detects JPEG with APP1/EXIF marker', () {
        final jpegExif = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1]);
        expect(FastImageEditor.detectFormat(jpegExif), ImageFormat.jpeg);
      });

      test('detects JPEG with other APP markers', () {
        // APP2 through APP15
        for (int marker = 0xE2; marker <= 0xEF; marker++) {
          final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, marker]);
          expect(FastImageEditor.detectFormat(jpeg), ImageFormat.jpeg,
              reason: 'Failed for APP marker 0x${marker.toRadixString(16)}');
        }
      });

      test('detects JPEG with DQT marker', () {
        final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xDB]);
        expect(FastImageEditor.detectFormat(jpeg), ImageFormat.jpeg);
      });

      test('detects JPEG with trailing data', () {
        final jpeg =
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A]);
        expect(FastImageEditor.detectFormat(jpeg), ImageFormat.jpeg);
      });

      test('detects JPEG minimum valid bytes', () {
        // Exactly 4 bytes with valid JPEG header
        final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xC0]);
        expect(FastImageEditor.detectFormat(jpeg), ImageFormat.jpeg);
      });
    });

    group('PNG detection', () {
      test('detects PNG with magic number', () {
        final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
        expect(FastImageEditor.detectFormat(png), ImageFormat.png);
      });

      test('detects PNG with full 8-byte signature', () {
        final png = Uint8List.fromList(
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        expect(FastImageEditor.detectFormat(png), ImageFormat.png);
      });

      test('detects PNG with trailing data', () {
        final png = Uint8List.fromList(
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00]);
        expect(FastImageEditor.detectFormat(png), ImageFormat.png);
      });
    });

    group('unsupported formats', () {
      test('returns null for unknown format', () {
        final unknown = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
        expect(FastImageEditor.detectFormat(unknown), isNull);
      });

      test('returns null for BMP', () {
        final bmp = Uint8List.fromList([0x42, 0x4D, 0x00, 0x00]);
        expect(FastImageEditor.detectFormat(bmp), isNull);
      });

      test('returns null for GIF87a', () {
        final gif = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]);
        expect(FastImageEditor.detectFormat(gif), isNull);
      });

      test('returns null for GIF89a', () {
        final gif = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
        expect(FastImageEditor.detectFormat(gif), isNull);
      });

      test('returns null for WebP', () {
        final webp = Uint8List.fromList(
            [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45]);
        expect(FastImageEditor.detectFormat(webp), isNull);
      });

      test('returns null for TIFF little-endian', () {
        final tiff = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]);
        expect(FastImageEditor.detectFormat(tiff), isNull);
      });

      test('returns null for TIFF big-endian', () {
        final tiff = Uint8List.fromList([0x4D, 0x4D, 0x00, 0x2A]);
        expect(FastImageEditor.detectFormat(tiff), isNull);
      });

      test('returns null for random bytes', () {
        final random = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
        expect(FastImageEditor.detectFormat(random), isNull);
      });

      test('returns null for all zeros', () {
        final zeros = Uint8List(100);
        expect(FastImageEditor.detectFormat(zeros), isNull);
      });

      test('returns null for all 0xFF', () {
        final allFf = Uint8List.fromList(List.filled(100, 0xFF));
        expect(FastImageEditor.detectFormat(allFf), isNull);
      });
    });

    group('edge cases', () {
      test('returns null for empty input', () {
        final empty = Uint8List(0);
        expect(FastImageEditor.detectFormat(empty), isNull);
      });

      test('returns null for 1 byte', () {
        final one = Uint8List.fromList([0xFF]);
        expect(FastImageEditor.detectFormat(one), isNull);
      });

      test('returns null for 2 bytes', () {
        final two = Uint8List.fromList([0xFF, 0xD8]);
        expect(FastImageEditor.detectFormat(two), isNull);
      });

      test('returns null for 3 bytes', () {
        final three = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
        expect(FastImageEditor.detectFormat(three), isNull);
      });

      test('returns null for 3 bytes PNG-like', () {
        final three = Uint8List.fromList([0x89, 0x50, 0x4E]);
        expect(FastImageEditor.detectFormat(three), isNull);
      });

      test('does not false-positive on partial JPEG header', () {
        // FF D8 but not followed by FF
        final partial = Uint8List.fromList([0xFF, 0xD8, 0x00, 0x00]);
        expect(FastImageEditor.detectFormat(partial), isNull);
      });

      test('does not false-positive on partial PNG header', () {
        // 89 50 but wrong continuation
        final partial = Uint8List.fromList([0x89, 0x50, 0x00, 0x00]);
        expect(FastImageEditor.detectFormat(partial), isNull);
      });
    });
  });

  // ============================================================================
  // Error code coverage — round-trip through exception
  // ============================================================================

  group('Error code round-trip', () {
    test('every NativeEditError can create an exception and recover', () {
      for (final error in NativeEditError.values) {
        final exception = NativeEditException(error.code);
        final recovered = NativeEditError.fromCode(exception.nativeCode);
        expect(recovered, error);
      }
    });

    test('exception preserves unknown error code', () {
      const unknownCode = -123;
      final exception = NativeEditException(unknownCode);
      expect(exception.nativeCode, unknownCode);
      expect(NativeEditError.fromCode(exception.nativeCode), isNull);
    });
  });
}
