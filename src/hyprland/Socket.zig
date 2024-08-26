const std = @import("std");
const util = @import("../util.zig");
const Self = @This();

path: []const u8,
stream: ?std.net.Stream,

pub fn init( path: []const u8 ) !Self {
	if ( path.len > 108 )
		return error.PathTooLong;

	return .{
		.path = path,
		.stream = null
	};
}

pub fn deinit( self: *Self ) void {
	self.close();
}

pub fn connect( self: *Self ) !void {
	self.stream = try std.net.connectUnixSocket( self.path );
}

pub fn close( self: *Self ) void {
	if ( self.stream ) |stream| {
		stream.close();
		self.stream = null;
	}
}

pub fn send( self: *Self, buf: []const u8 ) !void {
	if ( self.stream == null ) {
		return error.NotConnected;
	}

	// this may fail with `error.WouldBlock`, but our messages should be fairly small so we should be good
	try self.stream.?.writeAll( buf );
}

pub fn wait( self: *Self, timeout: f32 ) !void {
	if ( self.stream == null ) {
		return error.NotConnected;
	}

	var fds: [2]std.os.linux.pollfd = undefined;
	fds[0].fd = self.stream.?.handle;
	fds[0].events = std.os.linux.POLL.RDNORM;
	fds[0].revents = 0;
	_ = try std.posix.poll( fds[0..1], @intFromFloat( timeout * 1000 ) );
}

pub fn read( self: *Self, buffer: []u8 ) ![]const u8 {
	if ( self.stream == null ) {
		return error.NotConnected;
	}

	var reader = self.stream.?.reader();
	return reader.readUntilDelimiter( buffer, '\n' );
}

pub fn readAlloc( self: *Self, allocator: std.mem.Allocator ) ![]const u8 {
	if ( self.stream == null ) {
		return error.NotConnected;
	}

	var result = try std.ArrayList(u8).initCapacity( allocator, 256 );
	errdefer result.deinit();

	var reader = self.stream.?.reader();
	try reader.streamUntilDelimiter( result.writer(), '\n', null );

	result.shrinkAndFree( result.items.len );
	return result.items;
}

pub fn execute( self: *Self, comptime command: []const u8, args: []const u8, allocator: std.mem.Allocator ) ![]const u8 {
	comptime {
		// TODO: Make this error-check args too
		const valid: []const []const u8 = &.{ "version", "monitors", "workspaces", "activeworkspace", "workspacerules", "clients", "devices", "decorations", "binds", "activewindow", "layers", "splash", "getoption", "cursorpos", "animations", "instances", "layouts", "configerrors", "rollinglog", "locked", "descriptions" };
		if (! util.inSlice( []const u8, valid, command ) ) {
			@compileError( "Invalid command found in socket executor" );
		}
	}

	// build command
	var backBuffer: [256]u8 = undefined;
	var cmdBuffer = std.ArrayListUnmanaged(u8).initBuffer( &backBuffer );
	var writer = cmdBuffer.fixedWriter();
	try writer.print( "j/" ++ command, .{ } );
	if ( args.len > 1 ) {
		try writer.print( " {s}", .{ args } );
	}

	// send request & read output
	std.log.debug( "Executing request `{s}`", .{ cmdBuffer.items } );
	try self.connect();
	defer self.close();
	try self.send( cmdBuffer.items );
	try self.wait( 0.5 );
	return try self.readAlloc( allocator );
}
