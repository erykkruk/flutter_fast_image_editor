import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart'
    hide ImageFormat;

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
/// Supports two region types:
/// - [EditRegion] — rectangular region defined by edge percentages
/// - [RadialRegion] — circular region defined by center position and radius
///
/// When [radialRegion] is provided, [region] is ignored.
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
/// // Blur a circle in the center
/// final radialBlur = FastImageEditor.blur(
///   bytes: imageBytes,
///   radius: 20,
///   radialRegion: RadialRegion(centerX: 0.0, centerY: 0.0, radius: 0.3),
/// );
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
  /// [region] - Rectangular region to apply the effect to. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List blur({
    required Uint8List bytes,
    int radius = 10,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => blur(
        bytes: bytes,
        radius: radius,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
    );
  }

  // ============================================================================
  // Sepia
  // ============================================================================

  /// Apply sepia tone filter to an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [intensity] - Sepia intensity (0.0 = original, 1.0 = full sepia).
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List sepia({
    required Uint8List bytes,
    double intensity = 1.0,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => sepia(
        bytes: bytes,
        intensity: intensity,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
    );
  }

  // ============================================================================
  // Saturation
  // ============================================================================

  /// Adjust color saturation of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Saturation factor (0.0 = grayscale, 1.0 = original, 2.0 = double).
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List saturation({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => saturation(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
    );
  }

  // ============================================================================
  // Brightness
  // ============================================================================

  /// Adjust brightness of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Brightness factor (-1.0 to 1.0, 0.0 = no change).
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List brightness({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => brightness(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
    );
  }

  // ============================================================================
  // Contrast
  // ============================================================================

  /// Adjust contrast of an image.
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [factor] - Contrast factor (0.0 to 2.0, 1.0 = original).
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List contrast({
    required Uint8List bytes,
    required double factor,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => contrast(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
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
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List sharpen({
    required Uint8List bytes,
    double amount = 1.0,
    int radius = 1,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => sharpen(
        bytes: bytes,
        amount: amount,
        radius: radius,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
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
  /// [region] - Rectangular region. Null = entire image.
  /// [radialRegion] - Circular region. When provided, [region] is ignored.
  /// [quality] - JPEG output quality (1-100, default 90). Ignored for PNG.
  static Uint8List grayscale({
    required Uint8List bytes,
    EditRegion? region,
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    final r = region ?? EditRegion.full;
    final rcx = radialRegion?.centerX ?? 0.0;
    final rcy = radialRegion?.centerY ?? 0.0;
    final rr = radialRegion?.radius ?? 0.0;
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
          rcx,
          rcy,
          rr,
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
    RadialRegion? radialRegion,
    int quality = 90,
  }) {
    return Isolate.run(
      () => grayscale(
        bytes: bytes,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      ),
    );
  }

  // ============================================================================
  // Resize (via flutter_bicubic_resize)
  // ============================================================================

  /// Resize an image using high-quality bicubic interpolation.
  ///
  /// Automatically detects JPEG/PNG format and preserves it.
  /// Powered by [flutter_bicubic_resize](https://pub.dev/packages/flutter_bicubic_resize).
  ///
  /// [bytes] - JPEG or PNG image data.
  /// [outputWidth] - Target width in pixels.
  /// [outputHeight] - Target height in pixels.
  /// [quality] - JPEG output quality (1-100, default 95). Ignored for PNG.
  /// [compressionLevel] - PNG compression level (0-9, default 6). Ignored for JPEG.
  /// [filter] - Bicubic filter type (default: catmullRom).
  /// [edgeMode] - Edge handling mode (default: clamp).
  /// [crop] - Crop factor (1.0 = no crop, > 1.0 = zoom in).
  /// [cropAnchor] - Anchor point for cropping (default: center).
  /// [cropAspectRatio] - Aspect ratio mode for cropping.
  /// [aspectRatioWidth] - Custom aspect ratio width (when cropAspectRatio = custom).
  /// [aspectRatioHeight] - Custom aspect ratio height (when cropAspectRatio = custom).
  static Uint8List resize({
    required Uint8List bytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
    int compressionLevel = 6,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
  }) {
    return BicubicResizer.resize(
      bytes: bytes,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      quality: quality,
      compressionLevel: compressionLevel,
      filter: filter,
      edgeMode: edgeMode,
      crop: crop,
      cropAnchor: cropAnchor,
      cropAspectRatio: cropAspectRatio,
      aspectRatioWidth: aspectRatioWidth,
      aspectRatioHeight: aspectRatioHeight,
    );
  }

  /// Async version of [resize]. Runs in a separate isolate.
  static Future<Uint8List> resizeAsync({
    required Uint8List bytes,
    required int outputWidth,
    required int outputHeight,
    int quality = 95,
    int compressionLevel = 6,
    BicubicFilter filter = BicubicFilter.catmullRom,
    EdgeMode edgeMode = EdgeMode.clamp,
    double crop = 1.0,
    CropAnchor cropAnchor = CropAnchor.center,
    CropAspectRatio cropAspectRatio = CropAspectRatio.square,
    double aspectRatioWidth = 1.0,
    double aspectRatioHeight = 1.0,
  }) {
    return BicubicResizer.resizeAsync(
      bytes: bytes,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      quality: quality,
      compressionLevel: compressionLevel,
      filter: filter,
      edgeMode: edgeMode,
      crop: crop,
      cropAnchor: cropAnchor,
      cropAspectRatio: cropAspectRatio,
      aspectRatioWidth: aspectRatioWidth,
      aspectRatioHeight: aspectRatioHeight,
    );
  }
}
