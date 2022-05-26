const ezdxt = @import("main.zig");
const dxt1 = ezdxt.dxt1;
const dxt3 = ezdxt.dxt3;
const dxt5 = ezdxt.dxt5;
const Rgba = ezdxt.Rgba;

//todo: make ezdxt.Image an extern struct?
const Image = extern struct {
    data: [*]const u8,
    width: u16,
    height: u16,

    pub fn toEzdxt(self: @This()) ezdxt.Image {
        var data: []const u8 = undefined;
        data.ptr = self.data;
        data.len = (@as(u32, self.width) * self.height) / 2;
        return ezdxt.Image {
            .data = data,
            .width = self.width,
            .height = self.height,
        };
    }
};


//TODO: should `dxt1.getPixel[Chunk]NoAlpha()` be exported, or left for
// the individual language bindings to recreate, considering their simplicity?

export fn ezdxt1_get_pixel(
    image: Image,
    x: u16,
    y: u16,
) Rgba {
    return dxt1.getPixel(image.toEzdxt(), x, y);
}

export fn ezdxt1_get_pixel_chunk(
    data: *const [8]u8,
    x: u8,
    y: u8,
) Rgba {
    // @intCast not @truncate, for runtime safety+catching invalid arguments
    const _x = @intCast(u2, x);
    const _y = @intCast(u2, y);

    return dxt1.getPixelChunk(data, _x, _y);
}

export fn ezdxt1_encode_chunk(
    data: *const [16]Rgba,
    output: *[8]u8,
) void {
    ezdxt.dxt1.encodeChunk(data, output, false);
}

export fn ezdxt1_encode_image(
    data: [*]const Rgba,
    width: u16,
    height: u16,
    output: [*]u8,
) void {
    const pixel_count = @as(u32, width) * height;

    var data_slice = data[0..pixel_count];
    var output_slice = output[0..pixel_count];

    ezdxt.dxt1.encodeImage(data_slice, width, height, output_slice);
}

export fn ezdxt3_get_pixel(
    image: Image,
    x: u16,
    y: u16,
) Rgba {
    return dxt3.getPixel(
        image.toEzdxt(),
        @intCast(u2, x),
        @intCast(u2, y),
    );
}

export fn ezdxt3_get_pixel_chunk(
    data: *const [16]u8,
    x: u8,
    y: u8,
) Rgba {
    return dxt3.getPixelChunk(
        data,
        @intCast(u2, x),
        @intCast(u2, y),
    );
}

export fn ezdxt5_get_pixel(
    image: Image,
    x: u16,
    y: u16,
) Rgba {
    return dxt5.getPixel(
        image.toEzdxt(),
        @intCast(u2, x),
        @intCast(u2, y),
    );
}

export fn ezdxt5_get_pixel_chunk(
    data: *const [16]u8,
    x: u8,
    y: u8,
) Rgba {
    return dxt5.getPixelChunk(
        data,
        @intCast(u2, x),
        @intCast(u2, y),
    );
}

