# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
