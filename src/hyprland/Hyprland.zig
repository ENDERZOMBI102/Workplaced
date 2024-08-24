const std = @import("std");
const Self = @This();
const Socket = @import("Socket.zig");
const Window = @import("Window.zig");

pub const Event = union(enum) {
	/// emitted on workspace change. Is emitted ONLY when a user requests a workspace change, and is not emitted on mouse movements (see activemon)
	workspace: struct { name: []const u8 },
	/// emitted on workspace change. Is emitted ONLY when a user requests a workspace change, and is not emitted on mouse movements (see activemon)
	workspacev2: struct { id: u32, name: []const u8 },
	/// emitted on the active monitor being changed.
	focusedmon: struct { monname: []const u8, workspace: []const u8 },
	/// emitted on the active window being changed.
	activewindow: struct { class: []const u8, title: []const u8 },
	/// emitted on the active window being changed.
	activewindowv2: struct { address: []const u8 },
	/// emitted when a fullscreen status of a window changes.
	fullscreen: struct { state: bool },
	/// emitted when a monitor is removed (disconnected)
	monitorremoved: struct { name: []const u8 },
	/// emitted when a monitor is added (connected)
	monitoradded: struct { name: []const u8 },
	/// emitted when a monitor is added (connected)
	monitoraddedv2: struct { id: u32, name: []const u8, description: []const u8 },
	/// emitted when a workspace is created.
	createworkspace: struct { name: []const u8 },
	/// emitted when a workspace is created.
	createworkspacev2: struct { id: u32, name: []const u8 },
	/// emitted when a workspace is destroyed.
	destroyworkspace: struct { name: []const u8 },
	/// emitted when a workspace is destroyed.
	destroyworkspacev2: struct { id: u32, name: []const u8 },
	/// emitted when a workspace is moved to a different monitor, both names.
	moveworkspace: struct { workspace: []const u8, monitor: []const u8 },
	/// emitted when a workspace is moved to a different monitor
	moveworkspacev2: struct { workspace: struct { id: u32, name: []const u8 }, monitor: []const u8 },
	/// emitted when a workspace is renamed
	renameworkspace: struct { id: u32, name: []const u8 },
	/// emitted when the special workspace opened in a monitor changes (closing results in an empty WORKSPACENAME)
	activespecial: struct { workspace: []const u8, monitor: []const u8 },
	/// emitted on a layout change of the active keyboard
	activelayout: struct { keyboard: []const u8, layout: []const u8 },
	/// emitted when a window is opened
	openwindow: struct { address: []const u8, workspace: []const u8, class: []const u8, title: []const u8 },
	/// emitted when a window is closed
	closewindow: struct { address: []const u8 },
	/// emitted when a window is moved to a workspace
	movewindow: struct { address: []const u8, workspace: []const u8 },
	/// emitted when a window is moved to a workspace
	movewindowv2: struct { address: []const u8, workspace: struct { id: u32, name: []const u8 } },
	/// emitted when a layerSurface is mapped
	openlayer: struct { namespace: []const u8 },
	/// emitted when a layerSurface is unmapped
	closelayer: struct { namespace: []const u8 },
	/// emitted when a keybind submap changes. Empty means default.
	submap: struct { submap: []const u8 },
	/// emitted when a window changes its floating mode. FLOATING is either 0 or 1.
	changefloatingmode: struct { address: []const u8, floating: bool },
	/// emitted when a window requests an urgent state
	urgent: struct { address: []const u8 },
	/// emitted when a window requests a change to its minimized state. MINIMIZED is either 0 or 1.
	minimize: struct { address: []const u8, minimized: bool },
	/// emitted when a screencopy state of a client changes. Keep in mind there might be multiple separate clients. State is 0/1, owner is 0 - monitor share, 1 - window share
	screencast: struct { state: bool, owner: enum { monitor, window } },
	/// emitted when a window title changes.
	windowtitle: struct { address: []const u8 },
	/// emitted when a window title changes.
	windowtitlev2: struct { address: []const u8, title: []const u8 },
	/// emitted when togglegroup command is used. returns state,handle where the state is a toggle status and the handle is one or more window addresses separated by a comma e.g. 0,0x64cea2525760,0x64cea2522380 where 0 means that a group has been destroyed and the rest informs which windows were part of it.
	togglegroup: struct { state: bool, handle: []const u8 },
	/// emitted when the window is merged into a group. returns the address of a merged window
	moveintogroup: struct { address: []const u8 },
	/// emitted when the window is removed from a group. returns the address of a removed window
	moveoutofgroup: struct { address: []const u8 },
	/// emitted when ignoregrouplock is toggled.
	ignoregrouplock: struct { value: bool },
	/// emitted when lockgroups is toggled.
	lockgroups: struct { value: bool },
	/// emitted when the config is done reloading
	configreloaded,
	/// emitted when a window is pinned or unpinned
	pin: struct { address: []const u8, state: bool },

	fn parse( raw: []const u8 ) !Event {
		const sep = std.mem.indexOf( u8, raw, ">>" ) orelse return error.Unknown;
		const kind = raw[0..sep];
		const args = raw[(sep+2)..];
		switch ( kind[0] ) {
			'c' => switch ( kind[1] ) {
				'h' => {  // changefloatingmode
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .changefloatingmode = .{ .address = args[0..argSep], .floating = args[argSep + 1] == '1' } };
				},
				'o' => {  // configreloaded
					return .configreloaded;
				},
				else => { },
			},
			else => { },
		}
		// createworkspace
		// createworkspacev2
		// closewindow
		// closelayer

		return error.Unknown;
	}

	pub fn format( self: Event, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype ) !void {
		switch ( self ) {
			.workspace => |val| { try writer.print( "Event::workspace {?}", .{ val } ); },
			.workspacev2 => |val| { try writer.print( "Event::workspacev2 {?}", .{ val } ); },
			.focusedmon => |val| { try writer.print( "Event::focusedmon {?}", .{ val } ); },
			.activewindow => |val| { try writer.print( "Event::activewindow {?}", .{ val } ); },
			.activewindowv2 => |val| { try writer.print( "Event::activewindowv2 {?}", .{ val } ); },
			.fullscreen => |val| { try writer.print( "Event::fullscreen {?}", .{ val } ); },
			.monitorremoved => |val| { try writer.print( "Event::monitorremoved {?}", .{ val } ); },
			.monitoradded => |val| { try writer.print( "Event::monitoradded {?}", .{ val } ); },
			.monitoraddedv2 => |val| { try writer.print( "Event::monitoraddedv2 {?}", .{ val } ); },
			.createworkspace => |val| { try writer.print( "Event::createworkspace {?}", .{ val } ); },
			.createworkspacev2 => |val| { try writer.print( "Event::createworkspacev2 {?}", .{ val } ); },
			.destroyworkspace => |val| { try writer.print( "Event::destroyworkspace {?}", .{ val } ); },
			.destroyworkspacev2 => |val| { try writer.print( "Event::destroyworkspacev2 {?}", .{ val } ); },
			.moveworkspace => |val| { try writer.print( "Event::moveworkspace {?}", .{ val } ); },
			.moveworkspacev2 => |val| { try writer.print( "Event::moveworkspacev2 {?}", .{ val } ); },
			.renameworkspace => |val| { try writer.print( "Event::renameworkspace {?}", .{ val } ); },
			.activespecial => |val| { try writer.print( "Event::activespecial {?}", .{ val } ); },
			.activelayout => |val| { try writer.print( "Event::activelayout {?}", .{ val } ); },
			.openwindow => |val| { try writer.print( "Event::openwindow {?}", .{ val } ); },
			.closewindow => |val| { try writer.print( "Event::closewindow {?}", .{ val } ); },
			.movewindow => |val| { try writer.print( "Event::movewindow {?}", .{ val } ); },
			.movewindowv2 => |val| { try writer.print( "Event::movewindowv2 {?}", .{ val } ); },
			.openlayer => |val| { try writer.print( "Event::openlayer {?}", .{ val } ); },
			.closelayer => |val| { try writer.print( "Event::closelayer {?}", .{ val } ); },
			.submap => |val| { try writer.print( "Event::submap {?}", .{ val } ); },
			.changefloatingmode => |val| { try writer.print( "Event::changefloatingmode{{ .address=0x{s}, .floating={?} }}", .{ val.address, val.floating } ); },
			.urgent => |val| { try writer.print( "Event::urgent {?}", .{ val } ); },
			.minimize => |val| { try writer.print( "Event::minimize {?}", .{ val } ); },
			.screencast => |val| { try writer.print( "Event::screencast {?}", .{ val } ); },
			.windowtitle => |val| { try writer.print( "Event::windowtitle {?}", .{ val } ); },
			.windowtitlev2 => |val| { try writer.print( "Event::windowtitlev2 {?}", .{ val } ); },
			.togglegroup => |val| { try writer.print( "Event::togglegroup {?}", .{ val } ); },
			.moveintogroup => |val| { try writer.print( "Event::moveintogroup {?}", .{ val } ); },
			.moveoutofgroup => |val| { try writer.print( "Event::moveoutofgroup {?}", .{ val } ); },
			.ignoregrouplock => |val| { try writer.print( "Event::ignoregrouplock {?}", .{ val } ); },
			.lockgroups => |val| { try writer.print( "Event::lockgroups {?}", .{ val } ); },
			.configreloaded => try writer.print( "Event::configreloaded", .{} ),
			.pin => |val| { try writer.print( "Event::pin {?}", .{ val } ); },
		}
	}
};
const EventHandler = *const fn( Event ) void;

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
	const parsed = try std.json.parseFromSlice( []Window, self.allocator, res, .{ } );
	defer parsed.deinit();

	const result = try self.allocator.alloc( Window, parsed.value.len );
	@memcpy( result, parsed.value );
	return result;
}
