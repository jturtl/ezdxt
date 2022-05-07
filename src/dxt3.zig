const std = @import("std");
const common = @import("common.zig");

const Rgb565 = common.Rgb565;
const Rgba5654 = common.Rgba5654;
const Rgba = common.Rgba;

pub fn getPixel(
    image: common.Image,
    x: u16,
    y: u16,
) Rgba {
    std.debug.assert(x < image.width);
    std.debug.assert(y < image.height);

    const chunk_count_x = image.width / 4;
    const chunk_x = x / 4;
    const chunk_y = y / 4;
    const chunk_i: u32 = chunk_y*chunk_count_x + chunk_x;
    const chunk = image.data[chunk_i*16..].ptr[0..16];
    const local_x = @truncate(u2, x);
    const local_y = @truncate(u2, y);
    return getPixelChunk(chunk, local_x, local_y);
}

pub fn getPixelChunk(
    data: *const[16]u8,
    x: u2,
    y: u2,
) Rgba {
    const alpha_chunk = std.mem.readIntLittle(u64, data[0..8]);
    const alpha_value = getAlphaValue(alpha_chunk, x, y);

    const color_chunk = data[8..16];
    var color = getColor(color_chunk, x, y);
    color.a = @intToFloat(f32,alpha_value)/std.math.maxInt(u4);
    return color;
}

fn getAlphaValue(
    data: u64,
    x: u2,
    y: u2,
) u4 {
    const bit_pos = 4 * (@as(u6, y) * 4 + x);
    const value = @truncate(u4, data >> bit_pos);
    return value;
}

fn getColor(
    data: *const[8]u8,
    x: u2,
    y: u2,
) Rgba {
    const color0 = std.mem.readIntLittle(u16, data[0..2]);
    const color1 = std.mem.readIntLittle(u16, data[2..4]);
    const codes = std.mem.readIntLittle(u32, data[4..8]);

    const bit_pos = 2 * (@as(u5, y) * 4 + @as(u5, x));
    const code = @truncate(u2, codes >> bit_pos);

    return codeToColor(code, color0, color1);
}

fn codeToColor(code: u2, col0: u16, col1: u16) Rgba {
    const col0_rgb565 = Rgb565.fromInt(col0);
    const col1_rgb565 = Rgb565.fromInt(col1);
    const col0_rgba = col0_rgb565.asRgba();
    const col1_rgba = col1_rgb565.asRgba();
    
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
                    Rgba.black,
    };
}
