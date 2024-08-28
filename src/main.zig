const std = @import("std");
const builtin  = @import("builtin");
const clap = @import("clap");
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
	.logFn = log,
};


pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();
	allocator = gpa.allocator();

	const params = comptime clap.parseParamsComptime( helpContents );

	var res = try clap.parse(clap.Help, &params, clap.parsers.default, .{ .allocator = gpa.allocator() });
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

	// create API instance
	hypr = try Hyprland.init( allocator, eventHandler, sig );
	defer hypr.deinit();

	while ( true ) {
		// handle incoming events
		try hypr.tick();
		// handle controller requests

	}
}

pub fn log( comptime message_level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype ) void {
	const level_txt = comptime message_level.asText();
	const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
	const stderr = std.io.getStdErr().writer();
	var bw = std.io.bufferedWriter(stderr);
	const writer = bw.writer();

	// const now = std.time.Instant.now() catch return;
	// std.time.

	std.debug.lockStdErr();
	defer std.debug.unlockStdErr();
	nosuspend {
		writer.print( level_txt ++ prefix2 ++ format ++ "\n", args ) catch return;
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
