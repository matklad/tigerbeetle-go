const builtin = @import("builtin");
const std = @import("std");
const log = std.log;
const assert = std.debug.assert;

const flags = @import("../../flags.zig");
const fatal = flags.fatal;
const Shell = @import("../../shell.zig");
const TmpTigerBeetle = @import("../../testing/tmp_tigerbeetle.zig");

pub fn tests(shell: *Shell, gpa: std.mem.Allocator) !void {
    // No unit tests for Go :-(

    // Integration tests.

    // Integration tests require a C compiler, use `zig cc` as our CC. 
    const zig_exe = try shell.project_root.realpathAlloc(
        shell.arena.allocator(),
        comptime "zig/zig" ++ builtin.target.exeFileExt(),
    );
    const zig_cc = try shell.print("{s} cc", .{zig_exe});

    inline for (.{ "basic",  "two-phase", "two-phase-many" }) |sample| {
        var sample_dir = try shell.project_root.openDir("src/clients/go/samples/" ++ sample, .{});
        defer sample_dir.close();

        try sample_dir.setAsCwd();

        var tmp_beetle = try TmpTigerBeetle.init(gpa, .{});
        defer tmp_beetle.deinit(gpa);

        try shell.env.put("CC", zig_cc);
        try shell.env.put("TB_ADDRESS", tmp_beetle.port_str.slice());
        try shell.exec("go run main.go", .{});
    }
}

pub fn verify_release(shell: *Shell, gpa: std.mem.Allocator, tmp_dir: std.fs.Dir) !void {
    var tmp_beetle = try TmpTigerBeetle.init(gpa, .{});
    defer tmp_beetle.deinit(gpa);

    try shell.exec("go mod init tbtest", .{});
    try shell.exec("go get github.com/tigerbeetle/tigerbeetle-go", .{});

    try Shell.copy_path(
        shell.project_root,
        "src/clients/go/samples/basic/main.go",
        tmp_dir,
        "main.go",
    );
    const zig_exe = try shell.project_root.realpathAlloc(
        shell.arena.allocator(),
        comptime "zig/zig" ++ builtin.target.exeFileExt(),
    );
    const zig_cc = try shell.print("{s} cc", .{zig_exe});

    try shell.env.put("CC", zig_cc);
    try shell.exec("go run main.go", .{});
}
