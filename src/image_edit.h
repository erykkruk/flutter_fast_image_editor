#ifndef FAST_IMAGE_EDITOR_H
#define FAST_IMAGE_EDITOR_H

#include <stdint.h>

#if defined(_WIN32)
#define FFI_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Error codes
// ============================================================================

#define EDIT_SUCCESS              0
#define EDIT_ERROR_NULL_INPUT    -1
#define EDIT_ERROR_INVALID_DIMS  -2
#define EDIT_ERROR_DECODE_FAILED -3
#define EDIT_ERROR_ALLOC_FAILED  -4
#define EDIT_ERROR_ENCODE_FAILED -5
#define EDIT_ERROR_INVALID_PARAM -6

// ============================================================================
// Region parameters (shared by all filters)
//
// Rect region: top/bottom/left/right (0.0-1.0 percentages from edges)
//   All 0.0 = full image
//
// Radial region: center_x/center_y use Alignment convention:
//   center_x: -1.0 = left edge, 0.0 = center, 1.0 = right edge
//   center_y: -1.0 = top edge, 0.0 = center, 1.0 = bottom edge
//   radial_radius: 0.0-1.0 as fraction of image min(width, height)
//   When radial_radius > 0, rect region params are ignored.
// ============================================================================

// Apply blur effect (box blur, 3 passes for Gaussian approximation)
FFI_EXPORT int image_edit_blur(
    const uint8_t* input_data,
    int input_size,
    int radius,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Apply sepia tone filter
// intensity: 0.0-1.0 (blend between original and sepia)
FFI_EXPORT int image_edit_sepia(
    const uint8_t* input_data,
    int input_size,
    float intensity,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Adjust color saturation
// factor: 0.0 = grayscale, 1.0 = original, 2.0 = double saturation
FFI_EXPORT int image_edit_saturation(
    const uint8_t* input_data,
    int input_size,
    float factor,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Adjust brightness
// factor: -1.0 to 1.0 (0.0 = no change)
FFI_EXPORT int image_edit_brightness(
    const uint8_t* input_data,
    int input_size,
    float factor,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Adjust contrast
// factor: 0.0 to 2.0 (1.0 = original)
FFI_EXPORT int image_edit_contrast(
    const uint8_t* input_data,
    int input_size,
    float factor,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Sharpen using unsharp mask
// amount: 0.0-5.0, radius: 1-10
FFI_EXPORT int image_edit_sharpen(
    const uint8_t* input_data,
    int input_size,
    float amount,
    int radius,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Convert to grayscale
FFI_EXPORT int image_edit_grayscale(
    const uint8_t* input_data,
    int input_size,
    float region_top,
    float region_bottom,
    float region_left,
    float region_right,
    float radial_cx,
    float radial_cy,
    float radial_radius,
    uint8_t** output_data,
    int* output_size,
    int quality
);

// Free native-allocated output buffer
FFI_EXPORT void free_buffer(uint8_t* buffer);

#ifdef __cplusplus
}
#endif

#endif
