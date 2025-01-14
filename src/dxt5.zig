const std = @import("std");
const common = @import("common.zig");
const Rgba = common.Rgba;

//todo: a lot of code duplication from dxt3, could be cleaned

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
    const local_x = @as(u2, @truncate(x));
    const local_y = @as(u2, @truncate(y));
    return getPixelChunk(chunk, local_x, local_y);
}

pub fn getPixelChunk(
    data: *const[16]u8,
    x: u2,
    y: u2,
) Rgba {
    const alpha_chunk = data[0..8];
    const alpha_value = getAlphaValue(alpha_chunk, x, y);

    const color_chunk = data[8..16];
    var color = getColor(color_chunk, x, y);
    color.a = alpha_value;
    return color;
}

fn getAlphaValue(data: *const [8]u8, x: u2, y: u2) f32 {
    const alpha0 = data[0];
    const alpha1 = data[1];
    const alpha0f: f32 = @as(f32, @floatFromInt(alpha0))/255;
    const alpha1f: f32 = @as(f32, @floatFromInt(alpha1))/255;

    // const codes: u48 = std.mem.bytesAsSlice(u48, data[2..])[0];
    // WORKAROUND
    const codes: u48 = @as(u48, data[7]) << 40 | 
                  @as(u48, data[6]) << 32 |
                  @as(u48, data[5]) << 24 |
                  @as(u48, data[4]) << 16 |
                  @as(u48, data[3]) << 8 |
                  @as(u48, data[2]);

    const bit_pos = 3 * (@as(u6, y) * 4 + x);
    const code = @as(u3, @truncate(codes >> bit_pos));

    if (alpha0 > alpha1) {
        return switch (code) {
            0b000 => alpha0f,
            0b001 => alpha1f,
            0b010 => (6*alpha0f + alpha1f)/7,
            0b011 => (5*alpha0f + 2*alpha1f)/7,
            0b100 => (4*alpha0f + 3*alpha1f)/7,
            0b101 => (3*alpha0f + 4*alpha1f)/7,
            0b110 => (2*alpha0f + 5*alpha1f)/7,
            0b111 => (alpha0f + 6*alpha1f)/7,
        };
    } else {
        return switch (code) {
            0b000 => alpha0f,
            0b001 => alpha1f,
            0b010 => (4*alpha0f + alpha1f)/5,
            0b011 => (3*alpha0f + 2*alpha1f)/5,
            0b100 => (2*alpha0f + 3*alpha1f)/5,
            0b101 => (alpha0f + 4*alpha1f)/5,
            0b110 => 0,
            0b111 => 1,
        };
    }
}

fn getColor(
    data: *const[8]u8,
    x: u2,
    y: u2,
) Rgba {
    const color0: u16 = std.mem.bytesAsSlice(u16, data[0..2])[0];
    const color1: u16 = std.mem.bytesAsSlice(u16, data[2..4])[0];
    const codes: u32 = std.mem.bytesAsSlice(u32, data[4..8])[0];

    const bit_pos = 2 * (@as(u5, y) * 4 + @as(u5, x));
    const code = @as(u2, @truncate(codes >> bit_pos));

    return codeToColor(code, color0, color1);
}

fn codeToColor(code: u2, col0: u16, col1: u16) Rgba {
    const col0_rgb565 = common.Rgb565.fromInt(col0);
    const col1_rgb565 = common.Rgb565.fromInt(col1);
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

