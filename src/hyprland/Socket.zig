const std = @import("std");
const util = @import("../util.zig");
const Self = @This();

path: []const u8,
socket: std.posix.socket_t,

pub fn init( path: []const u8 ) !Self {
	if ( path.len > 108 )
		return error.PathTooLong;

	const sock = try std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK, std.posix.PROT.NONE);
	errdefer std.posix.close( sock );

	var addr = std.posix.sockaddr.un{ .path = undefined };
	@memcpy( addr.path[0..path.len], path );
	try std.posix.connect( sock, @ptrCast(&addr), @sizeOf(@TypeOf(addr)) );

	return .{
		.path = path,
		.socket = sock,
	};
}

pub fn deinit( self: *Self ) void {
	std.posix.close( self.socket );
}

pub fn send( self: *Self, buf: []const u8 ) !void {
	// this may fail with `error.WouldBlock`, but our messages should be fairly small so we should be good
	_ = try std.posix.send( self.socket, buf, 0 );
}

pub fn wait( self: *Self, timeout: i32 ) !void {
	var fds: [2]std.os.linux.pollfd = undefined;
	fds[0].fd = self.socket;
	fds[0].events = 0;
	fds[0].revents = 0;
	_ = try std.posix.poll( fds[0..1], timeout );
}

pub fn read( self: *Self, buffer: []u8 ) ![]const u8 {
	var offset: usize = 0;
	while ( true ) {
		const chunk = std.posix.recv( self.socket, buffer[offset..], 0 ) catch |err| {
			if ( err == error.WouldBlock ) {
				break;
			}
			// its an actual error
			return err;
		};
		offset += chunk;
	}

	if ( offset == 0 ) {
		return buffer[0..0];
	}

	return buffer[0..(offset - 1)];
}

pub fn readAlloc( self: *Self, allocator: std.mem.Allocator ) ![]const u8 {
	var resBuf = std.ArrayList(u8).init( allocator );
	errdefer resBuf.deinit();

	var buffer: [1024]u8 = undefined;

	while ( true ) {
		const chunk = std.posix.recv( self.socket, &buffer, 0 ) catch |err| {
			if ( err == error.WouldBlock ) {
				break;
			}
			// its an actual error
			return err;
		};
		try resBuf.appendSlice( buffer[0..chunk] );
	}

	return resBuf.items;
}

pub fn execute( self: *Self, comptime command: []const u8, flags: []const u8, allocator: std.mem.Allocator ) ![]const u8 {
	comptime {
		const valid: []const []const u8 = &.{ "version", "monitors", "workspaces", "activeworkspace", "workspacerules", "clients", "devices", "decorations", "binds", "activewindow", "layers", "splash", "getoption", "cursorpos", "animations", "instances", "layouts", "configerrors", "rollinglog", "locked", "descriptions" };
		if (! util.inSlice( []const u8, valid, command ) ) {
			@compileError( "Invalid command found in socket executor" );
		}
	}
	var buffer: [256]u8 = undefined;
	const res = try std.fmt.bufPrintZ( &buffer, "{s} {s}", .{ command, flags });
	try self.send( res );
	try self.wait( 1 );
	return try self.readAlloc( allocator );
}
