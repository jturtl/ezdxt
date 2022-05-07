const std = @import("std");
const ezdxt = @import("ezdxt");
const loss = @embedFile("loss_dxt1.bin");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();

    const buf = try allocator.alloc(u8, 42069);
    defer allocator.free(buf);
    const img = ezdxt.Image {
        .data = loss,
        .width = 8,
        .height = 8,
    };

    var idx: usize = 0;
    const print = std.fmt.bufPrint;
    idx += (try print(buf[idx..], "P3 8 8 255\n", .{})).len;
    var y: u4 = 0;
    while (y < 8) : (y += 1) {
        var x: u4 = 0;
        while (x < 8) : (x += 1) {
            const px = ezdxt.dxt1.getPixelNoAlpha(img, x, y);
            const rgb = px.asRgb888();
            idx += (try print(buf[idx..], "{} {} {}\n", .{rgb.r, rgb.g, rgb.b})).len;
        }
    }

    try std.io.getStdOut().writeAll(buf[0..idx]);
}
