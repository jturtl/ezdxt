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
    const local_x = @as(u2, @truncate(x));
    const local_y = @as(u2, @truncate(y));
    return getPixelChunk(chunk, local_x, local_y);
}

pub fn getPixelChunk(
    data: *const[16]u8,
    x: u2,
    y: u2,
) Rgba {
    const alpha_chunk: u64 = std.mem.bytesAsSlice(u64, data[0..8])[0];
    const alpha_value = getAlphaValue(alpha_chunk, x, y);

    const color_chunk = data[8..16];
    var color = getColor(color_chunk, x, y);
    color.a = @as(f32, @floatFromInt(alpha_value))/std.math.maxInt(u4);
    return color;
}

fn getAlphaValue(
    data: u64,
    x: u2,
    y: u2,
) u4 {
    const bit_pos = 4 * (@as(u6, y) * 4 + x);
    const value = @as(u4, @truncate(data >> bit_pos));
    return value;
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

pub fn encodeChunk(
    pixels: *const [16]Rgba,
    output: *[16]u8,
) void {
    // First 8 bytes: alpha values (4 bits each)
    var alpha_bits: u64 = 0;
    for (pixels, 0..) |px, i| {
        const alpha4: u4 = @intFromFloat(px.a * std.math.maxInt(u4));
        alpha_bits |= @as(u64, alpha4) << @as(u6, @intCast(i * 4));
    }
    std.mem.bytesAsSlice(u64, output[0..8])[0] = alpha_bits;

    // Last 8 bytes: color data (same as DXT1)
    @import("encode.zig").simpleColorEncode(pixels, output[8..16]);
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

pub fn encodeImage(
    data: []const Rgba,
    width: u16,
    height: u16,
    output: []u8,
) void {
    std.debug.assert(output.len == @as(u32, width) * height);
    std.debug.assert(width % 4 == 0 and height % 4 == 0);

    const nchunks_x = width / 4;
    const nchunks_y = height / 4;

    var i: u16 = 0;
    var y: u8 = 0;
    while (y < nchunks_y) : (y += 1) {
        var x: u8 = 0;
        while (x < nchunks_x) : (x += 1) {
            const row0 = data[@as(u32, 4)*y*width+@as(u32, 4)*x..][0..4].*;
            const row1 = data[@as(u32, 4)*y*width+@as(u32, 4)*x+width*1..][0..4].*;
            const row2 = data[@as(u32, 4)*y*width+@as(u32, 4)*x+width*2..][0..4].*;
            const row3 = data[@as(u32, 4)*y*width+@as(u32, 4)*x+width*3..][0..4].*;
            const chunk = [4][4]Rgba{
                row0,row1,row2,row3,
            };
            encodeChunk(@as(*const[16]Rgba, @ptrCast(&chunk)), output[@as(u32, i)*16..][0..16]);
            i += 1;
        }
    }
}

pub fn decodeImage(
    compressed: []const u8,
    width: u16, 
    height: u16,
    output: []Rgba,
) void {
    std.debug.assert(compressed.len == @as(u32, width) * height);
    std.debug.assert(output.len == @as(u32, width) * height);

    const nchunks_x = width / 4;
    const nchunks_y = height / 4;

    var chunk_y: u8 = 0;
    while (chunk_y < nchunks_y) : (chunk_y += 1) {
        var chunk_x: u8 = 0;
        while (chunk_x < nchunks_x) : (chunk_x += 1) {
            const chunk_idx = chunk_y * nchunks_x + chunk_x;
            const chunk_data = compressed[chunk_idx * 16..][0..16];

            var y: u2 = 0;
            while (y < 4) : (y += 1) {
                var x: u2 = 0;
                while (x < 4) : (x += 1) {
                    const pixel = getPixelChunk(chunk_data, x, y);
                    const out_idx = @as(u32, chunk_y * 4 + y) * width + (chunk_x * 4 + x);
                    output[out_idx] = pixel;
                }
            }
        }
    }
}

test "DXT3 encode/decode cycle for 8x8 image" {
    const testing = std.testing;
    
    // Create an 8x8 test image with some distinct colors and alpha values
    var original: [64]Rgba = undefined;
    for (&original, 0..) |*px, i| {
        px.* = switch (i % 4) {
            0 => Rgba{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 },     // Red
            1 => Rgba{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 0.5 },     // Semi-transparent Green
            2 => Rgba{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 0.25 },    // Mostly transparent Blue
            3 => Rgba{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 0.75 },    // Semi-opaque White
            else => unreachable,
        };
    }

    // Encode
    var compressed: [512]u8 = undefined;  // DXT3 uses 16 bytes per 4x4 block
    encodeImage(&original, 8, 8, &compressed);

    // Decode
    var decoded: [64]Rgba = undefined;
    decodeImage(&compressed, 8, 8, &decoded);

    // Compare results (with some tolerance due to lossy compression)
    const tolerance = 0.1;
    for (original, decoded) |orig, dec| {
        try testing.expect(@abs(orig.r - dec.r) <= tolerance);
        try testing.expect(@abs(orig.g - dec.g) <= tolerance);
        try testing.expect(@abs(orig.b - dec.b) <= tolerance);
        try testing.expect(@abs(orig.a - dec.a) <= tolerance);
    }
}