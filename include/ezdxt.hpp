#ifndef _ezdxt_hpp
#define _ezdxt_hpp

#include <cstdint>
#include <optional>

namespace ezdxt {
    struct Color {
        float r, g, b, a;
    };

    struct Image {
        const uint8_t *data;
        uint16_t width;
        uint16_t height;
    };

}

extern "C" {
    ezdxt::Color ezdxt1_get_pixel(ezdxt::Image, uint16_t x, uint16_t y);
    ezdxt::Color ezdxt1_get_pixel_chunk(const uint8_t *data, uint8_t x, uint8_t y);
    ezdxt::Color ezdxt3_get_pixel(ezdxt::Image, uint16_t x, uint16_t y);
    ezdxt::Color ezdxt3_get_pixel_chunk(const uint8_t *data, uint8_t x, uint8_t y);
}

namespace ezdxt {
    namespace dxt1 {
        inline ezdxt::Color get_pixel(ezdxt::Image img, uint16_t x, uint16_t y) {
            return ezdxt1_get_pixel(img, x, y);
        }
        inline ezdxt::Color get_pixel_chunk(const uint8_t *data, uint16_t x, uint16_t y) {
            return ezdxt1_get_pixel_chunk(data, x, y);
        }
        inline ezdxt::Color get_pixel_noalpha(ezdxt::Image img, uint16_t x, uint16_t y) {
            auto px = get_pixel(img, x, y);
            if (px.a == 0) {
                px.a = 1;
                px.r = px.g = px.b = 0;
            }
            return px;
        }
        inline ezdxt::Color get_pixel_chunk_noalpha(const uint8_t *data, uint16_t x, uint16_t y) {
            auto px = get_pixel_chunk(data, x, y);
            if (px.a == 0) {
                px.a = 1;
                px.r = px.g = px.b = 0;
            }
            return px;
        }
    }

    namespace dxt3 {
        inline ezdxt::Color get_pixel(ezdxt::Image img, uint16_t x, uint16_t y) {
            return ezdxt3_get_pixel(img, x, y);
        }
        inline ezdxt::Color get_pixel_chunk(const uint8_t *data, uint16_t x, uint16_t y) {
            return ezdxt3_get_pixel_chunk(data, x, y);
        }
    }
}

#endif
