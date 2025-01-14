const std = @import("std");

const name = "ezdxt";
const root = "src/exports.zig";
const tests_root = root;

const warn = std.debug.print;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary(.{
        .name = "ezdxt",
        .root_source_file = b.path("src/exports.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/exports.zig"),
        .target = target,
        .optimize = optimize,
    });
    

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
