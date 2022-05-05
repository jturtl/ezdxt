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
    (void)fprintf(outfile, "P3 %d %d 255\n", img.width, img.height);

    for (uint16_t y = 0; y < img.height; y++)
        for (uint16_t x = 0; x < img.width; x++) {
            const ezdxt_rgb565 px16bit = ezdxt_get_pixel_dxt1_noalpha(img, x, y);
            const ezdxt_rgb888 px = ezdxt_rgb888_from_565(px16bit);
            (void)fprintf(outfile, "%d %d %d\n", px.r, px.g, px.b);
        }

    (void)fclose(outfile);
    return 0;
}
