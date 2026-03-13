# fast_image_editor

## Overview

Flutter FFI plugin do natywnej edycji obrazów w C. 7 filtrów (blur, sepia, saturation, brightness, contrast, sharpen, grayscale) z obsługą region-based effects.

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Language | Dart | >=3.0.0 |
| Framework | Flutter | >=3.0.0 |
| Native | C++ (stb_image) | - |
| FFI | dart:ffi + ffi package | ^2.1.0 |
| Platforms | iOS, Android | iOS 11+, Android 21+ |

## Development Commands

```bash
cd edit_images && flutter pub get          # Dependencies
cd edit_images && flutter analyze          # Static analysis
cd edit_images && dart format .            # Format
cd edit_images && flutter test             # Tests
```

## Directory Structure

```
edit_images/
├── lib/
│   ├── fast_image_editor.dart              # Barrel export
│   └── src/
│       ├── fast_image_editor_api.dart      # Main API class (FastImageEditor)
│       ├── native_bindings.dart            # FFI typedefs + DynamicLibrary
│       ├── enums.dart                      # ImageFormat, EditRegion
│       └── exceptions.dart                 # NativeEditException, NativeEditError
├── src/                                    # Native C code
│   ├── image_edit.h                        # FFI_EXPORT signatures + error codes
│   ├── image_edit.cpp                      # All filter implementations
│   ├── stb_image.h                         # Image decoder
│   └── stb_image_write.h                   # Image encoder
├── ios/
│   ├── Classes/FastImageEditorPlugin.swift  # Symbol retention
│   ├── src -> ../src                        # Symlink
│   └── fast_image_editor.podspec
├── android/
│   ├── CMakeLists.txt
│   ├── build.gradle
│   └── src/main/AndroidManifest.xml
├── test/
├── example/
└── pubspec.yaml
```

## Architecture Pattern

FFI Plugin Pattern (identyczny z BICUBIC_FLUTTER):
- Dart API (static methods) → FFI Bindings → Native C code
- Każdy filtr: decode (stb_image) → process → encode (stb_image_write)
- Region system: percentages od krawędzi (0.0-1.0)
- Async via Isolate.run

## Error Handling

- Native: error codes (EDIT_ERROR_*) zwracane jako int
- Dart: NativeEditException wraps native codes
- UnsupportedImageFormatException dla non-JPEG/PNG

## Anti-patterns

- NIE dodawaj print() — biblioteka rzuca exceptions
- NIE używaj dynamic — zawsze explicit types
- NIE modyfikuj stb_image.h/stb_image_write.h — to vendor headers
- NIE dodawaj Flutter dependency w natywnym kodzie C

## Best Practices

- Każdy nowy filtr: dodaj w image_edit.h + image_edit.cpp + native_bindings.dart + fast_image_editor_api.dart
- Zawsze dodaj sync + async wariant
- Region support w każdym filtrze
- Testy na enums, exceptions, format detection
