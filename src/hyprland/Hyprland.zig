const std = @import("std");
const Self = @This();
const Socket = @import("Socket.zig");
const Window = @import("Window.zig");
const eventZig = @import("event.zig");
pub const Event = eventZig.Event;
pub const EventHandler = eventZig.EventHandler;
const Logger = std.log.scoped(.Hyprland);

allocator: std.mem.Allocator,
signature: []const u8,
recvSock: Socket,
sendSock: Socket,
eventHandler: EventHandler,

pub fn init( allocator: std.mem.Allocator, handler: EventHandler, xdgRuntimeDir: []const u8, sig: []const u8 ) !Self {
	// create sockets
	const eventPath = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket2.sock", .{ xdgRuntimeDir, sig } );
	var eventSock = try Socket.init( eventPath );
	try eventSock.connect();  // must connect
	const commaPath = try std.fmt.allocPrint( allocator, "{s}/hypr/{s}/.socket.sock" , .{ xdgRuntimeDir, sig } );
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

pub fn tick( self: *Self ) !void {
	var buffer: [2048]u8 = undefined;
	while ( true ) {
		const event = try self.recvSock.read( &buffer );
		if ( event.len == 0 ) {
			break;
		}

		const evt = Event.parse( event ) catch |err| {
			Logger.err( "Failed to parse event string: `{s}` -> {}", .{ event, err } );
			return;
		};
		Logger.debug( "Received event: {?}", .{ evt } );

		self.eventHandler( evt );
	}
}

pub fn getWindows( self: *Self ) ![]Window {
	const res = try self.sendSock.execute( "clients", "", self.allocator );
	defer self.allocator.free( res );
	Logger.debug( "{s}", .{ res } );
	const parsed = try std.json.parseFromSlice( []Window, self.allocator, res, .{ } );
	defer parsed.deinit();

	const result = try self.allocator.alloc( Window, parsed.value.len );
	@memcpy( result, parsed.value );
	return result;
}
