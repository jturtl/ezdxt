#ifndef _opensrc_ezdxt_hpp
#define _opensrc_ezdxt_hpp

#include <cstdint>
#include <optional>

namespace ezdxt {
    struct Rgb565;
    struct Rgbf {
        float r, g, b;
        static Rgbf from_rgb565(Rgb565);
    };

    struct Rgb565 {
        uint16_t data;

        static Rgb565 from_int(uint16_t data) {
            return Rgb565 {
                .data = data,
            };
        }

        uint8_t r() const {
            return uint8_t((data & 0xF800) >> 11);
        }
        uint8_t g() const {
            return uint8_t((data & 0x07E0) >> 5);
        }
        uint8_t b() const {
            return uint8_t(data & 0x001F);
        }

    };

    struct Rgb888 {
        uint8_t r, g, b;

        Rgb888() : r(0), g(0), b(0) {}

        static Rgb888 from_rgbf(Rgbf rgbf) {
            Rgb888 me;
            me.r = (uint8_t)(rgbf.r * 255);
            me.g = (uint8_t)(rgbf.g * 255);
            me.b = (uint8_t)(rgbf.b * 255);
            return me;
        }

        static Rgb888 from_rgb565(Rgb565 rgb) {
            const auto rgbf = Rgbf::from_rgb565(rgb);
            return from_rgbf(rgbf);
        }
    };

    // very reasonable place to put this function
    // for a very reasonable language like C++
    Rgbf Rgbf::from_rgb565(Rgb565 rgb) {
        Rgbf me;
        me.r = (float)rgb.r() / 31;
        me.g = (float)rgb.g() / 63;
        me.b = (float)rgb.b() / 31;
        return me;
    }


    struct Image {
        const void *data;
        uint16_t width, height;
    };

    struct Dxt1Pixel {
        Rgb565 color;
        bool has_color;
    };
}

extern "C" {
    ezdxt::Dxt1Pixel ezdxt_get_pixel_dxt1(ezdxt::Image,uint16_t,uint16_t);
    ezdxt::Dxt1Pixel ezdxt_get_pixel_dxt1_chunk(const uint8_t*,uint8_t,uint8_t);
}

namespace ezdxt {
    // What a journey, the pixel goes from a Zig optional to a C struct to a C++ optional
    inline std::optional<Rgb565> get_pixel_dxt1(Image image, uint16_t x, uint16_t y) {
        const Dxt1Pixel px = ezdxt_get_pixel_dxt1(image, x, y);
        if (px.has_color)
            return px.color;
        else
            return std::nullopt;
    }

    inline std::optional<Rgb565> get_pixel_dxt1_chunk(const uint8_t *data, uint8_t x, uint8_t y) {
        const Dxt1Pixel px = ezdxt_get_pixel_dxt1_chunk(data, x, y);
        if (px.has_color)
            return px.color;
        else
            return std::nullopt;
    }

    inline Rgb565 get_pixel_dxt1_noalpha(Image image, uint16_t x, uint16_t y) {
        const Dxt1Pixel px = ezdxt_get_pixel_dxt1(image, x, y);
        if (px.has_color)
            return px.color;
        else
            return Rgb565::from_int(0);
    }

    inline Rgb565 get_pixel_dxt1_chunk_noalpha(const uint8_t *data, uint8_t x, uint8_t y) {
        const Dxt1Pixel px = ezdxt_get_pixel_dxt1_chunk(data, x, y);
        if (px.has_color)
            return px.color;
        else
            return Rgb565::from_int(0);
    }
}

#endif
