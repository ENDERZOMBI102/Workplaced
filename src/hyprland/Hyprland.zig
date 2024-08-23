const std = @import("std");
const Self = @This();
const Socket = @import("Socket.zig");
const Window = @import("Window.zig");


allocator: std.mem.Allocator,
signature: []const u8,
recvSock: Socket,
sendSock: Socket,

pub fn init( allocator: std.mem.Allocator, sig: []const u8 ) !Self {
	const xdgRuntime = std.posix.getenv( "XDG_RUNTIME_DIR" ) orelse unreachable;

	const eventSock = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket2.sock", .{ xdgRuntime, sig } );
	const commaSock = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket.sock" , .{ xdgRuntime, sig } );

	return .{
		.allocator = allocator,
		.signature = sig,
		.sendSock = try Socket.init( commaSock ),
		.recvSock = try Socket.init( eventSock ),
	};
}

pub fn deinit( self: *Self ) void {
	self.sendSock.deinit();
	self.allocator.free( self.sendSock.path );
	self.recvSock.deinit();
	self.allocator.free( self.recvSock.path );
}

pub fn listen( self: *Self ) !void {
	var buffer: [2048]u8 = undefined;
	while ( true ) {
		const event = try self.recvSock.read( &buffer );
		if ( event.len != 0 ){
			try self.handleEvent( event );
		}
	}
}

pub fn getWindows( self: *Self ) ![]Window {
	const res = try self.sendSock.execute( "clients", "-j", self.allocator );
	std.log.info( "res={s}", .{ res });
	// const windows_data = json.loads( self.command_socket.send_command('clients', flags=['-j']) );
	// return [Window(window_data, self) for window_data in windows_data]
	return &.{ };
}

fn handleEvent( self: *Self, event: []const u8 ) !void {
	var list = std.ArrayList(u8).init( self.allocator );
	defer list.deinit();

	try std.json.encodeJsonStringChars( event, .{ }, list.writer() );
	std.log.info( "received event: {s}", .{ list.items } );
	if ( event[0] == 'c' ) {
		_ = try self.getWindows();
	}
}


