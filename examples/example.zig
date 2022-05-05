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
            const px_16 = ezdxt.getPixelDxt1(img, x, y)
                orelse ezdxt.Rgb565.fromInt(0);
            const px = px_16.as24bit();
            idx += (try print(buf[idx..], "{} {} {}\n", .{px.r, px.g, px.b})).len;
        }
    }

    try std.io.getStdOut().writeAll(buf[0..idx]);
}
