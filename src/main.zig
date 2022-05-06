const std = @import("std");
const builtin = @import("builtin");

pub const Image = struct {
    data: []const u8,
    width: u16,
    height: u16,
};

pub const Rgb565 = packed struct {
    r: u5, g: u6, b: u5,

    pub fn fromInt(int: u16) @This() {
        return .{ 
            .r = @truncate(u5, int >> 11),
            .g = @truncate(u6, int >> 5),
            .b = @truncate(u5, int),
        };
    }

    pub fn asFloats(self: @This()) Rgbf {
        const maxInt = std.math.maxInt;
        return Rgbf {
            .r = @intToFloat(f32, self.r) / maxInt(u5),
            .g = @intToFloat(f32, self.g) / maxInt(u6),
            .b = @intToFloat(f32, self.b) / maxInt(u5),
            .a = 1,
        };
    }

    pub fn as24bit(self: @This()) Rgb888 {
        return self.asFloats().as24bit();
    }
};
pub const Rgb888 = struct {
    r: u8, g: u8, b: u8,
};
comptime {
    std.debug.assert(@bitSizeOf(Rgb565) == 16);
    //std.debug.assert(@bitSizeOf(Rgbf) == 96);
}

pub const Rgbf = struct {
    r: f32, g: f32, b: f32, a: f32,

    pub fn assertValid(self: @This()) void {
        std.debug.assert(self.r >= 0 and self.r <= 1);
        std.debug.assert(self.g >= 0 and self.g <= 1);
        std.debug.assert(self.b >= 0 and self.b <= 1);
        std.debug.assert(self.a >= 0 and self.a <= 1);
    }

    pub fn as16bit(self: @This()) Rgb565 {
        self.assertValid();

        const maxInt = std.math.maxInt;
        return .{
            .r = @floatToInt(u5, self.r * maxInt(u5)),
            .g = @floatToInt(u6, self.g * maxInt(u6)),
            .b = @floatToInt(u5, self.b * maxInt(u5)),
        };
    }

    pub fn as24bit(self: @This()) Rgb888 {
        self.assertValid();

        const maxInt = std.math.maxInt;
        return .{
            .r = @floatToInt(u8, self.r * maxInt(u8)),
            .g = @floatToInt(u8, self.g * maxInt(u8)),
            .b = @floatToInt(u8, self.b * maxInt(u8)),
        };        
    }

    pub fn mul(self: @This(), scalar: f32) @This() {
        return .{
            .r = self.r * scalar,
            .g = self.g * scalar,
            .b = self.b * scalar,
            .a = 1,
        };
    }

    pub fn div(self: @This(), scalar: f32) @This() {
        return .{
            .r = self.r / scalar,
            .g = self.g / scalar,
            .b = self.b / scalar,
            .a = 1,
        };
    }

    pub fn add(self: @This(), other: @This()) @This() {
        return .{
            .r = self.r + other.r,
            .g = self.g + other.g,
            .b = self.b + other.b,
            .a = 1,
        };
    }
};


// the caller may interpet null return value as
// solid black (normal DXT1) or full transparent (DXT1+alpha)
pub fn getPixelDxt1Chunk(data: *const [8]u8, x: u2, y: u2) ?Rgb565 {
    const color0 = std.mem.readIntLittle(u16, data[0..2]);
    const color1 = std.mem.readIntLittle(u16, data[2..4]);
    const codes_int = std.mem.readIntLittle(u32, data[4..8]);
    
    const bit_pos = @intCast(u5, 2 * (@as(u8, y) * 4 + @as(u8, x)));
    const code = @truncate(u2, codes_int >> bit_pos);

    return codeToColor(code, color0, color1);
}

pub const Rgba5658 = struct {};
pub fn getPixelDxt3Chunk(data: *const [16]u8, x: u2, y: u2) Rgba5658 {
    _ = data;
    _ = x;
    _ = y;
    @compileError("todo");    
}

pub fn getPixelDxt1(
    image: Image,
    x: u16,
    y: u16,
) ?Rgb565 {
    std.debug.assert(x < image.width);
    std.debug.assert(y < image.height);

    const chunks_x = image.width / 4;
    const chunk_x = x / 4;
    const chunk_y = y / 4;
    const chunk_i: u32 = chunk_y * chunks_x + chunk_x;
    
    // do this magic instead of data[chunk_i*8..chunk_i*8+8]
    // so that chunk can cast to *const [8]u8 in getPixelDxt1Chunk
    const chunk = image.data[chunk_i*8..].ptr[0..8];

    const local_x = @truncate(u2, x % 4);
    const local_y = @truncate(u2, y % 4);
    return getPixelDxt1Chunk(chunk, local_x, local_y);
}

fn codeToColor(code: u2, col0: u16, col1: u16) ?Rgb565 {
    const col0_rgb = Rgb565.fromInt(col0);
    const col1_rgb = Rgb565.fromInt(col1);
    const col0_rgbf = col0_rgb.asFloats();
    const col1_rgbf = col1_rgb.asFloats();
    
    return switch (code) {
        0b00 => col0_rgb,
        0b01 => col1_rgb,
        0b10 => if (col0 > col1)
                    col0_rgbf.mul(2).add(col1_rgbf).div(3).as16bit()
                else
                    col0_rgbf.add(col1_rgbf).div(2).as16bit(),
        0b11 => if (col0 > col1)
                    col0_rgbf.add(col1_rgbf.mul(2)).div(3).as16bit()
                else
                    null,
    };
}


test "Rgb565 from int" {
    const int: u16 = 0b00100_110011_10101;
    const col = Rgb565.fromInt(int);
    const expectEqual = std.testing.expectEqual;

    try expectEqual(@as(u5, 0b00100), col.r);
    try expectEqual(@as(u6, 0b110011), col.g);
    try expectEqual(@as(u5, 0b10101), col.b);
}
