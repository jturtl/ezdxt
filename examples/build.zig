const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ezdxt_module = b.createModule(.{
        .root_source_file = b.path("../src/main.zig"),
    });

    const lib = b.addExecutable(.{
        .name = "ezdxt-example",
        .root_source_file = b.path("example.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addImport("ezdxt", ezdxt_module);
    b.installArtifact(lib);
}

