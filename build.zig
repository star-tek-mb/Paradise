const std = @import("std");
const wasmserve = @import("libs/wasmserve.zig");

const zlm = std.build.Pkg{
    .name = "zlm",
    .source = .{ .path = "libs/zlm.zig" },
};
const sysjs = std.build.Pkg{
    .name = "sysjs",
    .source = .{ .path = "libs/sysjs.zig" },
};
const qoi = std.build.Pkg{
    .name = "qoi",
    .source = .{ .path = "libs/qoi.zig" },
};

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{
        .default_target = std.zig.CrossTarget{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .abi = .none,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addAnonymousModule("zlm", .{ .source_file = .{ .path = "libs/zlm.zig" } });
    exe.addAnonymousModule("sysjs", .{ .source_file = .{ .path = "libs/sysjs.zig" } });
    exe.addAnonymousModule("qoi", .{ .source_file = .{ .path = "libs/qoi.zig" } });
    exe.export_symbol_names = &.{ "wasmCallFunction" };
    exe.install();

    const serve_step = try wasmserve.serve(exe, .{});
    const run_step = b.step("run", "Start a testing server");
    run_step.dependOn(&serve_step.step);
}
