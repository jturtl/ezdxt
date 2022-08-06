const std = @import("std");
const ezdxt = @import("ezdxt");
const loss = @embedFile("loss_dxt1.bin");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const img = ezdxt.Image {
        .data = loss,
        .width = 8,
        .height = 8,
    };

    // max 12 bytes per pixel ("NNN NNN NNN\n") times 64 (8x8 pixels)
    // plus 11 (header, "P3 8 8 255\n")
    const bufsz = 12 * 8*8 + 11;
    const buf = try allocator.alloc(u8, bufsz);
    defer allocator.free(buf);

    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();

    try writer.writeAll("P3 8 8 255\n");

    var y: u4 = 0;
    while (y < 8) : (y += 1) {
        var x: u4 = 0;
        while (x < 8) : (x += 1) {
            const px = ezdxt.dxt1.getPixelNoAlpha(img, x, y);
            const rgb = px.asRgb888();
            try writer.print("{} {} {}\n", .{rgb.r, rgb.g, rgb.b});
        }
    }

    try std.io.getStdOut().writeAll(buf[0..stream.pos]);
}
