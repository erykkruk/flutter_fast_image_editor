import 'dart:typed_data';

import 'package:fast_image_editor/fast_image_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Applying an operation reaches the native library, which needs a device.
  // These tests cover the parts that do not: the operation values, the
  // chain's own behaviour on an empty list, and the batch scheduler guards.

  group('EditOperation - values', () {
    test('every operation reports a name', () {
      const operations = <EditOperation>[
        BlurOperation(),
        SepiaOperation(),
        SaturationOperation(factor: 1.5),
        BrightnessOperation(factor: 1.2),
        ContrastOperation(factor: 0.8),
        SharpenOperation(),
        GrayscaleOperation(),
        ResizeOperation(outputWidth: 64, outputHeight: 64),
      ];

      for (final operation in operations) {
        expect(operation.name, isNotEmpty);
      }
      expect(
        operations.map((o) => o.name).toSet().length,
        operations.length,
        reason: 'names should identify the operation',
      );
    });

    test('filters default to quality 90', () {
      expect(const BlurOperation().quality, 90);
      expect(const SepiaOperation().quality, 90);
      expect(const GrayscaleOperation().quality, 90);
    });

    test('resize defaults to the higher quality the resizer uses', () {
      expect(
        const ResizeOperation(outputWidth: 10, outputHeight: 10).quality,
        95,
      );
    });

    test('quality can be overridden per operation', () {
      expect(const BlurOperation(quality: 60).quality, 60);
    });

    test('operations carry their own parameters', () {
      const blur = BlurOperation(radius: 25);
      const sepia = SepiaOperation(intensity: 0.4);
      const sharpen = SharpenOperation(amount: 2.0, radius: 3);
      const resize = ResizeOperation(outputWidth: 800, outputHeight: 600);

      expect(blur.radius, 25);
      expect(sepia.intensity, 0.4);
      expect(sharpen.amount, 2.0);
      expect(sharpen.radius, 3);
      expect(resize.outputWidth, 800);
      expect(resize.outputHeight, 600);
    });

    test('a region is carried through to the operation', () {
      const operation = BlurOperation(
        region: EditRegion.topOnly(0.5),
      );

      expect(operation.region, isNotNull);
      expect(operation.region!.top, 0.5);
      expect(operation.radialRegion, isNull);
    });

    test('a radial region is carried through to the operation', () {
      const operation = SepiaOperation(
        radialRegion: RadialRegion(centerX: 0.5, centerY: 0.5, radius: 0.3),
      );

      expect(operation.radialRegion, isNotNull);
      expect(operation.radialRegion!.radius, 0.3);
    });

    test('operations are const, so a preset can be a compile-time list', () {
      const preset = <EditOperation>[
        SepiaOperation(intensity: 0.7),
        ContrastOperation(factor: 1.2),
      ];

      expect(preset, hasLength(2));
    });
  });

  group('applyAll', () {
    test('an empty chain returns the input untouched', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = FastImageEditor.applyAll(
        bytes: bytes,
        operations: const [],
      );

      expect(identical(result, bytes), isTrue);
    });

    test('an empty async chain returns the input untouched', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = await FastImageEditor.applyAllAsync(
        bytes: bytes,
        operations: const [],
      );

      expect(result, equals(bytes));
    });
  });

  group('applyBatch', () {
    test('defaultBatchConcurrency leaves a core for the caller', () {
      expect(FastImageEditor.defaultBatchConcurrency, greaterThanOrEqualTo(1));
    });

    test('an empty batch resolves to an empty list', () async {
      final results = await FastImageEditor.applyBatch(
        images: const [],
        operations: const [GrayscaleOperation()],
      );

      expect(results, isEmpty);
    });

    test('rejects a non-positive concurrency', () {
      expect(
        () => FastImageEditor.applyBatch(
          images: const [],
          operations: const [GrayscaleOperation()],
          concurrency: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => FastImageEditor.applyBatch(
          images: const [],
          operations: const [GrayscaleOperation()],
          concurrency: -2,
        ),
        throwsArgumentError,
      );
    });

    test('concurrency is checked before the empty-batch shortcut', () {
      // A bad concurrency value must not slip through just because this
      // particular batch happened to be empty.
      expect(
        () => FastImageEditor.applyBatch(
          images: const [],
          operations: const [],
          concurrency: 0,
        ),
        throwsArgumentError,
      );
    });

    test('an empty batch with no operations still resolves empty', () async {
      final results = await FastImageEditor.applyBatch(
        images: const [],
        operations: const [],
      );

      expect(results, isEmpty);
    });
  });

  group('API surface', () {
    test('applyAll exists', () {
      expect(FastImageEditor.applyAll, isA<Function>());
    });

    test('applyAllAsync exists', () {
      expect(FastImageEditor.applyAllAsync, isA<Function>());
    });

    test('applyBatch exists', () {
      expect(FastImageEditor.applyBatch, isA<Function>());
    });
  });
}
