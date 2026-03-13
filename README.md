# fast_image_editor

Native C image editing for Flutter. Blur, sepia, saturation, brightness, contrast, sharpen, grayscale — all with **region-based effects** via Dart FFI.

## Features

- **7 image filters**: blur, sepia, saturation, brightness, contrast, sharpen, grayscale
- **Region-based effects**: apply filters to specific areas (e.g., blur only top 30%)
- **Native performance**: all processing in C via FFI — no Dart pixel loops
- **Sync & async**: every filter has a sync and `Isolate.run` async variant
- **Format support**: JPEG and PNG with automatic detection

## Installation

```yaml
dependencies:
  fast_image_editor: ^0.1.0
```

## Quick Start

```dart
import 'package:fast_image_editor/fast_image_editor.dart';

// Blur entire image
final blurred = FastImageEditor.blur(bytes: imageBytes, radius: 15);

// Sepia on top 30% and bottom 30%
final sepia = FastImageEditor.sepia(
  bytes: imageBytes,
  intensity: 0.8,
  region: EditRegion(top: 0.3, bottom: 0.3),
);

// Async variant (runs in isolate)
final result = await FastImageEditor.blurAsync(bytes: imageBytes, radius: 10);
```

## API

### Filters

| Method | Parameters | Description |
|--------|-----------|-------------|
| `blur` | `radius` (1+) | Box blur, 3 passes for Gaussian approximation |
| `sepia` | `intensity` (0.0-1.0) | Sepia tone filter |
| `saturation` | `factor` (0.0=gray, 1.0=original, 2.0=double) | Color saturation |
| `brightness` | `factor` (-1.0 to 1.0) | Brightness adjustment |
| `contrast` | `factor` (0.0-2.0, 1.0=original) | Contrast adjustment |
| `sharpen` | `amount` (0.0-5.0), `radius` (1-10) | Unsharp mask |
| `grayscale` | — | Luminance: 0.2126R + 0.7152G + 0.0722B |

Every method has an async variant (e.g., `blurAsync`, `sepiaAsync`).

### Region-Based Effects

```dart
// Blur top 30% only
FastImageEditor.blur(
  bytes: imageBytes,
  radius: 20,
  region: EditRegion(top: 0.3),
);

// Grayscale left half
FastImageEditor.grayscale(
  bytes: imageBytes,
  region: EditRegion(left: 0.5),
);

// Sepia on edges (top 20% + bottom 20% + left 10% + right 10%)
FastImageEditor.sepia(
  bytes: imageBytes,
  region: EditRegion(top: 0.2, bottom: 0.2, left: 0.1, right: 0.1),
);
```

### Format Detection

```dart
final format = FastImageEditor.detectFormat(bytes);
// Returns ImageFormat.jpeg, ImageFormat.png, or null
```

## Common Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `bytes` | required | JPEG or PNG image data |
| `region` | `null` (full image) | Area to apply effect |
| `quality` | `90` | JPEG output quality (1-100). Ignored for PNG. |

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android | ✅ |
| iOS | ✅ |

## License

MIT License. See [LICENSE](LICENSE).
