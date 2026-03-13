#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#define STBI_NO_PSD
#define STBI_NO_TGA
#define STBI_NO_GIF
#define STBI_NO_HDR
#define STBI_NO_PIC
#define STBI_NO_PNM

#include "stb_image.h"
#include "stb_image_write.h"
#include "image_edit.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

// ============================================================================
// WriteContext for stbi_write to memory
// ============================================================================

typedef struct {
    uint8_t* data;
    int size;
    int capacity;
} WriteContext;

static void write_func(void* context, void* data, int size) {
    WriteContext* ctx = (WriteContext*)context;
    while (ctx->size + size > ctx->capacity) {
        ctx->capacity = ctx->capacity * 2;
        ctx->data = (uint8_t*)realloc(ctx->data, ctx->capacity);
    }
    memcpy(ctx->data + ctx->size, data, size);
    ctx->size += size;
}

// ============================================================================
// Helper: clamp int to 0-255
// ============================================================================

static inline int clamp255(int v) {
    if (v < 0) return 0;
    if (v > 255) return 255;
    return v;
}

static inline float clampf(float v, float lo, float hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

// ============================================================================
// Helper: check if pixel is in region
// ============================================================================

static inline int in_region(int x, int y, int w, int h,
                            float region_top, float region_bottom,
                            float region_left, float region_right,
                            float radial_cx, float radial_cy,
                            float radial_radius) {
    // Radial mode: check if pixel is within circle
    if (radial_radius > 0.0f) {
        float min_dim = (float)(w < h ? w : h);
        float r_px = radial_radius * min_dim;

        // Convert Alignment coords (-1..1) to pixel coords
        float cx_px = (radial_cx + 1.0f) * 0.5f * (float)w;
        float cy_px = (radial_cy + 1.0f) * 0.5f * (float)h;

        float dx = (float)x - cx_px;
        float dy = (float)y - cy_px;
        return (dx * dx + dy * dy) <= (r_px * r_px);
    }

    // Rect mode: all zeros = full image
    if (region_top == 0.0f && region_bottom == 0.0f &&
        region_left == 0.0f && region_right == 0.0f) {
        return 1;
    }

    int top_limit = (int)(h * region_top);
    int bottom_start = h - (int)(h * region_bottom);
    int left_limit = (int)(w * region_left);
    int right_start = w - (int)(w * region_right);

    int in_top = (region_top > 0.0f && y < top_limit);
    int in_bottom = (region_bottom > 0.0f && y >= bottom_start);
    int in_left = (region_left > 0.0f && x < left_limit);
    int in_right = (region_right > 0.0f && x >= right_start);

    return in_top || in_bottom || in_left || in_right;
}

// ============================================================================
// EXIF Orientation parsing (JPEG only)
// ============================================================================

static int is_jpeg(const uint8_t* data, int size) {
    if (size < 3) return 0;
    return (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF);
}

static int parse_exif_orientation(const uint8_t* data, int size) {
    if (size < 12) return 1;
    if (data[0] != 0xFF || data[1] != 0xD8) return 1;

    int offset = 2;
    while (offset + 4 < size) {
        if (data[offset] != 0xFF) return 1;
        uint8_t marker = data[offset + 1];
        if (marker == 0xFF) { offset++; continue; }

        if (marker == 0xE1) {
            int segment_length = (data[offset + 2] << 8) | data[offset + 3];
            int segment_start = offset + 4;
            if (segment_start + 6 > size) return 1;
            if (data[segment_start] != 'E' || data[segment_start + 1] != 'x' ||
                data[segment_start + 2] != 'i' || data[segment_start + 3] != 'f' ||
                data[segment_start + 4] != 0 || data[segment_start + 5] != 0)
                return 1;

            int tiff_start = segment_start + 6;
            if (tiff_start + 8 > size) return 1;
            int little_endian = (data[tiff_start] == 'I' && data[tiff_start + 1] == 'I');
            int big_endian = (data[tiff_start] == 'M' && data[tiff_start + 1] == 'M');
            if (!little_endian && !big_endian) return 1;

            uint32_t ifd_offset;
            if (little_endian) {
                ifd_offset = data[tiff_start + 4] | (data[tiff_start + 5] << 8) |
                            (data[tiff_start + 6] << 16) | (data[tiff_start + 7] << 24);
            } else {
                ifd_offset = (data[tiff_start + 4] << 24) | (data[tiff_start + 5] << 16) |
                            (data[tiff_start + 6] << 8) | data[tiff_start + 7];
            }

            int ifd_start = tiff_start + ifd_offset;
            if (ifd_start + 2 > size) return 1;
            uint16_t num_entries;
            if (little_endian) {
                num_entries = data[ifd_start] | (data[ifd_start + 1] << 8);
            } else {
                num_entries = (data[ifd_start] << 8) | data[ifd_start + 1];
            }

            int entry_start = ifd_start + 2;
            for (int i = 0; i < num_entries; i++) {
                int entry_offset = entry_start + i * 12;
                if (entry_offset + 12 > size) return 1;
                uint16_t tag;
                if (little_endian) {
                    tag = data[entry_offset] | (data[entry_offset + 1] << 8);
                } else {
                    tag = (data[entry_offset] << 8) | data[entry_offset + 1];
                }
                if (tag == 0x0112) {
                    uint16_t orientation;
                    if (little_endian) {
                        orientation = data[entry_offset + 8] | (data[entry_offset + 9] << 8);
                    } else {
                        orientation = (data[entry_offset + 8] << 8) | data[entry_offset + 9];
                    }
                    return (orientation >= 1 && orientation <= 8) ? orientation : 1;
                }
            }
            return 1;
        }
        if (marker == 0xDA) return 1;
        int segment_length = (data[offset + 2] << 8) | data[offset + 3];
        offset += 2 + segment_length;
    }
    return 1;
}

static uint8_t* apply_orientation(uint8_t* pixels, int* width, int* height,
                                   int channels, int orientation) {
    if (orientation == 1) return pixels;
    int w = *width, h = *height;
    int new_w = w, new_h = h;
    if (orientation >= 5) { new_w = h; new_h = w; }

    uint8_t* result = (uint8_t*)malloc(new_w * new_h * channels);
    if (!result) return pixels;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int src_idx = (y * w + x) * channels;
            int dst_x, dst_y;
            switch (orientation) {
                case 2: dst_x = w - 1 - x; dst_y = y; break;
                case 3: dst_x = w - 1 - x; dst_y = h - 1 - y; break;
                case 4: dst_x = x; dst_y = h - 1 - y; break;
                case 5: dst_x = y; dst_y = x; break;
                case 6: dst_x = h - 1 - y; dst_y = x; break;
                case 7: dst_x = h - 1 - y; dst_y = w - 1 - x; break;
                case 8: dst_x = y; dst_y = w - 1 - x; break;
                default: dst_x = x; dst_y = y; break;
            }
            int dst_idx = (dst_y * new_w + dst_x) * channels;
            for (int c = 0; c < channels; c++) {
                result[dst_idx + c] = pixels[src_idx + c];
            }
        }
    }
    free(pixels);
    *width = new_w;
    *height = new_h;
    return result;
}

// ============================================================================
// Helper: decode image with EXIF orientation correction
// ============================================================================

static uint8_t* decode_image(const uint8_t* input_data, int input_size,
                              int* w, int* h, int* channels) {
    int jpeg = is_jpeg(input_data, input_size);
    int orientation = 1;
    if (jpeg) {
        orientation = parse_exif_orientation(input_data, input_size);
    }

    uint8_t* pixels = stbi_load_from_memory(
        input_data, input_size, w, h, channels, 0);
    if (pixels == NULL) return NULL;

    if (*channels != 3 && *channels != 4) {
        stbi_image_free(pixels);
        pixels = stbi_load_from_memory(
            input_data, input_size, w, h, channels, 3);
        if (pixels == NULL) return NULL;
        *channels = 3;
    }

    if (jpeg && orientation != 1) {
        pixels = apply_orientation(pixels, w, h, *channels, orientation);
    }

    return pixels;
}

// ============================================================================
// Helper: detect format and encode output
// ============================================================================

static int is_png(const uint8_t* data, int size) {
    if (size < 4) return 0;
    return (data[0] == 0x89 && data[1] == 0x50 &&
            data[2] == 0x4E && data[3] == 0x47);
}

static int encode_output(uint8_t* pixels, int w, int h, int channels,
                         int is_png_format, int quality,
                         uint8_t** output_data, int* output_size) {
    WriteContext ctx;
    ctx.capacity = w * h * channels;
    ctx.size = 0;
    ctx.data = (uint8_t*)malloc(ctx.capacity);
    if (ctx.data == NULL) return EDIT_ERROR_ALLOC_FAILED;

    int result;
    if (is_png_format) {
        result = stbi_write_png_to_func(
            write_func, &ctx, w, h, channels, pixels, w * channels);
    } else {
        if (quality < 1) quality = 1;
        if (quality > 100) quality = 100;
        result = stbi_write_jpg_to_func(
            write_func, &ctx, w, h, channels, pixels, quality);
    }

    if (result == 0) {
        free(ctx.data);
        return EDIT_ERROR_ENCODE_FAILED;
    }

    *output_data = (uint8_t*)realloc(ctx.data, ctx.size);
    *output_size = ctx.size;
    return EDIT_SUCCESS;
}

// ============================================================================
// Box blur implementation (single pass, horizontal + vertical)
// ============================================================================

static void box_blur_horizontal(uint8_t* src, uint8_t* dst, int w, int h,
                                int channels, int radius,
                                float region_top, float region_bottom,
                                float region_left, float region_right,
                                float radial_cx, float radial_cy,
                                float radial_radius) {
    for (int y = 0; y < h; y++) {
        // Running sum accumulators
        int sum[4] = {0, 0, 0, 0};
        int count = 0;

        // Initialize window for first pixel
        for (int kx = -radius; kx <= radius; kx++) {
            int sx = kx < 0 ? 0 : (kx >= w ? w - 1 : kx);
            int idx = (y * w + sx) * channels;
            for (int c = 0; c < channels; c++) {
                sum[c] += src[idx + c];
            }
            count++;
        }

        for (int x = 0; x < w; x++) {
            int dst_idx = (y * w + x) * channels;

            if (in_region(x, y, w, h, region_top, region_bottom,
                          region_left, region_right,
                          radial_cx, radial_cy, radial_radius)) {
                for (int c = 0; c < channels; c++) {
                    dst[dst_idx + c] = (uint8_t)(sum[c] / count);
                }
            } else {
                int src_idx = (y * w + x) * channels;
                for (int c = 0; c < channels; c++) {
                    dst[dst_idx + c] = src[src_idx + c];
                }
            }

            // Slide window: remove left pixel, add right pixel
            int remove_x = x - radius;
            int add_x = x + radius + 1;
            if (remove_x >= 0 && add_x < w) {
                int rem_idx = (y * w + remove_x) * channels;
                int add_idx = (y * w + add_x) * channels;
                for (int c = 0; c < channels; c++) {
                    sum[c] += src[add_idx + c] - src[rem_idx + c];
                }
            } else {
                // Recalculate for edge cases
                for (int c = 0; c < channels; c++) sum[c] = 0;
                count = 0;
                int nx = x + 1;
                for (int kx = nx - radius; kx <= nx + radius; kx++) {
                    int sx = kx < 0 ? 0 : (kx >= w ? w - 1 : kx);
                    int idx = (y * w + sx) * channels;
                    for (int c = 0; c < channels; c++) {
                        sum[c] += src[idx + c];
                    }
                    count++;
                }
            }
        }
    }
}

static void box_blur_vertical(uint8_t* src, uint8_t* dst, int w, int h,
                               int channels, int radius,
                               float region_top, float region_bottom,
                               float region_left, float region_right,
                               float radial_cx, float radial_cy,
                               float radial_radius) {
    for (int x = 0; x < w; x++) {
        int sum[4] = {0, 0, 0, 0};
        int count = 0;

        for (int ky = -radius; ky <= radius; ky++) {
            int sy = ky < 0 ? 0 : (ky >= h ? h - 1 : ky);
            int idx = (sy * w + x) * channels;
            for (int c = 0; c < channels; c++) {
                sum[c] += src[idx + c];
            }
            count++;
        }

        for (int y = 0; y < h; y++) {
            int dst_idx = (y * w + x) * channels;

            if (in_region(x, y, w, h, region_top, region_bottom,
                          region_left, region_right,
                          radial_cx, radial_cy, radial_radius)) {
                for (int c = 0; c < channels; c++) {
                    dst[dst_idx + c] = (uint8_t)(sum[c] / count);
                }
            } else {
                int src_idx = (y * w + x) * channels;
                for (int c = 0; c < channels; c++) {
                    dst[dst_idx + c] = src[src_idx + c];
                }
            }

            int remove_y = y - radius;
            int add_y = y + radius + 1;
            if (remove_y >= 0 && add_y < h) {
                int rem_idx = (remove_y * w + x) * channels;
                int add_idx = (add_y * w + x) * channels;
                for (int c = 0; c < channels; c++) {
                    sum[c] += src[add_idx + c] - src[rem_idx + c];
                }
            } else {
                for (int c = 0; c < channels; c++) sum[c] = 0;
                count = 0;
                int ny = y + 1;
                for (int ky = ny - radius; ky <= ny + radius; ky++) {
                    int sy = ky < 0 ? 0 : (ky >= h ? h - 1 : ky);
                    int idx = (sy * w + x) * channels;
                    for (int c = 0; c < channels; c++) {
                        sum[c] += src[idx + c];
                    }
                    count++;
                }
            }
        }
    }
}

// ============================================================================
// Blur filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;
    if (radius < 1) return EDIT_ERROR_INVALID_PARAM;

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    int pixel_count = w * h * channels;
    uint8_t* tmp = (uint8_t*)malloc(pixel_count);
    if (tmp == NULL) {
        stbi_image_free(pixels);
        return EDIT_ERROR_ALLOC_FAILED;
    }

    // 3 passes of box blur for Gaussian approximation
    for (int pass = 0; pass < 3; pass++) {
        box_blur_horizontal(pixels, tmp, w, h, channels, radius,
                            region_top, region_bottom, region_left, region_right,
                            radial_cx, radial_cy, radial_radius);
        box_blur_vertical(tmp, pixels, w, h, channels, radius,
                          region_top, region_bottom, region_left, region_right,
                          radial_cx, radial_cy, radial_radius);
    }

    free(tmp);

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Sepia filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;

    intensity = clampf(intensity, 0.0f, 1.0f);

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            int r = pixels[idx];
            int g = pixels[idx + 1];
            int b = pixels[idx + 2];

            int sr = clamp255((int)(0.393f * r + 0.769f * g + 0.189f * b));
            int sg = clamp255((int)(0.349f * r + 0.686f * g + 0.168f * b));
            int sb = clamp255((int)(0.272f * r + 0.534f * g + 0.131f * b));

            pixels[idx]     = (uint8_t)(r + (sr - r) * intensity);
            pixels[idx + 1] = (uint8_t)(g + (sg - g) * intensity);
            pixels[idx + 2] = (uint8_t)(b + (sb - b) * intensity);
        }
    }

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Saturation filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            float r = pixels[idx];
            float g = pixels[idx + 1];
            float b = pixels[idx + 2];

            float lum = 0.2126f * r + 0.7152f * g + 0.0722f * b;

            pixels[idx]     = (uint8_t)clamp255((int)(lum + factor * (r - lum)));
            pixels[idx + 1] = (uint8_t)clamp255((int)(lum + factor * (g - lum)));
            pixels[idx + 2] = (uint8_t)clamp255((int)(lum + factor * (b - lum)));
        }
    }

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Brightness filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;

    factor = clampf(factor, -1.0f, 1.0f);

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    int adjustment = (int)(factor * 255.0f);

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            pixels[idx]     = (uint8_t)clamp255(pixels[idx] + adjustment);
            pixels[idx + 1] = (uint8_t)clamp255(pixels[idx + 1] + adjustment);
            pixels[idx + 2] = (uint8_t)clamp255(pixels[idx + 2] + adjustment);
        }
    }

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Contrast filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            for (int c = 0; c < 3; c++) {
                float val = pixels[idx + c] / 255.0f;
                val = (val - 0.5f) * factor + 0.5f;
                pixels[idx + c] = (uint8_t)clamp255((int)(val * 255.0f));
            }
        }
    }

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Sharpen filter (unsharp mask)
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;
    if (radius < 1) radius = 1;
    if (radius > 10) radius = 10;

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    int pixel_count = w * h * channels;

    // Create blurred copy for unsharp mask
    uint8_t* blurred = (uint8_t*)malloc(pixel_count);
    uint8_t* tmp = (uint8_t*)malloc(pixel_count);
    if (blurred == NULL || tmp == NULL) {
        free(blurred);
        free(tmp);
        stbi_image_free(pixels);
        return EDIT_ERROR_ALLOC_FAILED;
    }

    memcpy(blurred, pixels, pixel_count);

    // Blur the copy (full image, region is applied only when compositing)
    for (int pass = 0; pass < 3; pass++) {
        box_blur_horizontal(blurred, tmp, w, h, channels, radius,
                            0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
        box_blur_vertical(tmp, blurred, w, h, channels, radius,
                          0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
    }

    free(tmp);

    // Unsharp mask: result = original + amount * (original - blurred)
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            for (int c = 0; c < 3; c++) {
                int diff = pixels[idx + c] - blurred[idx + c];
                int val = pixels[idx + c] + (int)(amount * diff);
                pixels[idx + c] = (uint8_t)clamp255(val);
            }
        }
    }

    free(blurred);

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Grayscale filter
// ============================================================================

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
) {
    if (input_data == NULL || output_data == NULL || output_size == NULL) {
        return EDIT_ERROR_NULL_INPUT;
    }
    if (input_size <= 0) return EDIT_ERROR_INVALID_DIMS;

    int png_format = is_png(input_data, input_size);
    int w, h, channels;
    uint8_t* pixels = decode_image(input_data, input_size, &w, &h, &channels);
    if (pixels == NULL) return EDIT_ERROR_DECODE_FAILED;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            if (!in_region(x, y, w, h, region_top, region_bottom,
                           region_left, region_right,
                           radial_cx, radial_cy, radial_radius)) continue;

            int idx = (y * w + x) * channels;
            float r = pixels[idx];
            float g = pixels[idx + 1];
            float b = pixels[idx + 2];

            uint8_t gray = (uint8_t)clamp255(
                (int)(0.2126f * r + 0.7152f * g + 0.0722f * b));

            pixels[idx]     = gray;
            pixels[idx + 1] = gray;
            pixels[idx + 2] = gray;
        }
    }

    int err = encode_output(pixels, w, h, channels, png_format, quality,
                            output_data, output_size);
    stbi_image_free(pixels);
    return err;
}

// ============================================================================
// Memory management
// ============================================================================

FFI_EXPORT void free_buffer(uint8_t* buffer) {
    if (buffer != NULL) {
        free(buffer);
    }
}
