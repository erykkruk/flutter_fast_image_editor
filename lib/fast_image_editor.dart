/// Native image editing for Flutter with region-based effects.
///
/// This library provides high-performance native C image editing operations
/// via Dart FFI. All processing runs in native code for maximum performance.
///
/// ## Features
///
/// - 7 image filters: blur, sepia, saturation, brightness, contrast, sharpen, grayscale
/// - Region-based effects (e.g., blur only top 30% of image)
/// - High-quality bicubic image resizing (via flutter_bicubic_resize)
/// - Sync and async (Isolate) variants for every operation
/// - JPEG and PNG support with automatic format detection
///
/// ## Quick Start
///
/// ```dart
/// import 'package:fast_image_editor/fast_image_editor.dart';
///
/// // Apply blur to entire image
/// final blurred = FastImageEditor.blur(bytes: imageBytes, radius: 15);
///
/// // Apply sepia only to top 30% and bottom 30%
/// final sepia = FastImageEditor.sepia(
///   bytes: imageBytes,
///   intensity: 0.8,
///   region: EditRegion(top: 0.3, bottom: 0.3),
/// );
///
/// // Resize image with bicubic interpolation
/// final resized = FastImageEditor.resize(
///   bytes: imageBytes,
///   outputWidth: 800,
///   outputHeight: 600,
/// );
/// ```
library fast_image_editor;

export 'src/enums.dart';
export 'src/exceptions.dart';
export 'src/fast_image_editor_api.dart';

// Re-export bicubic resize enums for convenience
export 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart'
    show BicubicFilter, EdgeMode, CropAnchor, CropAspectRatio;
