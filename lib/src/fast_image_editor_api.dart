import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'enums.dart';
import 'exceptions.dart';
import 'native_bindings.dart';

// ============================================================================
// Helper: throw if native result indicates error
// ============================================================================

void _throwIfError(int result) {
  if (result != 0) {
    throw NativeEditException(result);
  }
}

/// High-performance native image editor with region-based effects.
///
/// All methods are static. Each filter has a sync and async (Isolate) variant.
/// The async variants run in a separate isolate to avoid blocking the UI thread.
///
/// ```dart
/// // Blur entire image
/// final blurred = FastImageEditor.blur(bytes: imageBytes, radius: 15);
///
/// // Sepia on top 30% only
/// final sepia = FastImageEditor.sepia(
///   bytes: imageBytes,
///   region: EditRegion(top: 0.3),
/// );
///
/// // Async variant
/// final result = await FastImageEditor.blurAsync(bytes: imageBytes, radius: 10);
/// ```
class FastImageEditor {
  // ============================================================================
  // Format detection
  // ============================================================================

  /// Detect the image format from raw bytes.
  ///
  /// Returns the detected [ImageFormat] or `null` if the format is not supported.
  static ImageFormat? detectFormat(Uint8List bytes) {
    if (bytes.length < 4) return null;

    // JPEG: starts with FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return ImageFormat.jpeg;
    }

    // PNG: starts with 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return ImageFormat.png;
    }

    return null;
  }

  // ============================================================================
  // Internal helper: call native filter function
  // ============================================================================

  static Uint8List _callNative({
    required Uint8List bytes,
    required int Function(
      Pointer<Uint8> inputData,
      int inputSize,
      Pointer<Pointer<Uint8>> outputData,
      Pointer<Int32> outputSize,
    ) nativeCall,
  }) {
    final inputPtr = calloc<Uint8>(bytes.length);
    final outputDataPtr = calloc<Pointer<Uint8>>();
    final outputSizePtr = calloc<Int32>();

    try {
      inputPtr.asTypedList(bytes.length).setAll(0, bytes);

      final result = nativeCall(
        inputPtr,
        bytes.length,
        outputDataPtr,
        outputSizePtr,
      );

      _throwIfError(result);

      final outputData = outputDataPtr.value;
      final outputSize = outputSizePtr.value;

      final resultBytes = Uint8List.fromList(
        outputData.asTypedList(outputSize),
      );

      NativeBindings.instance.freeBuffer(outputData);

      return resultBytes;
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputDataPtr);
      calloc.free(outputSizePtr);
    }
  }

  // ============================================================================
  // Blur
  // ============================================================================

  /// Apply blur effect to an image.
  ///
  /// Uses box blur with 3 passes for Gaussian approximation.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [radius] - Blur radius in pixels (must be >= 1).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List blur({
    required Uint8List bytes,
    int radius = 10,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditBlur(
          inputPtr,
          inputSize,
          radius,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [blur]. Runs in a separate isolate.
  static Future<Uint8List> blurAsync({
    required Uint8List bytes,
    int radius = 10,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () =>
          blur(bytes: bytes, radius: radius, region: region, quality: quality),
    );
  }

  // ============================================================================
  // Sepia
  // ============================================================================

  /// Apply sepia tone filter to an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [intensity] - Sepia intensity (0.0 = original, 1.0 = full sepia).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List sepia({
    required Uint8List bytes,
    double intensity = 1.0,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditSepia(
          inputPtr,
          inputSize,
          intensity,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [sepia]. Runs in a separate isolate.
  static Future<Uint8List> sepiaAsync({
    required Uint8List bytes,
    double intensity = 1.0,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => sepia(
          bytes: bytes, intensity: intensity, region: region, quality: quality),
    );
  }

  // ============================================================================
  // Saturation
  // ============================================================================

  /// Adjust color saturation of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Saturation factor (0.0 = grayscale, 1.0 = original, 2.0 = double).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List saturation({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditSaturation(
          inputPtr,
          inputSize,
          factor,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [saturation]. Runs in a separate isolate.
  static Future<Uint8List> saturationAsync({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => saturation(
          bytes: bytes, factor: factor, region: region, quality: quality),
    );
  }

  // ============================================================================
  // Brightness
  // ============================================================================

  /// Adjust brightness of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Brightness factor (-1.0 to 1.0, 0.0 = no change).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List brightness({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditBrightness(
          inputPtr,
          inputSize,
          factor,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [brightness]. Runs in a separate isolate.
  static Future<Uint8List> brightnessAsync({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => brightness(
          bytes: bytes, factor: factor, region: region, quality: quality),
    );
  }

  // ============================================================================
  // Contrast
  // ============================================================================

  /// Adjust contrast of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Contrast factor (0.0 to 2.0, 1.0 = original).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List contrast({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditContrast(
          inputPtr,
          inputSize,
          factor,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [contrast]. Runs in a separate isolate.
  static Future<Uint8List> contrastAsync({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => contrast(
          bytes: bytes, factor: factor, region: region, quality: quality),
    );
  }

  // ============================================================================
  // Sharpen
  // ============================================================================

  /// Sharpen an image using unsharp mask.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [amount] - Sharpening amount (0.0-5.0, default 1.0).
  /// [radius] - Blur radius for unsharp mask (1-10, default 1).
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List sharpen({
    required Uint8List bytes,
    double amount = 1.0,
    int radius = 1,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditSharpen(
          inputPtr,
          inputSize,
          amount,
          radius,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [sharpen]. Runs in a separate isolate.
  static Future<Uint8List> sharpenAsync({
    required Uint8List bytes,
    double amount = 1.0,
    int radius = 1,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => sharpen(
          bytes: bytes,
          amount: amount,
          radius: radius,
          region: region,
          quality: quality),
    );
  }

  // ============================================================================
  // Grayscale
  // ============================================================================

  /// Convert an image to grayscale.
  ///
  /// Uses luminance formula: 0.2126R + 0.7152G + 0.0722B.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [region] - Region to apply the effect to. Null = entire image.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List grayscale({
    required Uint8List bytes,
    EditRegion? region,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    return _callNative(
      bytes: bytes,
      nativeCall: (inputPtr, inputSize, outputDataPtr, outputSizePtr) {
        return NativeBindings.instance.imageEditGrayscale(
          inputPtr,
          inputSize,
          r.top,
          r.bottom,
          r.left,
          r.right,
          outputDataPtr,
          outputSizePtr,
          quality,
        );
      },
    );
  }

  /// Async version of [grayscale]. Runs in a separate isolate.
  static Future<Uint8List> grayscaleAsync({
    required Uint8List bytes,
    EditRegion? region,
    int quality = 90,
  }) {
    return Isolate.run(
      () => grayscale(bytes: bytes, region: region, quality: quality),
    );
  }
}
