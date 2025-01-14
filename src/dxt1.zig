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
    const local_x = @as(u2, @truncate(x));
    const local_y = @as(u2, @truncate(y));
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
    const color0: u16 = std.mem.bytesAsSlice(u16, data[0..2])[0];
    const color1: u16 = std.mem.bytesAsSlice(u16, data[2..4])[0];
    const codes_int: u32 = std.mem.bytesAsSlice(u32, data[4..8])[0];
    
    // magic!
    const bit_pos = 2 * (@as(u5, y) * 4 + x);
    const code = @as(u2, @truncate(codes_int >> bit_pos));

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

//TODO: transparency
pub fn encodeChunk(
    pixels: *const [16]Rgba,
    output: *[8]u8,
    use_alpha: bool,
) void {
    _ = use_alpha;
    @import("encode.zig").simpleColorEncode(pixels, output);
}

pub fn encodeImage(
    data: []const Rgba,
    width: u16,
    height: u16,
    output: []u8,
) void {
    std.debug.assert(output.len == (@as(u32, width) * height)/2);

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
            encodeChunk(@as(*const[16]Rgba, @ptrCast(&chunk)), output[@as(u32, i)*8..][0..8], false);
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
    std.debug.assert(compressed.len == (@as(u32, width) * height)/2);
    std.debug.assert(output.len == @as(u32, width) * height);

    const nchunks_x = width / 4;
    const nchunks_y = height / 4;

    var chunk_y: u8 = 0;
    while (chunk_y < nchunks_y) : (chunk_y += 1) {
        var chunk_x: u8 = 0;
        while (chunk_x < nchunks_x) : (chunk_x += 1) {
            const chunk_idx = chunk_y * nchunks_x + chunk_x;
            const chunk_data = compressed[chunk_idx * 8..][0..8];

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

test "DXT1 encode/decode cycle for 8x8 image" {
    const testing = std.testing;
    
    // Create an 8x8 test image with some distinct colors
    var original: [64]Rgba = undefined;
    for (&original, 0..) |*px, i| {
        px.* = switch (i % 4) {
            0 => Rgba{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }, // Red
            1 => Rgba{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }, // Green
            2 => Rgba{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }, // Blue
            3 => Rgba{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }, // White
            else => unreachable,
        };
    }

    // Encode
    var compressed: [256]u8 = undefined;
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