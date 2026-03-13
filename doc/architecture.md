# Architecture

## Overview

`fast_image_editor` is a Flutter FFI plugin that processes images natively in C for maximum performance. The architecture follows a strict layered approach:

```
┌─────────────────────────────────────────────┐
│              User Code (Dart)               │
│         FastImageEditor.blur(...)           │
├─────────────────────────────────────────────┤
│           Public API Layer                  │
│     fast_image_editor_api.dart              │
│   - Static methods (sync + async)           │
│   - Parameter validation                    │
│   - Memory management (calloc/free)         │
├─────────────────────────────────────────────┤
│           FFI Bindings Layer                │
│        native_bindings.dart                 │
│   - DynamicLibrary loading                  │
│   - C function typedefs                     │
│   - Platform-specific library resolution    │
├─────────────────────────────────────────────┤
│          Native C Layer                     │
│           image_edit.cpp                    │
│   - stb_image decode                        │
│   - EXIF orientation correction             │
│   - Pixel processing (filters)              │
│   - Region/radial masking                   │
│   - stb_image_write encode                  │
└─────────────────────────────────────────────┘
```

---

## Data Flow

Every filter follows the same pipeline:

```
Input bytes (JPEG/PNG)
    │
    ▼
┌─────────────────────┐
│  Dart: allocate      │  calloc input buffer, copy bytes
│  native memory       │
├─────────────────────┤
│  C: decode_image()   │  stb_image + EXIF orientation fix
├─────────────────────┤
│  C: apply filter     │  per-pixel processing with region check
├─────────────────────┤
│  C: encode_output()  │  stb_image_write to malloc'd buffer
├─────────────────────┤
│  Dart: copy output   │  Uint8List.fromList(nativeBuffer)
│  free native memory  │  free_buffer() + calloc.free()
└─────────────────────┘
    │
    ▼
Output bytes (JPEG/PNG, same format as input)
```

---

## File Structure

```
lib/
├── fast_image_editor.dart          # Barrel export (library directive)
└── src/
    ├── fast_image_editor_api.dart  # FastImageEditor static class
    ├── native_bindings.dart        # FFI typedefs + DynamicLibrary
    ├── enums.dart                  # ImageFormat, EditRegion, RadialRegion
    └── exceptions.dart             # NativeEditException, NativeEditError

src/                                # Native C code
├── image_edit.h                    # Public C API (FFI_EXPORT functions)
├── image_edit.cpp                  # All filter implementations
├── stb_image.h                     # Vendor: image decoder (header-only)
└── stb_image_write.h               # Vendor: image encoder (header-only)

ios/
├── Classes/
│   └── FastImageEditorPlugin.swift # Symbol retention via dummy calls
├── src -> ../src                   # Symlink to shared native code
└── fast_image_editor.podspec       # CocoaPods build config

android/
├── CMakeLists.txt                  # CMake build for image_edit.cpp
├── build.gradle                    # Gradle config (minSdk 21)
└── src/main/AndroidManifest.xml
```

---

## Region System

### How `in_region()` works

Every pixel `(x, y)` is checked against the active region before the filter is applied. Pixels outside the region are copied unchanged.

```c
static inline int in_region(int x, int y, int w, int h,
                            float region_top, float region_bottom,
                            float region_left, float region_right,
                            float radial_cx, float radial_cy,
                            float radial_radius);
```

**Priority:** If `radial_radius > 0`, radial mode is used and rect params are ignored.

### Rect mode

Regions are defined as percentages from edges. They combine with OR logic:

- `top=0.3` → pixels where `y < h * 0.3`
- `bottom=0.3` → pixels where `y >= h * (1 - 0.3)`
- `left=0.5` → pixels where `x < w * 0.5`
- Combined: pixel is in region if it matches **any** edge condition

### Radial mode

Circle defined by Alignment-style center + radius:

```
pixel_cx = (radial_cx + 1) * 0.5 * width
pixel_cy = (radial_cy + 1) * 0.5 * height
radius_px = radial_radius * min(width, height)

in_circle = (dx² + dy²) <= radius_px²
```

---

## EXIF Orientation

JPEG files may contain EXIF orientation tags. Without handling, images appear rotated after decode/encode.

The `decode_image()` helper:

1. Checks if input is JPEG (magic bytes `FF D8 FF`)
2. Parses EXIF orientation tag (tag `0x0112`) from IFD0
3. Decodes with `stbi_load_from_memory`
4. Applies pixel rotation via `apply_orientation()` (supports orientations 1-8)

This ensures output images always have correct orientation regardless of EXIF metadata.

---

## Memory Management

### Native side

- `stbi_load_from_memory` → allocates pixel buffer (freed with `stbi_image_free`)
- `apply_orientation` → may allocate rotated buffer (freed, original freed)
- `encode_output` → `malloc` for WriteContext (returned to Dart, freed via `free_buffer`)
- Temporary buffers (blur tmp, sharpen blurred) → `malloc`/`free` within function

### Dart side

- `calloc<Uint8>(size)` → input buffer (freed in `finally` block)
- `calloc<Pointer<Uint8>>()` → output pointer (freed in `finally` block)
- `calloc<Int32>()` → output size (freed in `finally` block)
- `NativeBindings.instance.freeBuffer(outputData)` → frees the native output buffer
- `Uint8List.fromList(...)` → copies data to Dart-managed memory

All allocations are wrapped in `try/finally` to prevent leaks.

---

## Async Pattern

Every filter has an async variant that wraps the sync version in `Isolate.run`:

```dart
static Future<Uint8List> blurAsync({...}) {
  return Isolate.run(
    () => blur(bytes: bytes, radius: radius, ...),
  );
}
```

This moves the entire operation (FFI call + native processing) to a separate isolate, keeping the UI thread responsive for large images.

---

## Platform Build

### Android

CMake compiles `image_edit.cpp` into `libfast_image_editor.so`:

```cmake
add_library(fast_image_editor SHARED "../src/image_edit.cpp")
target_include_directories(fast_image_editor PRIVATE "../src")
```

Loaded at runtime: `DynamicLibrary.open('libfast_image_editor.so')`

### iOS

CocoaPods compiles `src/*.cpp` via the podspec. The Swift plugin class calls each C function once (with dummy data) to prevent the linker from stripping symbols:

```swift
_ = image_edit_blur(&dummyInput, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
```

Loaded at runtime: `DynamicLibrary.executable()` (symbols are in the main executable)
