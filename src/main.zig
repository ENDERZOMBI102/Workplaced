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

	try hypr.listen();
}

fn eventHandler( evt: Hyprland.Event ) void {
	std.log.debug( "received event: {?}", .{ evt } );
	if ( evt == .changefloatingmode ) {
		// const res = hypr.getWindows() catch unreachable;
		// allocator.free( res );
	}
}
