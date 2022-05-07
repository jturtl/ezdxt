const std = @import("std");
const common = @import("common.zig");

const Rgb565 = common.Rgb565;
const Rgba5654 = common.Rgba5654;

pub fn getPixel(
    image: common.Image,
    x: u16,
    y: u16,
) Rgba5654 {
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
) Rgba5654 {
    const alpha_chunk = std.mem.readIntLittle(u64, data[0..8]);
    const alpha_value = getAlphaValue(alpha_chunk, x, y);

    const color_chunk = data[8..16];
    const color = getColor(color_chunk, x, y);

    return Rgba5654 {
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = alpha_value,
    };
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
) Rgb565 {
    const color0 = std.mem.readIntLittle(u16, data[0..2]);
    const color1 = std.mem.readIntLittle(u16, data[2..4]);
    const codes = std.mem.readIntLittle(u32, data[4..8]);

    const bit_pos = 2 * (@as(u5, y) * 4 + @as(u5, x));
    const code = @truncate(u2, codes >> bit_pos);

    return codeToColor(code, color0, color1);
}

fn codeToColor(code: u2, col0: u16, col1: u16) Rgb565 {
    const col0_rgb = Rgb565.fromInt(col0);
    const col1_rgb = Rgb565.fromInt(col1);
    const col0_rgba = col0_rgb.asRgba();
    const col1_rgba = col1_rgb.asRgba();
    
    return switch (code) {
        0b00 => col0_rgb,
        0b01 => col1_rgb,
        0b10 => col0_rgba.add(col1_rgba).div(2).asRgb565(),
        0b11 => Rgb565.fromInt(0),
    };
}
