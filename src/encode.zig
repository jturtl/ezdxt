//TODO: integrate SIMD, @Vector
// gotta go fast

const std = @import("std");
const common = @import("common.zig");
const Rgba = common.Rgba;

/// Very basic, and therefore fast, compression.
/// Results may be... disappointing.
pub fn simpleColorEncode(
    pixels: *const [16]Rgba,
    output: *[8]u8,
) void {
    const what = getFurthestColors(pixels);
    var min_rgba = pixels[what.min];
    var max_rgba = pixels[what.max];

    var min = min_rgba.asRgb565();
    var max = max_rgba.asRgb565();

    //HACK: HACK HACK HACKY
    // At some point in the encoding process, the R and B values are swapped.
    // This hack works around that. Remove when fixed.
    // (this bug is probably representative of a bigger problem elsewhere)
    {
        const tmp = min.r;
        min.r = min.b;
        min.b = tmp;
    }
    {
        const tmp = max.r;
        max.r = max.b;
        max.b = tmp;
    }
    // END HACK

    //HACK 2: ELECTRIC BOOGALOO
    // If col1(min) >= col0(max), then code 0b11 will be solid black.
    // However this algorithm never wants that. Make sure min and max are
    // always different
    if (@as(u16, @bitCast(min)) == @as(u16, @bitCast(max))) {
        // std.log.warn("min and max colors are identical as RGB565({X:0>4})", .{@bitCast(u16, min)});
        // std.log.warn("HACK : working around this by changing max.g", .{});
        // Basic overflow protection
        if (max.g == std.math.maxInt(u6)) {
            max.g -%= 1; // if g = 0 then.. too bad!
        } else {
            max.g += 1;
        }
    }
    // END HACK
    
    if (@as(u16, @bitCast(min)) > @as(u16, @bitCast(max))) {
        std.mem.swap(common.Rgb565, &min, &max);
        std.mem.swap(Rgba, &min_rgba, &max_rgba);
    }

    const code10 = max_rgba.mul(2).add(min_rgba).div(3);
    const code11 = max_rgba.add(min_rgba.mul(2)).div(3);

    var codes: [16]u2 = undefined;
    for (pixels, 0..) |px, i| {
        codes[i] = closestColor(px, [4]Rgba{max_rgba, min_rgba, code10, code11});
    }

    output[0] = @as(u8, @intCast(@as(u16, @bitCast(max))));
    output[1] = @as(u8, @intCast(@as(u16, @bitCast(max)) >> 8));
    output[2] = @as(u8, @intCast(@as(u16, @bitCast(min))));
    output[3] = @as(u8, @intCast(@as(u16, @bitCast(min)) >> 8));

    var codes_int: u32 = 0;
    var i: u8 = 16;
    while (i > 0) {
        i -= 1;
        const code = codes[i];
        codes_int <<= 2;
        codes_int |= code;
    }

    std.mem.bytesAsSlice(u32, output[4..8])[0] = codes_int;
}

fn closestColor(target: Rgba, options: [4]Rgba) u2 {
    var lowest_distance: f32 = 99;
    var closest_color: u2 = 0;
    for (options, 0..) |opt, i| {
        if (colorDistance(target, opt) < lowest_distance) {
            lowest_distance = colorDistance(target, opt);
            closest_color = @as(u2, @truncate(i));
        }
    }
    return closest_color;
}
fn colorDistance(a: Rgba, b: Rgba) f32 {
    return ( ( a.r - b.r ) * ( a.r - b.r ) ) +
        ( ( a.g - b.g ) * ( a.g - b.g ) ) +
        ( ( a.b - b.b ) * ( a.b - b.b ) );
}

const MinMax = struct {
    min: u8,
    max: u8,
};

fn getFurthestColors(pixels: *const [16]Rgba) MinMax {
    var max_distance: f32 = -1;
    var min: u8 = undefined;
    var max: u8 = undefined;
    var i: u8 = 0;
    while (i < pixels.len-1) : (i += 1) {
        var j: u8 = i+1;
        while (j < pixels.len) : (j += 1) {
            const dist = colorDistance(
                pixels[i],
                pixels[j],
            );
            if (dist > max_distance) {
                max_distance = dist;
                min = i;
                max = j;
            }
        }
    }

    return .{ .min = min, .max = max };
}

fn getUniqueColors(
    pixels: *const[16]Rgba,
    unique_indices: *[16]u8,
) u8 {
    var len: u8 = 0;

    for (pixels, 0..) |px, _pxi| {
        const pxi = @as(u8, @truncate(_pxi));

        var is_unique = true;

        var i: u8 = 0;
        while (i < len) : (i += 1) {
            if (px.almostEq(pixels[unique_indices[i]])) {
                is_unique = false;
                break;
            }
        }

        if (is_unique) {
            unique_indices[len] = pxi;
            len += 1;
        }
    }
    return len;
}

test "getUniqueColors" {
    const black = Rgba {.r=0,.g=0,.b=0};
    const white = Rgba {.r=1,.g=1,.b=1};
    const lgrey = Rgba {.r=0.8,.g=0.8,.b=0.8};
    const dgrey = Rgba {.r=0.4,.g=0.4,.b=0.4};
    const red = Rgba{.r=1,.g=0,.b=0};
    const grn = Rgba{.r=0,.g=1,.b=0};
    const blu = Rgba{.r=0,.g=0,.b=1};
    const expectEqual = std.testing.expectEqual;

    const seven_unique = [16]Rgba {
        red,red,blu,black,
        lgrey,red,dgrey,white,
        grn,white,lgrey,lgrey,
        white,white,dgrey,red,
    };

    var seven_unique_indices: [16]u8 = undefined;
    const seven = getUniqueColors(
        &seven_unique,
        &seven_unique_indices,
    );
    try expectEqual(seven, 7);


    const four_unique = [16]Rgba {
        black,white,lgrey,dgrey,
        dgrey,lgrey,white,white,
        white,black,dgrey,dgrey,
        white,black,white,black,
    };

    var four_unique_indices: [16]u8 = undefined;
    const four = getUniqueColors(
        &four_unique,
        &four_unique_indices,
    );
    try expectEqual(four, 4);
}
