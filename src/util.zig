const std = @import("std");


pub fn inSlice( comptime T: type, haystack: []const T, needle: T ) bool {
	comptime var impl: fn(T, T) bool = undefined;
	switch ( @typeInfo(T) ) {
		.Pointer => |ptr| {
			// string?
			if ( ptr.child == u8 ) {
				const X = struct {
					fn equal( a: T, b: T ) bool {
						return std.mem.eql( u8, a, b );
					}
				};
				impl = X.equal;
			} else {
				@compileError( "Cannot check for equality of the given type" );
			}
		},
		.Int, .Float, .Bool => {
			const X = struct {
				fn equal( a: T, b: T ) bool {
					return a == b;
				}
			};
			impl = X.equal;
		},
		else => @compileError( "Cannot check for equality of the given type" ),
	}

	for ( haystack ) |thing| {
		if ( impl( thing, needle ) ) {
			return true;
		}
	}
	return false;
}

test "slices" {
	const expect = std.testing.expect;

	try expect( inSlice( []const u8, &.{ "abc", "cba" }, "cba" ) );
	try expect( inSlice( u8, &.{ 1, 2, 3 }, 3 ) );
}
