const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const lib = b.addExecutable("ezdxt-example", "example.zig");
    lib.addPackagePath("ezdxt", "../src/main.zig");
    lib.install();
}

