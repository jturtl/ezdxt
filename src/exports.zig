const ezdxt = @import("main.zig");

const Dxt1Pixel = extern struct {
    color: ezdxt.Rgb565,
    has_color: bool,
};
export fn ezdxt_get_pixel_dxt1_chunk(
    data: *const [8]u8,
    x: u8,
    y: u8,
) Dxt1Pixel {
    // @intCast not @truncate, for runtime safety+catching invalid arguments
    const _x = @intCast(u2, x);
    const _y = @intCast(u2, y);

    if (ezdxt.getPixelDxt1Chunk(data, _x, _y)) |px|
        return .{ .has_color=true, .color=px }
    else
        return .{ .has_color=false, .color=undefined};
}
const Image = extern struct {
    data: [*]const u8,
    width: u16,
    height: u16,


    pub fn toEzdxt1(self: @This()) ezdxt.Image {
        // - calculate length of data, assuming DXT1 format -
        // ezdxt.Image.data being a slice and not a pointer-to-many
        // is intentional, as it allows runtime safety checks.
        // This might change because
        // 1. with safety checks disabled, data.len is not used (an entire usize wasted!)
        // 2. extern structs cannot have slices (hence this struct)
        // The result of this function does not guarantee that
        // data.len covers the actual amount of memory allocated in data.ptr
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
export fn ezdxt_get_pixel_dxt1(
    image: Image,
    x: u16,
    y: u16,
) Dxt1Pixel {
    if (ezdxt.getPixelDxt1(image.toEzdxt1(), x, y)) |px|
        return .{ .has_color=true, .color=px }
    else
        return .{ .has_color=false, .color=undefined };
}

