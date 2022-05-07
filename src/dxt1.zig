const std = @import("std");
const common = @import("common.zig");

const Rgb565 = common.Rgb565;
const Rgba = common.Rgba;

pub fn getPixel(
    img: common.Image,
    x: u16,
    y: u16,
) Rgba {
    std.debug.assert(x < img.width);
    std.debug.assert(y < img.height);

    const chunk_count_x = img.width / 4;
    const chunk_x = x / 4;
    const chunk_y = y / 4;
    const chunk_i: u32 = chunk_y*chunk_count_x + chunk_x;
    
    // do this magic instead of data[chunk_i*8..chunk_i*8+8]
    // so that chunk can cast to *const [8]u8 in getPixelDxt1Chunk
    const chunk = img.data[chunk_i*8..].ptr[0..8];

    // faster than (x % 4)? Same result, anyway.
    const local_x = @truncate(u2, x);
    const local_y = @truncate(u2, y);
    return getPixelChunk(chunk, local_x, local_y);
}

/// Same as `getPixel`, but returns a black pixel if result is null
pub fn getPixelNoAlpha(
    img: common.Image,
    x: u16,
    y: u16,
) Rgba {
    const px = getPixel(img, x, y);
    if (px.a == 0)
        return Rgba.black
    else
        return px;
}

pub fn getPixelChunk(
    data: *const[8]u8,
    x: u2,
    y: u2,
) Rgba {
    const color0 = std.mem.readIntLittle(u16, data[0..2]);
    const color1 = std.mem.readIntLittle(u16, data[2..4]);
    const codes_int = std.mem.readIntLittle(u32, data[4..8]);
    
    // magic!
    const bit_pos = 2 * (@as(u5, y) * 4 + x);
    const code = @truncate(u2, codes_int >> bit_pos);

    return codeToColor(code, color0, color1);
}

pub fn getPixelChunkNoAlpha(
    data: *const[8]u8,
    x: u2,
    y: u2,
) Rgba {
        const px = getPixelChunk(data, x, y);
        if (px.a == 0)
            return Rgba.black
        else
            return px; 
}

fn codeToColor(code: u2, col0: u16, col1: u16) Rgba {
    const col0_rgb = Rgb565.fromInt(col0);
    const col1_rgb = Rgb565.fromInt(col1);
    const col0_rgba = col0_rgb.asRgba();
    const col1_rgba = col1_rgb.asRgba();
    
    return switch (code) {
        0b00 => col0_rgba,
        0b01 => col1_rgba,
        0b10 => if (col0 > col1)
                    col0_rgba.mul(2).add(col1_rgba).div(3)
                else
                    col0_rgba.add(col1_rgba).div(2),
        0b11 => if (col0 > col1)
                    col0_rgba.add(col1_rgba.mul(2)).div(3)
                else
                    Rgba.transparent,
    };
}

