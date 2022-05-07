#include <iostream>
#include <fstream>
#include "ezdxt.hpp"
#include "loss_dxt1.h"

int main() {
    ezdxt::Image img;
    img.data = loss;
    img.width = loss_w;
    img.height = loss_h;

    std::ofstream outfile("loss_cpp.ppm");
    outfile << "P3 " << img.width << ' ' << img.height << " 255\n";
    for (uint16_t y = 0; y < img.height; y++)
        for (uint16_t x = 0; x < img.width; x++) {
            const auto px = ezdxt::dxt1::get_pixel_noalpha(img, x, y);
            const uint8_t r = px.r*255,
                g = px.g*255,
                b = px.b*255;
            // C++ is fucking awful please stop using it
            outfile << (int)r << ' ' << (int)g << ' ' << (int)b << '\n';
        }

    outfile.close();
}
