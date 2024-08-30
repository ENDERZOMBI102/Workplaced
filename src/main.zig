const std = @import("std");
const builtin  = @import("builtin");
const clap = @import("clap");
const zdt = @import("datetime");
const Hyprland = @import("hyprland/Hyprland.zig");


const helpHeader =
	\\ Usage: workplaced [options]
	\\  A simple yet powerful workspace manager daemon.
	\\
	\\ The options are:
	\\
;
// these are parsed by clap, so need to be a separate constant
const helpContents =
	\\  -h, --help         Display this help and exit.
	\\  -v, --version      Output version information and exit.
	\\      --sig <str>    The Hyprland signature to use, by default
	\\                     taken from the `HYPRLAND_INSTANCE_SIGNATURE` env var.
	\\
;

pub var allocator: std.mem.Allocator = undefined;
pub var hypr: Hyprland = undefined;
pub const std_options: std.Options = .{
	.logFn = log,  // better log formatting
	.http_disable_tls = true,  // we do not make http requests
};


pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();
	allocator = gpa.allocator();

	const params = comptime clap.parseParamsComptime( helpContents );

	var res = try clap.parse(clap.Help, &params, clap.parsers.default, .{ .allocator = allocator });
	defer res.deinit();

	if ( res.args.help != 0 ) {
		const writer = std.io.getStdOut().writer();
		_ = try writer.write( helpHeader );
		_ = try writer.write( helpContents );
		return;
	}

	std.log.info( "workplaced v{?} build with Zig v{s}", .{ @import("consts").version, builtin.zig_version_string } );

	// get the hyprland instance signature (favoriting the one from cli)
	const sig: []const u8 = res.args.sig orelse std.posix.getenv( "HYPRLAND_INSTANCE_SIGNATURE" ) orelse {
		std.log.err( "Failed to obtain Hyprland signature!!", .{} );
		std.process.exit(1);
	};
	std.log.info( "found Hyprland signature ({s})", .{ sig } );

	const xdgRuntimeDir = std.posix.getenv( "XDG_RUNTIME_DIR" ) orelse unreachable;

	// create API instance
	hypr = try Hyprland.init( allocator, eventHandler, xdgRuntimeDir, sig );
	defer hypr.deinit();

	while ( true ) {
		// handle incoming events
		try hypr.tick();
		// handle controller requests

	}
}

pub fn log( comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype ) void {
	const levelText = switch ( level ) {
		.err => "ERROR",
		.warn => "WARN",
		.info => "INFO",
		.debug => "DEBUG",
	};
	// name
	const name = if (scope == .default) "main" else @tagName(scope);
	// time
	const now = zdt.datetime.Time.now();

	// writer
	const stderr = std.io.getStdErr().writer();
	var bw = std.io.bufferedWriter(stderr);
	const writer = bw.writer();

	// write out
	std.debug.lockStdErr();
	defer std.debug.unlockStdErr();
	nosuspend {
		writer.print( "[{}:{}:{}] [" ++ name ++ "/" ++ levelText ++ "]: " ++ format ++ "\n", .{ now.hour, now.minute, now.second } ++ args ) catch return;
		bw.flush() catch return;
	}
}

fn eventHandler( evt: Hyprland.Event ) void {
	switch ( evt ) {
		.changefloatingmode => {
			// const res = hypr.getWindows() catch unreachable;
			// allocator.free( res );
		},
		.activewindow => |act| {
			if ( act.class.len > 0 and act.class[0] == 'R' ) {
				std.process.exit( 0 );
			}
		},
		else => { },
	}
}
