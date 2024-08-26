const std = @import("std");
const Self = @This();
const Socket = @import("Socket.zig");
const Window = @import("Window.zig");
const eventZig = @import("event.zig");
pub const Event = eventZig.Event;
pub const EventHandler = eventZig.EventHandler;


allocator: std.mem.Allocator,
signature: []const u8,
recvSock: Socket,
sendSock: Socket,
eventHandler: EventHandler,

pub fn init( allocator: std.mem.Allocator, handler: EventHandler, sig: []const u8 ) !Self {
	const xdgRuntime = std.posix.getenv( "XDG_RUNTIME_DIR" ) orelse unreachable;

	// create sockets
	const eventPath = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket2.sock", .{ xdgRuntime, sig } );
	var eventSock = try Socket.init( eventPath );
	try eventSock.connect();  // must connect
	const commaPath = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket.sock" , .{ xdgRuntime, sig } );
	const commaSock = try Socket.init( commaPath );

	// load env info

	return .{
		.allocator = allocator,
		.signature = sig,
		.sendSock = commaSock,
		.recvSock = eventSock,
		.eventHandler = handler,
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
		if ( event.len != 0 ) {
			const evt = Event.parse( event ) catch |err| {
				std.log.err( "Failed to parse event string: `{s}` -> {}", .{ event, err } );
				return;
			};
			self.eventHandler( evt );
		}
	}
}

pub fn getWindows( self: *Self ) ![]Window {
	const res = try self.sendSock.execute( "clients", "", self.allocator );
	defer self.allocator.free( res );
	std.log.debug( "{s}", .{ res } );
	const parsed = try std.json.parseFromSlice( []Window, self.allocator, res, .{ } );
	defer parsed.deinit();

	const result = try self.allocator.alloc( Window, parsed.value.len );
	@memcpy( result, parsed.value );
	return result;
}
