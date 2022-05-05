const std = @import("std");

const name = "ezdxt";
const root = "src/exports.zig";
const tests_root = root;

const warn = std.debug.print;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary(name, root);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();
    //lib.strip = true;
    
    const main_tests = b.addTest(tests_root);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
