import 'dart:ffi';
import 'dart:io';

// ============================================================================
// C function signatures — Blur
// ============================================================================

typedef ImageEditBlurNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Int32 radius,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditBlurDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  int radius,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Sepia
// ============================================================================

typedef ImageEditSepiaNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float intensity,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditSepiaDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double intensity,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Saturation
// ============================================================================

typedef ImageEditSaturationNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float factor,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditSaturationDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double factor,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Brightness
// ============================================================================

typedef ImageEditBrightnessNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float factor,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditBrightnessDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double factor,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Contrast
// ============================================================================

typedef ImageEditContrastNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float factor,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditContrastDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double factor,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Sharpen
// ============================================================================

typedef ImageEditSharpenNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float amount,
  Int32 radius,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditSharpenDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double amount,
  int radius,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Grayscale
// ============================================================================

typedef ImageEditGrayscaleNative = Int32 Function(
  Pointer<Uint8> inputData,
  Int32 inputSize,
  Float regionTop,
  Float regionBottom,
  Float regionLeft,
  Float regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  Int32 quality,
);

typedef ImageEditGrayscaleDart = int Function(
  Pointer<Uint8> inputData,
  int inputSize,
  double regionTop,
  double regionBottom,
  double regionLeft,
  double regionRight,
  Pointer<Pointer<Uint8>> outputData,
  Pointer<Int32> outputSize,
  int quality,
);

// ============================================================================
// C function signatures — Memory management
// ============================================================================

typedef FreeBufferNative = Void Function(Pointer<Uint8> buffer);
typedef FreeBufferDart = void Function(Pointer<Uint8> buffer);

// ============================================================================
// Native bindings class
// ============================================================================

class NativeBindings {
  static NativeBindings? _instance;
  static NativeBindings get instance => _instance ??= NativeBindings._();

  late final DynamicLibrary _library;

  late final ImageEditBlurDart imageEditBlur;
  late final ImageEditSepiaDart imageEditSepia;
  late final ImageEditSaturationDart imageEditSaturation;
  late final ImageEditBrightnessDart imageEditBrightness;
  late final ImageEditContrastDart imageEditContrast;
  late final ImageEditSharpenDart imageEditSharpen;
  late final ImageEditGrayscaleDart imageEditGrayscale;
  late final FreeBufferDart freeBuffer;

  NativeBindings._() {
    _library = _loadLibrary();
    _bindFunctions();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libfast_image_editor.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.executable();
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libfast_image_editor.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('fast_image_editor.dll');
    } else {
      throw UnsupportedError(
          'Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  void _bindFunctions() {
    imageEditBlur = _library
        .lookup<NativeFunction<ImageEditBlurNative>>('image_edit_blur')
        .asFunction<ImageEditBlurDart>();

    imageEditSepia = _library
        .lookup<NativeFunction<ImageEditSepiaNative>>('image_edit_sepia')
        .asFunction<ImageEditSepiaDart>();

    imageEditSaturation = _library
        .lookup<NativeFunction<ImageEditSaturationNative>>(
            'image_edit_saturation')
        .asFunction<ImageEditSaturationDart>();

    imageEditBrightness = _library
        .lookup<NativeFunction<ImageEditBrightnessNative>>(
            'image_edit_brightness')
        .asFunction<ImageEditBrightnessDart>();

    imageEditContrast = _library
        .lookup<NativeFunction<ImageEditContrastNative>>('image_edit_contrast')
        .asFunction<ImageEditContrastDart>();

    imageEditSharpen = _library
        .lookup<NativeFunction<ImageEditSharpenNative>>('image_edit_sharpen')
        .asFunction<ImageEditSharpenDart>();

    imageEditGrayscale = _library
        .lookup<NativeFunction<ImageEditGrayscaleNative>>(
            'image_edit_grayscale')
        .asFunction<ImageEditGrayscaleDart>();

    freeBuffer = _library
        .lookup<NativeFunction<FreeBufferNative>>('free_buffer')
        .asFunction<FreeBufferDart>();
  }
}
