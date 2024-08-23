const std = @import("std");
const Self = @This();

/// String representation of a hexadecimal number, unique identifier for the window.
address: []const u8,
/// Unknown.
mapped: bool,
/// Unknown.
hidden: bool,
/// Absolute X-coordinate of the window on the monitor (in pixels).
x: i32,
/// Absolute Y-coordinate of the window on the monitor (in pixels).
y: i32,
/// Width of the window (in pixels).
width: u32,
/// Height of the window (in pixels).
height: u32,
/// Numeric ID of the workspace which the window is on.
workspace_id: u32,
/// Name of the workspace which the window is on.
workspace_name: []const u8,
/// Whether or not this is a floating window.
floating: bool,
/// Numeric ID of the monitor which the window is on.
monitor_id: u32,
/// Window manager class assigned to this window.
wm_class: []const u8,
/// Current title of the window.
title: []const u8,
/// Window manager class when the window was created.
initial_wm_class: []const u8,
/// Title when the window was created.
initial_title: []const u8,
/// Process ID of the process the window is assigned to.
pid: u32,
/// Whether or not the window is using xwayland to be displayed.
xwayland: bool,
/// Unknown.
pinned: bool,
/// Whether or not the window is in fullscreen mode.
fullscreen: bool,
/// Unknown.
fullscreen_mode: u32,
/// Unknown.
fake_fullscreen: bool,

pub fn init() Self {

}



