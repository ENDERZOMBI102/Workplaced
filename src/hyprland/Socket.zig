const std = @import("std");
const util = @import("../util.zig");
const Self = @This();

path: []const u8,
socket: ?std.posix.socket_t,

pub fn init( path: []const u8 ) !Self {
	if ( path.len > 108 )
		return error.PathTooLong;

	return .{
		.path = path,
		.socket = null
	};
}

pub fn deinit( self: *Self ) void {
	self.close();
}

pub fn connect( self: *Self ) !void {
	const sock = try std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK, std.posix.PROT.NONE);
	errdefer std.posix.close( sock );

	var addr = std.posix.sockaddr.un{ .path = undefined };
	@memcpy( addr.path[0..self.path.len], self.path );
	try std.posix.connect( sock, @ptrCast(&addr), @sizeOf(@TypeOf(addr)) );
	self.socket = sock;
}

pub fn close( self: *Self ) void {
	if ( self.socket ) |sock| {
		std.posix.close( sock );
		self.socket = null;
	}
}

pub fn send( self: *Self, buf: []const u8 ) !void {
	if ( self.socket == null ) {
		return error.NotConnected;
	}
	// this may fail with `error.WouldBlock`, but our messages should be fairly small so we should be good
	_ = try std.posix.send( self.socket orelse unreachable, buf, 0 );
}

pub fn wait( self: *Self, timeout: f32 ) !void {
	if ( self.socket == null ) {
		return error.NotConnected;
	}

	var fds: [2]std.os.linux.pollfd = undefined;
	fds[0].fd = self.socket orelse unreachable;
	fds[0].events = std.os.linux.POLL.RDNORM;
	fds[0].revents = 0;
	_ = try std.posix.poll( fds[0..1], @intFromFloat( timeout * 1000 ) );
}

pub fn read( self: *Self, buffer: []u8 ) ![]const u8 {
	if ( self.socket == null ) {
		return error.NotConnected;
	}

	var offset: usize = 0;
	while ( true ) {
		const chunk = std.posix.recv( self.socket orelse unreachable, buffer[offset..], 0 ) catch |err| {
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
	if ( self.socket == null ) {
		return error.NotConnected;
	}

	var result = std.ArrayList(u8).init( allocator );
	errdefer result.deinit();
	try result.ensureTotalCapacity( 256 );

	var buffer: [1024]u8 = undefined;
	while ( true ) {
		const chunk = std.posix.recv( self.socket orelse unreachable, &buffer, 0 ) catch |err| {
			if ( err == error.WouldBlock ) {
				break;
			}
			// its an actual error
			return err;
		};

		if ( chunk == 0 ) {
			break;
		}

		try result.appendSlice( buffer[0..chunk] );
	}

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
	try writer.print( "j/{s}", .{ command } );
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
