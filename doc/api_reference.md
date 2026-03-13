# API Reference

## FastImageEditor

Main static class providing all image editing operations. Every filter has a **sync** and **async** (Isolate) variant.

All methods accept JPEG or PNG input and return the same format.

---

### Format Detection

#### `detectFormat`

```dart
static ImageFormat? detectFormat(Uint8List bytes)
```

Detects image format from raw bytes by checking magic bytes.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bytes` | `Uint8List` | Raw image data |

**Returns:** `ImageFormat.jpeg`, `ImageFormat.png`, or `null` if unrecognized.

---

### Filters

All filters share these common parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bytes` | `Uint8List` | required | JPEG or PNG image data |
| `region` | `EditRegion?` | `null` | Rectangular region. `null` = entire image |
| `radialRegion` | `RadialRegion?` | `null` | Circular region. When set, `region` is ignored |
| `quality` | `int` | `90` | JPEG output quality (1-100). Ignored for PNG |

---

#### `blur` / `blurAsync`

```dart
static Uint8List blur({
  required Uint8List bytes,
  int radius = 10,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> blurAsync({...})
```

Box blur with 3 passes for Gaussian approximation.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `radius` | `int` | `10` | >= 1 | Blur radius in pixels |

```dart
// Full image blur
final result = FastImageEditor.blur(bytes: imageBytes, radius: 15);

// Blur top 30%
final result = FastImageEditor.blur(
  bytes: imageBytes,
  radius: 20,
  region: const EditRegion(top: 0.3),
);

// Radial blur in center
final result = FastImageEditor.blur(
  bytes: imageBytes,
  radius: 25,
  radialRegion: const RadialRegion(centerX: 0.0, centerY: 0.0, radius: 0.3),
);
```

---

#### `sepia` / `sepiaAsync`

```dart
static Uint8List sepia({
  required Uint8List bytes,
  double intensity = 1.0,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> sepiaAsync({...})
```

Applies sepia tone using the standard sepia matrix, blended with the original image.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `intensity` | `double` | `1.0` | 0.0 - 1.0 | 0.0 = original, 1.0 = full sepia |

```dart
final result = FastImageEditor.sepia(bytes: imageBytes, intensity: 0.7);
```

---

#### `grayscale` / `grayscaleAsync`

```dart
static Uint8List grayscale({
  required Uint8List bytes,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> grayscaleAsync({...})
```

Converts to grayscale using luminance formula: `0.2126R + 0.7152G + 0.0722B`.

No additional parameters beyond the common ones.

```dart
final result = FastImageEditor.grayscale(bytes: imageBytes);
```

---

#### `brightness` / `brightnessAsync`

```dart
static Uint8List brightness({
  required Uint8List bytes,
  required double factor,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> brightnessAsync({...})
```

Adjusts brightness by adding `factor * 255` to each channel, clamped to 0-255.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `factor` | `double` | required | -1.0 to 1.0 | 0.0 = no change, positive = brighter, negative = darker |

```dart
// Brighten
final result = FastImageEditor.brightness(bytes: imageBytes, factor: 0.3);

// Darken
final result = FastImageEditor.brightness(bytes: imageBytes, factor: -0.2);
```

---

#### `contrast` / `contrastAsync`

```dart
static Uint8List contrast({
  required Uint8List bytes,
  required double factor,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> contrastAsync({...})
```

Adjusts contrast using the formula: `((pixel/255 - 0.5) * factor + 0.5) * 255`.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `factor` | `double` | required | 0.0 - 2.0 | 1.0 = original, < 1 = less contrast, > 1 = more contrast |

```dart
final result = FastImageEditor.contrast(bytes: imageBytes, factor: 1.5);
```

---

#### `sharpen` / `sharpenAsync`

```dart
static Uint8List sharpen({
  required Uint8List bytes,
  double amount = 1.0,
  int radius = 1,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> sharpenAsync({...})
```

Sharpens using unsharp mask: `result = original + amount * (original - blurred)`.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `amount` | `double` | `1.0` | 0.0 - 5.0 | Sharpening strength |
| `radius` | `int` | `1` | 1 - 10 | Blur radius for the unsharp mask |

```dart
final result = FastImageEditor.sharpen(bytes: imageBytes, amount: 2.0, radius: 2);
```

---

#### `saturation` / `saturationAsync`

```dart
static Uint8List saturation({
  required Uint8List bytes,
  required double factor,
  EditRegion? region,
  RadialRegion? radialRegion,
  int quality = 90,
})

static Future<Uint8List> saturationAsync({...})
```

Adjusts color saturation using luminance-based desaturation: `L = 0.2126R + 0.7152G + 0.0722B`.

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `factor` | `double` | required | >= 0.0 | 0.0 = grayscale, 1.0 = original, 2.0 = double saturation |

```dart
final result = FastImageEditor.saturation(bytes: imageBytes, factor: 2.0);
```

---

## EditRegion

Rectangular region defined by percentages from each edge. When all values are `0.0`, the effect applies to the entire image. Multiple edges can be combined.

```dart
const EditRegion({
  double top = 0.0,
  double bottom = 0.0,
  double left = 0.0,
  double right = 0.0,
})
```

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `top` | `double` | 0.0 - 1.0 | Percentage from the top edge |
| `bottom` | `double` | 0.0 - 1.0 | Percentage from the bottom edge |
| `left` | `double` | 0.0 - 1.0 | Percentage from the left edge |
| `right` | `double` | 0.0 - 1.0 | Percentage from the right edge |

### Static constants

| Constant | Description |
|----------|-------------|
| `EditRegion.full` | Applies effect to the entire image (all zeros) |

### Examples

```dart
// Blur top 30% and bottom 30%, leaving middle untouched
EditRegion(top: 0.3, bottom: 0.3)

// Apply effect to left half
EditRegion(left: 0.5)

// Apply effect to all edges (frame effect)
EditRegion(top: 0.1, bottom: 0.1, left: 0.1, right: 0.1)
```

### How regions work

```
top=0.3:
┌──────────────┐
│ ■■■■■■■■■■■■ │  ← effect applied (30%)
│ ■■■■■■■■■■■■ │
│              │
│              │  ← untouched (70%)
│              │
└──────────────┘

top=0.3, bottom=0.3:
┌──────────────┐
│ ■■■■■■■■■■■■ │  ← effect (30%)
│              │
│              │  ← untouched (40%)
│              │
│ ■■■■■■■■■■■■ │  ← effect (30%)
└──────────────┘

left=0.5:
┌──────────────┐
│ ■■■■■■│      │
│ ■■■■■■│      │
│ ■■■■■■│      │  ← left 50% affected
│ ■■■■■■│      │
│ ■■■■■■│      │
└──────────────┘
```

---

## RadialRegion

Circular region defined by a center point and radius. Uses **Alignment-style coordinates** where the center of the image is `(0, 0)`.

When a `RadialRegion` is provided, the `EditRegion` (rect) is ignored.

```dart
const RadialRegion({
  double centerX = 0.0,
  double centerY = 0.0,
  required double radius,
})
```

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `centerX` | `double` | -1.0 to 1.0 | Horizontal center. -1 = left edge, 0 = center, 1 = right edge |
| `centerY` | `double` | -1.0 to 1.0 | Vertical center. -1 = top edge, 0 = center, 1 = bottom edge |
| `radius` | `double` | 0.0 - 1.0 | Circle radius as fraction of `min(width, height)` |

### Coordinate system

```
centerX:  -1.0          0.0          1.0
           ┌─────────────┬─────────────┐
     -1.0  │ left-top    │  center-top │ right-top
           │             │             │
centerY:   │             │             │
      0.0  │ left-center │   CENTER    │ right-center
           │             │             │
           │             │             │
      1.0  │ left-bottom │center-bottom│ right-bottom
           └─────────────┴─────────────┘
```

### Examples

```dart
// Circle in the center of the image
RadialRegion(centerX: 0.0, centerY: 0.0, radius: 0.3)

// Circle in the top-left corner
RadialRegion(centerX: -1.0, centerY: -1.0, radius: 0.2)

// Circle shifted to the right
RadialRegion(centerX: 0.5, centerY: 0.0, radius: 0.25)
```

---

## Enums

### ImageFormat

```dart
enum ImageFormat { jpeg, png }
```

Detected by `FastImageEditor.detectFormat()` based on magic bytes:
- JPEG: `FF D8 FF`
- PNG: `89 50 4E 47`

---

## Exceptions

### NativeEditException

Thrown when a native C operation fails.

| Property | Type | Description |
|----------|------|-------------|
| `nativeCode` | `int` | Raw error code from C |
| `error` | `NativeEditError?` | Mapped enum, `null` if unrecognized |
| `message` | `String` | Human-readable description |

### NativeEditError

Enum mapping native error codes:

| Value | Code | Description |
|-------|------|-------------|
| `nullInput` | -1 | Null pointer passed to native function |
| `invalidDims` | -2 | Invalid dimensions (size <= 0) |
| `decodeFailed` | -3 | Image decoding failed (corrupt or unsupported data) |
| `allocFailed` | -4 | Memory allocation failed in native code |
| `encodeFailed` | -5 | Image encoding failed |
| `invalidParam` | -6 | Invalid parameter value |

### UnsupportedImageFormatException

Thrown when input bytes are not JPEG or PNG.

| Property | Type | Description |
|----------|------|-------------|
| `bytes` | `Uint8List` | The raw bytes that were passed |
| `message` | `String` | Error description |
