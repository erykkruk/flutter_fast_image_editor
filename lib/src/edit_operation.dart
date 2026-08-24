import 'dart:typed_data';

import 'enums.dart';
import 'fast_image_editor_api.dart';

/// A single edit, described rather than executed.
///
/// Operations are values: build a list once and reuse it across images, send
/// it to an isolate, or store it as a preset. Apply one with [apply], or a
/// whole list with [FastImageEditor.applyAll].
///
/// ```dart
/// const vintage = <EditOperation>[
///   SepiaOperation(intensity: 0.7),
///   ContrastOperation(factor: 1.2),
///   BlurOperation(radius: 3, radialRegion: RadialRegion(radius: 0.9)),
/// ];
///
/// final edited = FastImageEditor.applyAll(bytes: photo, operations: vintage);
/// ```
///
/// Each operation is one native decode/filter/encode round trip, so a long
/// chain re-encodes several times. Order the cheap, size-reducing steps
/// first: a [ResizeOperation] at the front makes everything after it work on
/// fewer pixels.
sealed class EditOperation {
  /// Creates an operation with the JPEG output [quality] it should encode at.
  const EditOperation({this.quality = 90});

  /// JPEG output quality (1-100). Ignored for PNG input.
  final int quality;

  /// Short name used in error messages and debug output.
  String get name;

  /// Runs this operation against [bytes] and returns the edited image.
  ///
  /// Synchronous, like the underlying filter; use
  /// [FastImageEditor.applyAllAsync] to keep it off the UI isolate.
  Uint8List apply(Uint8List bytes);
}

/// Blurs the image, or a region of it.
class BlurOperation extends EditOperation {
  /// Creates a blur with the given [radius] in pixels.
  const BlurOperation({
    this.radius = 10,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Blur radius in pixels (must be >= 1).
  final int radius;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'blur';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.blur(
        bytes: bytes,
        radius: radius,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Applies a sepia tone.
class SepiaOperation extends EditOperation {
  /// Creates a sepia tone at [intensity] (0.0 to 1.0).
  const SepiaOperation({
    this.intensity = 1.0,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Strength of the tone, from 0.0 (no change) to 1.0 (full sepia).
  final double intensity;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'sepia';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.sepia(
        bytes: bytes,
        intensity: intensity,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Scales colour saturation.
class SaturationOperation extends EditOperation {
  /// Creates a saturation change by [factor] (1.0 leaves the image alone).
  const SaturationOperation({
    required this.factor,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Multiplier: 0.0 is greyscale, 1.0 unchanged, above 1.0 more saturated.
  final double factor;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'saturation';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.saturation(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Scales brightness.
class BrightnessOperation extends EditOperation {
  /// Creates a brightness change by [factor] (1.0 leaves the image alone).
  const BrightnessOperation({
    required this.factor,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Multiplier: below 1.0 darkens, above 1.0 brightens.
  final double factor;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'brightness';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.brightness(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Scales contrast.
class ContrastOperation extends EditOperation {
  /// Creates a contrast change by [factor] (1.0 leaves the image alone).
  const ContrastOperation({
    required this.factor,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Multiplier: below 1.0 flattens, above 1.0 deepens.
  final double factor;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'contrast';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.contrast(
        bytes: bytes,
        factor: factor,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Sharpens the image.
class SharpenOperation extends EditOperation {
  /// Creates a sharpen pass at [amount] strength and [radius] pixels.
  const SharpenOperation({
    this.amount = 1.0,
    this.radius = 1,
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Strength of the sharpening.
  final double amount;

  /// Radius in pixels.
  final int radius;

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'sharpen';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.sharpen(
        bytes: bytes,
        amount: amount,
        radius: radius,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Converts the image to greyscale.
class GrayscaleOperation extends EditOperation {
  /// Creates a greyscale conversion.
  const GrayscaleOperation({
    this.region,
    this.radialRegion,
    super.quality,
  });

  /// Rectangular region to affect. Null means the whole image.
  final EditRegion? region;

  /// Circular region to affect. When set, [region] is ignored.
  final RadialRegion? radialRegion;

  @override
  String get name => 'grayscale';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.grayscale(
        bytes: bytes,
        region: region,
        radialRegion: radialRegion,
        quality: quality,
      );
}

/// Resizes the image.
///
/// Put this first in a chain: every later operation then works on the
/// smaller image, which is usually the difference between a snappy pipeline
/// and a slow one.
class ResizeOperation extends EditOperation {
  /// Creates a resize to [outputWidth] x [outputHeight] pixels.
  const ResizeOperation({
    required this.outputWidth,
    required this.outputHeight,
    super.quality = 95,
    this.compressionLevel = 6,
  });

  /// Target width in pixels.
  final int outputWidth;

  /// Target height in pixels.
  final int outputHeight;

  /// PNG compression level (0-9). Ignored for JPEG.
  final int compressionLevel;

  @override
  String get name => 'resize';

  @override
  Uint8List apply(Uint8List bytes) => FastImageEditor.resize(
        bytes: bytes,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
        quality: quality,
        compressionLevel: compressionLevel,
      );
}
