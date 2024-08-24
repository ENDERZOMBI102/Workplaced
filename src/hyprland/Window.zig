const std = @import("std");
const Self = @This();

/// String representation of a hexadecimal number, unique identifier for the window.
address: []const u8,
/// Unknown.
mapped: bool,
/// Unknown.
hidden: bool,
/// Absolute coordinates of the window on the monitor (in pixels).
at: struct{ i32, i32 },
/// Size of the window (in pixels).
size: struct{ u32, u32 },
/// The workspace on which the window is located on.
workspace: struct {
	/// Numeric ID of the workspace.
	id: u32,
	/// Name of the workspace.
	name: []const u8,
},
/// Whether or not this is a floating window.
floating: bool,
/// Whether or not this window is pseudo-tiled.
pseudo: bool,
/// Numeric ID of the monitor which the window is on.
monitor: u32,
/// Window manager class assigned to this window.
class: []const u8,
/// Current title of the window.
title: []const u8,
/// Window manager class when the window was created.
initialClass: []const u8,
/// Title when the window was created.
initialTitle: []const u8,
/// Process ID of the process the window is assigned to.
pid: u32,
/// Whether or not the window is using xwayland to be displayed.
xwayland: bool,
/// Whether or not the window is pinned.
pinned: bool,
/// Whether or not the window is in fullscreen mode.
fullscreen: bool,
/// Unknown.
fullscreenMode: u32,
/// Unknown.
fakeFullscreen: bool,
/// Unknown.
grouped: [][]const u8,
/// Unknown.
tags: [][]const u8,
/// Unknown.
swallowing: []const u8,
/// Unknown.
focusHistoryID: i32,


