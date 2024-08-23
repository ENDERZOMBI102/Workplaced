const std = @import("std");

pub fn Signal(comptime T: type) type {
	const Listener = struct {
		call: fn( T, ?*anyopaque ) anyerror!void,
		ctx: ?*anyopaque,
	};

	return struct {
		const Self = @This();

		code: []const u8,
		listeners: std.ArrayList(Listener),

		pub fn addListener( self: *Self, it: Listener ) void {
			self.listeners.append( it );
		}
	};
}