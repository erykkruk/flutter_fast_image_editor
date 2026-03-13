# Native C API Reference

Low-level C functions exported via FFI. These are called by the Dart bindings — you typically interact with the Dart `FastImageEditor` class instead.

## Header: `image_edit.h`

---

## Error Codes

| Constant | Value | Description |
|----------|-------|-------------|
| `EDIT_SUCCESS` | 0 | Operation completed successfully |
| `EDIT_ERROR_NULL_INPUT` | -1 | Null pointer passed as input, output, or size |
| `EDIT_ERROR_INVALID_DIMS` | -2 | Invalid dimensions (input_size <= 0) |
| `EDIT_ERROR_DECODE_FAILED` | -3 | stb_image could not decode the input |
| `EDIT_ERROR_ALLOC_FAILED` | -4 | `malloc` returned NULL |
| `EDIT_ERROR_ENCODE_FAILED` | -5 | stb_image_write failed to encode output |
| `EDIT_ERROR_INVALID_PARAM` | -6 | Invalid parameter (e.g. blur radius < 1) |

---

## Common Parameters

All filter functions share these parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `input_data` | `const uint8_t*` | Raw JPEG or PNG bytes |
| `input_size` | `int` | Size of input_data in bytes |
| `region_top` | `float` | Rect region: percentage from top (0.0-1.0) |
| `region_bottom` | `float` | Rect region: percentage from bottom (0.0-1.0) |
| `region_left` | `float` | Rect region: percentage from left (0.0-1.0) |
| `region_right` | `float` | Rect region: percentage from right (0.0-1.0) |
| `radial_cx` | `float` | Radial center X: -1.0 (left) to 1.0 (right) |
| `radial_cy` | `float` | Radial center Y: -1.0 (top) to 1.0 (bottom) |
| `radial_radius` | `float` | Radial radius: 0.0-1.0 as fraction of min(w,h). When > 0, rect params are ignored |
| `output_data` | `uint8_t**` | Pointer to receive allocated output buffer |
| `output_size` | `int*` | Pointer to receive output buffer size |
| `quality` | `int` | JPEG quality (1-100). Ignored for PNG input |

**Return:** `int` — `EDIT_SUCCESS` (0) on success, negative error code on failure.

**Memory:** The caller must free `*output_data` using `free_buffer()`.

---

## Functions

### `image_edit_blur`

```c
int image_edit_blur(
    const uint8_t* input_data, int input_size,
    int radius,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Box blur with 3 passes (Gaussian approximation). `radius` must be >= 1.

---

### `image_edit_sepia`

```c
int image_edit_sepia(
    const uint8_t* input_data, int input_size,
    float intensity,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Sepia tone filter. `intensity` (0.0-1.0) blends between original and sepia.

Sepia matrix:
```
R' = 0.393*R + 0.769*G + 0.189*B
G' = 0.349*R + 0.686*G + 0.168*B
B' = 0.272*R + 0.534*G + 0.131*B
```

---

### `image_edit_saturation`

```c
int image_edit_saturation(
    const uint8_t* input_data, int input_size,
    float factor,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Adjusts saturation. `factor`: 0.0 = grayscale, 1.0 = original, 2.0 = double.

Uses luminance: `L = 0.2126*R + 0.7152*G + 0.0722*B`

---

### `image_edit_brightness`

```c
int image_edit_brightness(
    const uint8_t* input_data, int input_size,
    float factor,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Adjusts brightness. `factor` (-1.0 to 1.0): `pixel + factor * 255`, clamped to 0-255.

---

### `image_edit_contrast`

```c
int image_edit_contrast(
    const uint8_t* input_data, int input_size,
    float factor,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Adjusts contrast. `factor` (0.0-2.0, 1.0 = original): `((pixel/255 - 0.5) * factor + 0.5) * 255`.

---

### `image_edit_sharpen`

```c
int image_edit_sharpen(
    const uint8_t* input_data, int input_size,
    float amount, int radius,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Unsharp mask sharpening. `amount` (0.0-5.0), `radius` (1-10).

Formula: `result = original + amount * (original - blurred)`

---

### `image_edit_grayscale`

```c
int image_edit_grayscale(
    const uint8_t* input_data, int input_size,
    float region_top, float region_bottom, float region_left, float region_right,
    float radial_cx, float radial_cy, float radial_radius,
    uint8_t** output_data, int* output_size,
    int quality
);
```

Converts to grayscale using luminance: `0.2126*R + 0.7152*G + 0.0722*B`.

---

### `free_buffer`

```c
void free_buffer(uint8_t* buffer);
```

Frees a buffer allocated by any filter function. Must be called on `*output_data` after copying the result.
