#ifndef _opensrc_ezdxt_h
#define _opensrc_ezdxt_h

#include <stdint.h>
#include <stdbool.h>


typedef uint16_t ezdxt_rgb565;

// Return 5-bit Red color channel from a 16-bit color.
// Maximum value is 31.
inline uint8_t ezdxt_rgb565_r(ezdxt_rgb565 a) {
    return (uint8_t)((a & 0xF800) >> 11);
}

// Return 6-bit Green color channel from a 16-bit color.
// Maximum value is 63.
inline uint8_t ezdxt_rgb565_g(ezdxt_rgb565 a) {
    return (uint8_t)((a & 0x07E0) >> 5);
}

// Return 5-bit Blue color channel from a 16-bit color.
// Maximum value is 31.
inline uint8_t ezdxt_rgb565_b(ezdxt_rgb565 a) {
    return (uint8_t)(a & 0x001F);
}

// Floating-point RGB color. All fields are in range 0 to 1 inclusive.
struct ezdxt_rgbf {
    float r, g, b;
};
typedef struct ezdxt_rgbf ezdxt_rgbf;

inline ezdxt_rgbf ezdxt_rgbf_from_565(ezdxt_rgb565 a) {
    return (ezdxt_rgbf) {
        .r = (float)ezdxt_rgb565_r(a) / 31,
        .g = (float)ezdxt_rgb565_g(a) / 63,
        .b = (float)ezdxt_rgb565_b(a) / 31,
    };
}

// Typical 24-bit RGB color.
struct ezdxt_rgb888 {
    uint8_t r, g, b;
};
typedef struct ezdxt_rgb888 ezdxt_rgb888;

inline ezdxt_rgb888 ezdxt_rgb888_from_565(ezdxt_rgb565 a) {
    const ezdxt_rgbf rgbf = ezdxt_rgbf_from_565(a);
    return (ezdxt_rgb888) {
        .r = (uint8_t)(rgbf.r * 255),
        .g = (uint8_t)(rgbf.g * 255),
        .b = (uint8_t)(rgbf.b * 255),
    };
}

// DXT1 pixels can be colorless. This is normally interpreted as full black
// or full transparent. `color` is an undefined  value if `has_color` is false.
struct ezdxt_dxt1pixel {
    ezdxt_rgb565 color;
    bool has_color;
};
typedef struct ezdxt_dxt1pixel ezdxt_dxt1pixel;

// A DXT encoded image. Which DXT mode? That can be inferred from context.
struct ezdxt_image {
    const void *data;
    uint16_t width, height;
};
typedef struct ezdxt_image ezdxt_image;

enum ezdxt_mode {
    EZDXT_MODE_DXT1,
    EZDXT_MODE_DXT1_ALPHA,
    EZDXT_MODE_DXT3,
    EZDXT_MODE_DXT5,
};
typedef enum ezdxt_mode ezdxt_mode;

/* return the pixel at X,Y in the DXT1 data given.
   `data` must point to 8 bytes of DXT1 data.
   `x` and `y` must be less than 4. */
ezdxt_dxt1pixel ezdxt_get_pixel_dxt1_chunk(
    const uint8_t *data,
    uint8_t x,
    uint8_t y
);

inline ezdxt_rgb565 ezdxt_get_pixel_dxt1_noalpha_chunk(
    const uint8_t *data,
    uint8_t x,
    uint8_t y
) {
    const ezdxt_dxt1pixel px = ezdxt_get_pixel_dxt1_chunk(data, x, y);
    if (px.has_color)
        return px.color;
    else
        return (ezdxt_rgb565)0;
}

/* return pixel at X,Y in the DXT1 image given.
   `data` must point to a valid DXT1 image.
   `x` and `y` must be within the image bounds. */
ezdxt_dxt1pixel ezdxt_get_pixel_dxt1(
    ezdxt_image image,
    uint16_t x,
    uint16_t y
);

inline ezdxt_rgb565 ezdxt_get_pixel_dxt1_noalpha(
    ezdxt_image image,
    uint16_t x,
    uint16_t y
) {
    const ezdxt_dxt1pixel px = ezdxt_get_pixel_dxt1(image, x, y);
    if (px.has_color)
        return px.color;
    else
        return (ezdxt_rgb565)0;
}

#endif
