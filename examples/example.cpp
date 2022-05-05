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
            const auto px16 = ezdxt::get_pixel_dxt1_noalpha(img, x, y);
            const auto px = ezdxt::Rgb888::from_rgb565(px16);
            // C++ is fucking awful please stop using it
            outfile << (int)px.r << ' ' << (int)px.g << ' ' << (int)px.b << '\n';
        }

    outfile.close();
}
