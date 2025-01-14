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

pub fn encodeChunk(
    pixels: *const [16]Rgba,
    output: *[16]u8,
) void {
    // First 8 bytes: interpolated alpha values
    var min_alpha: u8 = 255;
    var max_alpha: u8 = 0;
    
    // Find alpha range
    for (pixels) |px| {
        const alpha = @as(u8, @intFromFloat(px.a * 255));
        if (alpha < min_alpha) min_alpha = alpha;
        if (alpha > max_alpha) max_alpha = alpha;
    }

    output[0] = max_alpha;
    output[1] = min_alpha;

    // Generate alpha codes
    var alpha_codes: u48 = 0;
    for (pixels, 0..) |px, i| {
        const alpha = @as(u8, @intFromFloat(px.a * 255));
        const code = getAlphaCode(alpha, min_alpha, max_alpha);
        alpha_codes |= @as(u48, code) << @as(u6, @intCast(i * 3));
    }

    // Store alpha codes
    output[2] = @as(u8, @truncate(alpha_codes));
    output[3] = @as(u8, @truncate(alpha_codes >> 8));
    output[4] = @as(u8, @truncate(alpha_codes >> 16));
    output[5] = @as(u8, @truncate(alpha_codes >> 24));
    output[6] = @as(u8, @truncate(alpha_codes >> 32));
    output[7] = @as(u8, @truncate(alpha_codes >> 40));

    // Last 8 bytes: color data (same as DXT1)
    @import("encode.zig").simpleColorEncode(pixels, output[8..16]);
}

fn getAlphaCode(alpha: u8, min: u8, max: u8) u3 {
    if (max > min) {
        if (alpha == max) return 0;
        if (alpha == min) return 1;
        
        //const dist_to_max = @as(i16, max) - alpha;
        const dist_to_min = alpha - @as(i16, min);
        const total_dist = @as(i16, max) - min;
        
        const ratio = (@as(f32, @floatFromInt(dist_to_min)) / @as(f32, @floatFromInt(total_dist))) * 7;
        return @as(u3, @intFromFloat(@floor(ratio)));
    } else {
        if (alpha == max) return 0;
        if (alpha == min) return 1;
        return 0;
    }
}

test "DXT5 encode/decode cycle for 8x8 image" {
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
    var compressed: [512]u8 = undefined;  // DXT5 uses 16 bytes per 4x4 block
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
