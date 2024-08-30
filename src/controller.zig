const std = @import("std");
const clap = @import("clap");


const helpHeader =
	\\ Usage: workplacectl [options]
	\\  A simple yet powerful workspace manager daemon.
	\\
	\\ The options are:
	\\
;
// these are parsed by clap, so need to be a separate constant
const helpContents =
	\\  -h, --help         Display this help and exit.
	\\  -v, --version      Output version information and exit.
	\\      --goto <WID>   Switch to the requested workspace.
	\\      --bring        Bring the current active window with you
	\\                     while changing workspace.
	\\      --current      Print the current workspace's name.
	\\
;


pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();
	const allocator = gpa.allocator();

	const params = comptime clap.parseParamsComptime( helpContents );

	var res = try clap.parse(clap.Help, &params, clap.parsers.default, .{ .allocator = allocator });
	defer res.deinit();

	if ( res.args.help != 0 ) {
		const writer = std.io.getStdOut().writer();
		_ = try writer.write( helpHeader );
		_ = try writer.write( helpContents );
		return;
	}
}
