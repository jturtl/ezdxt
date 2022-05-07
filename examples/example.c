#include <stdio.h>
#include <stdint.h>

#include <ezdxt.h>

#include "loss_dxt1.h"

int main(void) {
    ezdxt_image img = {
        .data = loss,
        .width = loss_w,
        .height = loss_h,
    };

    FILE *const outfile = fopen("loss_c.ppm", "wb");
    if (outfile == NULL)
        return 1;

    // PPM file header
    fprintf(outfile, "P3 %d %d 255\n", img.width, img.height);

    for (uint16_t y = 0; y < img.height; y++)
        for (uint16_t x = 0; x < img.width; x++) {
            const ezdxt_color px = ezdxt1_get_pixel_noalpha(img, x, y);
            const uint8_t r = px.r*255,
                g = px.g*255,
                b = px.b*255;
            fprintf(outfile, "%d %d %d\n", r, g, b);
        }

    fclose(outfile);
    return 0;
}
