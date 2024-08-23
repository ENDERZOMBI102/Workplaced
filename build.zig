const std = @import("std");


pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

	// build constants
	const consts = b.addOptions();
	consts.addOption(std.SemanticVersion, "version", try std.SemanticVersion.parse( "0.0.0" ) );

	// dependencies
	const clap = b.dependency("clap", .{});

    const daemon = b.addExecutable(.{
        .name = "workplaced",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
	daemon.root_module.addImport("clap", clap.module("clap"));
	daemon.root_module.addOptions("consts", consts);

    const ctl = b.addExecutable(.{
        .name = "workplacectl",
        .root_source_file = b.path("src/controller.zig"),
        .target = target,
        .optimize = optimize,
    });
	ctl.root_module.addImport("clap", clap.module("clap"));

    b.installArtifact(daemon);
    b.installArtifact(ctl);

    // run daemon
    const daemonCmd = b.addRunArtifact(daemon);
    daemonCmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        daemonCmd.addArgs(args);
    }
    const runDaemonStep = b.step("run-daemon", "Run the daemon");
    runDaemonStep.dependOn(&daemonCmd.step);

	// run controller
    const controllerCmd = b.addRunArtifact(ctl);
    controllerCmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        controllerCmd.addArgs(args);
    }
    const runControllerStep = b.step("run-ctl", "Run the controller");
	runControllerStep.dependOn(&controllerCmd.step);
}
