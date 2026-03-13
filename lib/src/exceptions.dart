import 'dart:typed_data';

/// Native error codes returned by the C layer.
///
/// These correspond to the `EDIT_*` defines in `image_edit.h`.
enum NativeEditError {
  /// Null pointer passed as input, output, or size parameter.
  nullInput(-1, 'Null pointer passed to native function'),

  /// Invalid dimensions (size <= 0).
  invalidDims(-2, 'Invalid dimensions (size <= 0)'),

  /// Image decoding failed (corrupt or unsupported data).
  decodeFailed(-3, 'Image decoding failed (corrupt or unsupported data)'),

  /// Memory allocation failed in native code.
  allocFailed(-4, 'Memory allocation failed in native code'),

  /// Image encoding failed.
  encodeFailed(-5, 'Image encoding failed'),

  /// Invalid parameter value.
  invalidParam(-6, 'Invalid parameter value');

  /// The native error code value.
  final int code;

  /// Human-readable description of the error.
  final String description;

  const NativeEditError(this.code, this.description);

  /// Look up a [NativeEditError] by its native [code].
  ///
  /// Returns `null` if the code does not match any known error.
  static NativeEditError? fromCode(int code) {
    for (final error in values) {
      if (error.code == code) return error;
    }
    return null;
  }
}

/// Exception thrown when a native image edit operation fails.
///
/// Contains the native error code and a human-readable description.
class NativeEditException implements Exception {
  /// The raw native error code returned by the C function.
  final int nativeCode;

  /// The mapped error enum, or `null` if the code is unrecognized.
  final NativeEditError? error;

  /// Human-readable message describing the failure.
  final String message;

  NativeEditException(this.nativeCode)
      : error = NativeEditError.fromCode(nativeCode),
        message = NativeEditError.fromCode(nativeCode)?.description ??
            'Unknown native error (code: $nativeCode)';

  @override
  String toString() => 'NativeEditException: $message (code: $nativeCode)';
}

/// Exception thrown when an unsupported image format is detected.
///
/// This library only supports JPEG and PNG formats.
class UnsupportedImageFormatException implements Exception {
  /// The raw bytes that were passed.
  final Uint8List bytes;

  /// Human-readable message describing the error.
  final String message;

  UnsupportedImageFormatException({
    required this.bytes,
    this.message = 'Unsupported image format. Only JPEG and PNG are supported.',
  });

  @override
  String toString() => 'UnsupportedImageFormatException: $message';
}
