const std = @import("std");

pub const Event = union(enum) {
	/// emitted on workspace change. Is emitted ONLY when a user requests a workspace change, and is not emitted on mouse movements (see activemon)
	workspace: struct { name: []const u8 },
	/// emitted on workspace change. Is emitted ONLY when a user requests a workspace change, and is not emitted on mouse movements (see activemon)
	workspacev2: struct { id: i32, name: []const u8 },
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
	createworkspacev2: struct { id: i32, name: []const u8 },
	/// emitted when a workspace is destroyed.
	destroyworkspace: struct { name: []const u8 },
	/// emitted when a workspace is destroyed.
	destroyworkspacev2: struct { id: i32, name: []const u8 },
	/// emitted when a workspace is moved to a different monitor, both names.
	moveworkspace: struct { workspace: []const u8, monitor: []const u8 },
	/// emitted when a workspace is moved to a different monitor
	moveworkspacev2: struct { workspace: struct { id: u32, name: []const u8 }, monitor: []const u8 },
	/// emitted when a workspace is renamed
	renameworkspace: struct { id: i32, newname: []const u8 },
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
	movewindowv2: struct { address: []const u8, workspace: struct { id: i32, name: []const u8 } },
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
	togglegroup: struct { state: bool, addresses: []const u8 },
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

	pub fn parse( raw: []const u8 ) !Event {
		const sep = std.mem.indexOf( u8, raw, ">>" ) orelse return error.Illegal;
		const kind = raw[0..sep];
		const args = raw[(sep+2)..];

		switch ( kind[0] ) {
			'a' => switch ( kind[6] ) {
				'w' => switch ( kind.len ) {
					14 => {  // activewinodow2
						return .{ .activewindowv2 = .{ .address = args } };
					},
					12 => {  // activewindow
						const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
						return .{ .activewindow = .{ .class = args[0..argSep], .title = args[argSep+1..] } };
					},
					else => { },
				},
				's' => {  // activespecial
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .activespecial = .{ .workspace = args[0..argSep], .monitor = args[argSep+1..] } };
				},
				'l' => {  // activelayout
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .activelayout = .{ .keyboard = args[0..argSep], .layout = args[argSep+1..] } };
				},
				else => { },
			},
			'c' => switch ( kind.len ) {
				11 => {  // closewindow
					return .{ .closewindow = .{ .address = args } };
				},
				10 => {  // closelayer
					return .{ .closelayer = .{ .namespace = args } };
				},
				14 => {  // configreloaded
					return .configreloaded;
				},
				15 => {  // createworkspace
					return .{ .createworkspace = .{ .name = args } };
				},
				17 => {  // createworkspacev2
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .createworkspacev2 = .{ .id = std.fmt.parseInt( i32, args[0..argSep], 10 ) catch -1, .name = args[argSep+1..] } };
				},
				18 => {  // changefloatingmode
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .changefloatingmode = .{ .address = args[0..argSep], .floating = args[argSep+1] == '1' } };
				},
				else => { },
			},
			'd' => switch ( kind.len ) {
				16 => {  // destroyworkspace
					return .{ .destroyworkspace = .{ .name = args } };
				},
				18 => {  // destroyworkspacev2
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .destroyworkspacev2 = .{ .id = std.fmt.parseInt( i32, args[0..argSep], 10 ) catch -1, .name = args[argSep+1..] } };
				},
				else => { },
			},
			'f' => switch ( kind[1] ) {
				'u' => {  // fullscreen
					return .{ .fullscreen = .{ .state = args[0] == '1' } };
				},
				'o' => {  // focusedmon
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .focusedmon = .{ .monname = args[0..argSep], .workspace = args[argSep+1..] } };
				},
				else => { },
			},
			'i' => switch ( kind.len ) {
				15 => {  // ignoregrouplock
					return .{ .ignoregrouplock= .{ .value = args[0] == '1' } };
				},
				else => { },
			},
			'l' => switch ( kind.len ) {
				10 => {  // lockgroups
					return .{ .lockgroups = .{ .value = args[0] == '1' } };
				},
				else => { },
			},
			'm' => switch ( kind.len ) {
				15 => {  // moveworkspacev2
					const idSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					const id = try std.fmt.parseInt( u32, args[0..idSep], 10 );
					const nameSep = idSep+1 + (std.mem.indexOf( u8, args[idSep+1..], "," ) orelse return error.Illegal);
					const name = args[idSep+1..nameSep];
					const monitor = args[nameSep+1..];

					return .{ .moveworkspacev2 = .{ .workspace = .{ .id = id, .name = name }, .monitor = monitor } };
				},
				14 => switch ( kind[7] ) {
					'r' => {  // monitorremoved
						return .{ .monitorremoved = .{ .name = args } };
					},
					'o' => {  // moveoutofgroup
						return .{ .moveoutofgroup = .{ .address = args } };
					},
					'a' => {  // monitoraddedv2
						const idSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
						const id = try std.fmt.parseInt( u32, args[0..idSep], 10 );
						const nameSep = idSep+1 + (std.mem.indexOf( u8, args[idSep+1..], "," ) orelse return error.Illegal);
						const name = args[idSep+1..nameSep];
						const description = args[nameSep+1..];

						return .{ .monitoraddedv2 = .{ .id = id, .name = name, .description = description } };
					},
					else => { },
				},
				13 => switch ( kind[4] ) {
					'w' => {  // moveworkspace
						const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
						return .{ .moveworkspace = .{ .workspace = args[0..argSep], .monitor = args[argSep+1..] } };
					},
					'i' => {  // moveintogroup
						return .{ .moveintogroup = .{ .address = args } };
					},
					else => { },
				},
				12 => switch ( kind[4] ) {
					'w' => {  // movewindowv2
						const addrSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
						const addr = args[0..addrSep];
						const idSep = addrSep+1 + (std.mem.indexOf( u8, args[addrSep+1..], "," ) orelse return error.Illegal);
						const id = try std.fmt.parseInt( i32, args[addrSep+1..idSep], 10 );
						const name = args[idSep+1..];

						return .{ .movewindowv2 = .{ .address = addr, .workspace = .{ .id = id, .name = name } } };
					},
					't' => {  // monitoradded
						return .{ .monitoradded = .{ .name = args } };
					},
					else => { },
				},
				10 => {  // movewindow
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .movewindow = .{ .address = args[0..argSep], .workspace = args[argSep+1..] } };
				},
				8 => {  // minimize
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .minimize = .{ .address = args[0..argSep], .minimized = args[argSep+1..][0] == '1' } };
				},
				else => { },
			},
			'o' => switch ( kind.len ) {
				10 => {  // openwindow
					const addrSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					const addr = args[0..addrSep];
					const workspaceSep = addrSep+1 + (std.mem.indexOf( u8, args[addrSep+1..], "," ) orelse return error.Illegal);
					const workspace = args[addrSep+1..workspaceSep];
					const classSep = workspaceSep+1 + (std.mem.indexOf( u8, args[workspaceSep+1..], "," ) orelse return error.Illegal);
					const class = args[workspaceSep+1..classSep];
					const title = args[classSep+1..];

					return .{ .openwindow = .{ .address = addr, .workspace = workspace, .class =class, .title = title } };
				},
				9 => {  // openlayer
					return .{ .openlayer = .{ .namespace = args } };
				},
				else => { },
			},
			'p' => switch ( kind.len ) {
				3 => {  // pin
					return .{ .pin = .{ .address = args[0..args.len-2], .state = args[args.len-1] == '1' } };
				},
				else => { },
			},
			'r' => switch ( kind.len ) {
				15 => {  // renameworkspace
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .renameworkspace = .{ .id = std.fmt.parseInt( i32, args[0..argSep], 10 ) catch -1, .newname = args[argSep+1..] } };
				},
				else => { },
			},
			's' => switch ( kind.len ) {
				10 => {  // screencast
					return .{
						.screencast = .{
							.state = args[0] == '1',
							.owner = switch ( args[2] ) {
								'm' => .monitor,
								'w' => .window,
								else => return error.Illegal,
							}
						}
					};
				},
				6 => {  // submap
					return .{ .submap = .{ .submap = args } };
				},
				else => { },
			},
			't' => switch ( kind.len ) {
				11 => {  // togglegroup
					return .{ .togglegroup = .{ .state = args[0] == '1', .addresses = args[2..] } };
				},
				else => { },
			},
			'u' => switch ( kind.len ) {
				6 => {  // urgent
					return .{ .urgent = .{ .address = args } };
				},
				else => { },
			},
			'w' => switch ( kind[4] ) {
				's' => if ( kind.len == 11 ) {  // workspacev2
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .workspacev2 = .{ .id = std.fmt.parseInt( i32, args[0..argSep], 10 ) catch -1, .name = args[argSep+1..] } };
				} else {  // workspace
					return .{ .workspace = .{ .name = args } };
				},
				'o' => if ( kind.len == 13 ) {  // windowtitlev2
					const argSep = std.mem.indexOf( u8, args, "," ) orelse return error.Illegal;
					return .{ .windowtitlev2 = .{ .address = args[0..argSep], .title = args[argSep+1..] } };
				} else {  // windowtitle
					return .{ .windowtitle = .{ .address = args } };
				},
				else => { },
			},
			else => { },
		}

		return error.Unknown;
	}

	pub fn format( self: Event, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype ) !void {
		switch ( self ) {
			.workspace => |val| { try writer.print( "workspace{{ name=`{s}` }}", .{ val.name } ); },
			.workspacev2 => |val| { try writer.print( "workspacev2{{ id={}, name=`{s}` }}", .{ val.id, val.name } ); },
			.focusedmon => |val| { try writer.print( "focusedmon{{ monitorName=`{s}`, workspace=`{s}` }}", .{ val.monname, val.workspace } ); },
			.activewindow => |val| { try writer.print( "activewindow{{ class=`{s}`, title=`{s}` }}", .{ val.class, val.title } ); },
			.activewindowv2 => |val| { try writer.print( "activewindowv2{{ address=`{s}` }}", .{ val.address } ); },
			.fullscreen => |val| { try writer.print( "fullscreen{{ state={} }}", .{ val.state } ); },
			.monitorremoved => |val| { try writer.print( "monitorremoved{{ name=`{s}` }}", .{ val.name } ); },
			.monitoradded => |val| { try writer.print( "monitoradded{{ name=`{s}` }}", .{ val.name } ); },
			.monitoraddedv2 => |val| { try writer.print( "monitoraddedv2{{ id=`{}`, name=`{s}`, description=`{s}` }}", .{ val.id, val.name, val.description } ); },
			.createworkspace => |val| { try writer.print( "createworkspace{{ name=`{s}` }}", .{ val.name } ); },
			.createworkspacev2 => |val| { try writer.print( "createworkspacev2{{ id={}, name=`{s}` }}", .{ val.id, val.name } ); },
			.destroyworkspace => |val| { try writer.print( "destroyworkspace{{ name=`{s}` }}", .{ val.name } ); },
			.destroyworkspacev2 => |val| { try writer.print( "destroyworkspacev2{{ id={}, name=`{s}` }}", .{ val.id, val.name } ); },
			.moveworkspace => |val| { try writer.print( "moveworkspace{{ monitor=`{s}`, workspace=`{s}` }}", .{ val.monitor, val.workspace } ); },
			.moveworkspacev2 => |val| { try writer.print( "moveworkspacev2{{ monitor=`{s}` }}", .{ val.monitor } ); },
			.renameworkspace => |val| { try writer.print( "renameworkspace{{ id={}, newname=`{s}` }}", .{ val.id, val.newname } ); },
			.activespecial => |val| { try writer.print( "activespecial{{ monitor=`{s}`, workspace=`{s}` }}", .{ val.monitor, val.workspace } ); },
			.activelayout => |val| { try writer.print( "activelayout{{ keyboard=`{s}`, layout=`{s}` }}", .{ val.keyboard, val.layout } ); },
			.openwindow => |val| { try writer.print( "openwindow{{ address=`{s}`, workspace=`{s}`, class=`{s}`, title=`{s}` }}", .{ val.address, val.workspace, val.class, val.title } ); },
			.closewindow => |val| { try writer.print( "closewindow{{ address=`{s}` }}", .{ val.address } ); },
			.movewindow => |val| { try writer.print( "movewindow{{ address=`{s}`, workspace=`{s}` }}", .{ val.address, val.workspace } ); },
			.movewindowv2 => |val| { try writer.print( "movewindowv2{{ address=`{s}`, workspace={{ id={}, name=`{s}` }} }}", .{ val.address, val.workspace.id, val.workspace.name } ); },
			.openlayer => |val| { try writer.print( "openlayer{{ namesapce=`{s}` }}", .{ val.namespace } ); },
			.closelayer => |val| { try writer.print( "closelayer{{ namespace=`{s}` }}", .{ val.namespace } ); },
			.submap => |val| { try writer.print( "submap{{ submap=`{s}` }}", .{ val.submap } ); },
			.changefloatingmode => |val| { try writer.print( "changefloatingmode{{ address=`{s}`, floating={} }}", .{ val.address, val.floating } ); },
			.urgent => |val| { try writer.print( "urgent{{ address=`{s}` }}", .{ val.address } ); },
			.minimize => |val| { try writer.print( "minimize{{ address=`{s}`, minimized={} }}", .{ val.address, val.minimized } ); },
			.screencast => |val| { try writer.print( "screencast{{ state={}, owner=`{s}` }}", .{ val.state, @tagName(val.owner) } ); },
			.windowtitle => |val| { try writer.print( "windowtitle{{ address=`{s}` }}", .{ val.address } ); },
			.windowtitlev2 => |val| { try writer.print( "windowtitlev2{{ address=`{s}`, title=`{s}` }}", .{ val.address, val.title } ); },
			.togglegroup => |val| { try writer.print( "togglegroup{{ state={}, addresses=`{s}` }}", .{ val.state, val.addresses } ); },
			.moveintogroup => |val| { try writer.print( "moveintogroup{{ address=`{s}` }}", .{ val.address } ); },
			.moveoutofgroup => |val| { try writer.print( "moveoutofgroup{{ address=`{s}` }}", .{ val.address } ); },
			.ignoregrouplock => |val| { try writer.print( "ignoregrouplock{{ value={} }}", .{ val.value } ); },
			.lockgroups => |val| { try writer.print( "lockgroups{{ value={} }}", .{ val.value } ); },
			.configreloaded => try writer.print( "configreloaded", .{} ),
			.pin => |val| { try writer.print( "pin{{ address=`{s}`, state={} }}", .{ val.address, val.state } ); },
		}
	}
};
pub const EventHandler = *const fn( Event ) void;
