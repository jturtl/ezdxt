#ifndef _ezdxt_h
#define _ezdxt_h

#include <stdint.h>
#include <stdbool.h>

#define alias(s) typedef struct s s;

struct ezdxt_image {
    const uint8_t *data;
    uint16_t width;
    uint16_t height;
};
alias(ezdxt_image)

struct ezdxt_color {
    float r, g, b, a;
};
alias(ezdxt_color)

ezdxt_color ezdxt1_get_pixel(ezdxt_image, uint16_t x, uint16_t y);
ezdxt_color ezdxt1_get_pixel_chunk(const uint8_t *data, uint8_t x, uint8_t y);

// Same result as `ezdxt1_get_pixel`, but converts transparent pixels
// to solid black, per DXT1 standard
inline ezdxt_color ezdxt1_get_pixel_noalpha(ezdxt_image img, uint16_t x, uint16_t y) {
    ezdxt_color px = ezdxt1_get_pixel(img, x, y);
    if (px.a == 0) {
        px.a = 1;
        px.r = px.g = px.b = 0;
    }
    return px;
}

inline ezdxt_color ezdxt1_get_pixel_chunk_noalpha(const uint8_t *data, uint16_t x, uint16_t y) {
    ezdxt_color px = ezdxt1_get_pixel_chunk(data, x, y);
    if (px.a == 0) {
        px.a = 1;
        px.r = px.g = px.b = 0;
    }
    return px;
}

ezdxt_color ezdxt3_get_pixel(ezdxt_image, uint16_t x, uint16_t y);
ezdxt_color ezdxt3_get_pixel_chunk(const uint8_t *data, uint8_t x, uint8_t y);

ezdxt_color ezdxt5_get_pixel(ezdxt_image, uint16_t x, uint16_t y);
ezdxt_color ezdxt5_get_pixel_chunk(const uint8_t *data, uint8_t x, uint8_t y);

#undef alias

#endif
