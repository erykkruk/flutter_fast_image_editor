# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-04-07

### Changed
- Updated installation docs to ^1.0.2

## [1.0.1] - 2026-04-07

### Changed
- Dart SDK constraint: `>=3.2.0 <4.0.0`
- Flutter constraint: `>=3.16.0`
- Android `compileSdk`: 33 → 35
- Android Gradle Plugin: 7.4.2 → 8.7.3
- iOS deployment target: 11.0 → 13.0
- `flutter_bicubic_resize` dependency: ^1.4.0 → ^1.5.0
- Modernized Gradle DSL

## [1.0.0] - 2026-03-13

### Added

- High-quality bicubic image resizing via `flutter_bicubic_resize`
  - `resize` / `resizeAsync` with configurable filter, edge mode, crop
  - Re-exported resize enums: `BicubicFilter`, `EdgeMode`, `CropAnchor`, `CropAspectRatio`
- Radial region effects (`RadialRegion`) — apply filters to circular areas

### Changed

- Promoted to stable 1.0.0 release

## [0.1.0] - 2025-01-01

### Added

- Initial release with 7 image filters:
  - `blur` — Box blur with Gaussian approximation (3 passes)
  - `sepia` — Sepia tone with adjustable intensity
  - `saturation` — Color saturation adjustment
  - `brightness` — Brightness adjustment
  - `contrast` — Contrast adjustment
  - `sharpen` — Unsharp mask sharpening
  - `grayscale` — Luminance-based grayscale conversion
- Region-based effects (apply filter to specific areas of the image)
- Sync and async (Isolate) variants for every filter
- JPEG and PNG support with automatic format detection
- Native C implementation via FFI for maximum performance
- iOS and Android platform support
