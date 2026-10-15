// Host-side regression tests for the native layer. The Dart tests cannot load
// the FFI library on the CI host, so these call src/image_edit.cpp directly.
//
// Build and run from the package root (same flags as CI):
//   g++ -std=c++11 -g -w -fsanitize=address,undefined -fno-sanitize=shift \
//     -fno-sanitize-recover=all -Isrc \
//     test/native/image_edit_native_test.cpp src/image_edit.cpp -o native_test
//   ./native_test

#include "image_edit.h"
#include "stb_image.h"
#include "stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vector>

static const int BLUR_PASSES = 3;
static const int CHANNELS = 3;
static const int JPEG_QUALITY = 90;
static const int EXIF_ORIENTATION_ROTATE_90 = 6;
static const uint32_t HUGE_IFD_OFFSET = 0xFFFFFFF0u;

static int failures = 0;

#define EXPECT(cond, msg)                                         \
    do {                                                          \
        if (!(cond)) {                                            \
            fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, \
                    msg);                                         \
            failures++;                                           \
        }                                                         \
    } while (0)

static void append_bytes(void* context, void* data, int size) {
    std::vector<uint8_t>* out = (std::vector<uint8_t>*)context;
    const uint8_t* bytes = (const uint8_t*)data;
    out->insert(out->end(), bytes, bytes + size);
}

static std::vector<uint8_t> make_pixels(int w, int h) {
    std::vector<uint8_t> pixels(w * h * CHANNELS);
    unsigned int seed = 12345u;
    for (size_t i = 0; i < pixels.size(); i++) {
        seed = seed * 1103515245u + 12345u;
        pixels[i] = (uint8_t)(seed >> 16);
    }
    return pixels;
}

static std::vector<uint8_t> encode_png(const std::vector<uint8_t>& pixels,
                                       int w, int h) {
    std::vector<uint8_t> out;
    stbi_write_png_to_func(append_bytes, &out, w, h, CHANNELS, pixels.data(),
                           w * CHANNELS);
    return out;
}

static std::vector<uint8_t> encode_jpeg(const std::vector<uint8_t>& pixels,
                                        int w, int h) {
    std::vector<uint8_t> out;
    stbi_write_jpg_to_func(append_bytes, &out, w, h, CHANNELS, pixels.data(),
                           JPEG_QUALITY);
    return out;
}

// Inserts a big-endian APP1/Exif segment right after SOI. The IFD holds one
// Orientation entry, and ifd_offset is written as given so tests can point it
// anywhere.
static std::vector<uint8_t> with_exif(const std::vector<uint8_t>& jpeg,
                                      uint32_t ifd_offset,
                                      uint16_t orientation) {
    std::vector<uint8_t> tiff = {
        'M', 'M', 0x00, 0x2A,
        (uint8_t)(ifd_offset >> 24), (uint8_t)(ifd_offset >> 16),
        (uint8_t)(ifd_offset >> 8), (uint8_t)ifd_offset,
        0x00, 0x01,                                      // 1 entry
        0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01,  // Orientation, SHORT
        (uint8_t)(orientation >> 8), (uint8_t)orientation, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,                          // next IFD
    };
    std::vector<uint8_t> payload = {'E', 'x', 'i', 'f', 0x00, 0x00};
    payload.insert(payload.end(), tiff.begin(), tiff.end());
    int segment_length = (int)payload.size() + 2;

    std::vector<uint8_t> out(jpeg.begin(), jpeg.begin() + 2);
    out.push_back(0xFF);
    out.push_back(0xE1);
    out.push_back((uint8_t)(segment_length >> 8));
    out.push_back((uint8_t)segment_length);
    out.insert(out.end(), payload.begin(), payload.end());
    out.insert(out.end(), jpeg.begin() + 2, jpeg.end());
    return out;
}

static int clamp_index(int i, int n) {
    return i < 0 ? 0 : (i >= n ? n - 1 : i);
}

// Straightforward re-summing box blur: the definition the optimized sliding
// window in image_edit.cpp must match exactly.
static void reference_blur(std::vector<uint8_t>& pixels, int w, int h,
                           int radius) {
    std::vector<uint8_t> tmp(pixels.size());
    int count = 2 * radius + 1;
    for (int pass = 0; pass < BLUR_PASSES; pass++) {
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                for (int c = 0; c < CHANNELS; c++) {
                    int sum = 0;
                    for (int k = -radius; k <= radius; k++) {
                        sum += pixels[(y * w + clamp_index(x + k, w)) *
                                      CHANNELS + c];
                    }
                    tmp[(y * w + x) * CHANNELS + c] = (uint8_t)(sum / count);
                }
            }
        }
        for (int x = 0; x < w; x++) {
            for (int y = 0; y < h; y++) {
                for (int c = 0; c < CHANNELS; c++) {
                    int sum = 0;
                    for (int k = -radius; k <= radius; k++) {
                        sum += tmp[(clamp_index(y + k, h) * w + x) *
                                   CHANNELS + c];
                    }
                    pixels[(y * w + x) * CHANNELS + c] =
                        (uint8_t)(sum / count);
                }
            }
        }
    }
}

static std::vector<uint8_t> decode(const uint8_t* data, int size, int* w,
                                   int* h) {
    int channels = 0;
    uint8_t* pixels =
        stbi_load_from_memory(data, size, w, h, &channels, CHANNELS);
    std::vector<uint8_t> out;
    if (pixels != NULL) {
        out.assign(pixels, pixels + (*w) * (*h) * CHANNELS);
        stbi_image_free(pixels);
    }
    return out;
}

static std::vector<uint8_t> run_blur(const std::vector<uint8_t>& png,
                                     int radius, float region_top, int* w,
                                     int* h) {
    uint8_t* output = NULL;
    int output_size = 0;
    int result = image_edit_blur(png.data(), (int)png.size(), radius,
                                 region_top, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
                                 0.0f, &output, &output_size, JPEG_QUALITY);
    EXPECT(result == EDIT_SUCCESS, "blur returns success");
    std::vector<uint8_t> pixels;
    if (result == EDIT_SUCCESS) {
        pixels = decode(output, output_size, w, h);
        free_buffer(output);
    }
    return pixels;
}

static void test_blur_matches_reference(int w, int h, int radius) {
    // Arrange
    std::vector<uint8_t> original = make_pixels(w, h);
    std::vector<uint8_t> expected = original;
    reference_blur(expected, w, h, radius);

    // Act
    int out_w = 0, out_h = 0;
    std::vector<uint8_t> actual =
        run_blur(encode_png(original, w, h), radius, 0.0f, &out_w, &out_h);

    // Assert
    EXPECT(out_w == w && out_h == h, "blur keeps dimensions");
    EXPECT(actual == expected, "blur matches the re-summing reference");
}

static void test_blur_region_leaves_rest_untouched() {
    // Arrange
    const int w = 20, h = 20, radius = 30;
    std::vector<uint8_t> original = make_pixels(w, h);

    // Act
    int out_w = 0, out_h = 0;
    std::vector<uint8_t> actual =
        run_blur(encode_png(original, w, h), radius, 0.5f, &out_w, &out_h);

    // Assert
    size_t half = (size_t)(h / 2) * w * CHANNELS;
    EXPECT(actual.size() == original.size(), "region blur keeps size");
    EXPECT(actual.size() == original.size() &&
               memcmp(actual.data() + half, original.data() + half,
                      original.size() - half) == 0,
           "pixels outside the region are unchanged");
}

static int run_grayscale(const std::vector<uint8_t>& jpeg, int* w, int* h) {
    uint8_t* output = NULL;
    int output_size = 0;
    int result = image_edit_grayscale(jpeg.data(), (int)jpeg.size(), 0.0f,
                                      0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
                                      &output, &output_size, JPEG_QUALITY);
    if (result == EDIT_SUCCESS) {
        decode(output, output_size, w, h);
        free_buffer(output);
    }
    return result;
}

static void test_exif_huge_ifd_offset_is_ignored() {
    // Arrange: before the fix this offset wrapped ifd_start negative and the
    // parser read before the input buffer (ASan reports it).
    const int w = 16, h = 8;
    std::vector<uint8_t> jpeg = with_exif(
        encode_jpeg(make_pixels(w, h), w, h), HUGE_IFD_OFFSET,
        EXIF_ORIENTATION_ROTATE_90);

    // Act
    int out_w = 0, out_h = 0;
    int result = run_grayscale(jpeg, &out_w, &out_h);

    // Assert
    EXPECT(result == EDIT_SUCCESS, "malformed EXIF still decodes");
    EXPECT(out_w == w && out_h == h, "malformed EXIF is treated as upright");
}

static void test_exif_valid_orientation_still_applies() {
    // Arrange: IFD right after the 8-byte TIFF header.
    const int w = 16, h = 8;
    std::vector<uint8_t> jpeg = with_exif(
        encode_jpeg(make_pixels(w, h), w, h), 8, EXIF_ORIENTATION_ROTATE_90);

    // Act
    int out_w = 0, out_h = 0;
    int result = run_grayscale(jpeg, &out_w, &out_h);

    // Assert
    EXPECT(result == EDIT_SUCCESS, "valid EXIF decodes");
    EXPECT(out_w == h && out_h == w, "orientation 6 swaps width and height");
}

int main() {
    test_blur_matches_reference(17, 11, 1);
    test_blur_matches_reference(17, 11, 4);
    test_blur_matches_reference(17, 11, 50);
    test_blur_region_leaves_rest_untouched();
    test_exif_huge_ifd_offset_is_ignored();
    test_exif_valid_orientation_still_applies();

    if (failures > 0) {
        fprintf(stderr, "%d native check(s) failed\n", failures);
        return 1;
    }
    printf("All native checks passed\n");
    return 0;
}
