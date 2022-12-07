//! This is a simple implementation of a Set data structure backed by Zig's `std.AutoArrayHashMap`.

const std = @import("std");

/// A Set backed by an `std.AutoArrayHashMap`.
pub fn Set(comptime T: type) type {
    return struct {
        map: std.AutoArrayHashMap(T, void),

        const Self = @This();

        /// Initialize an empty set.
        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .map = std.AutoArrayHashMap(T, void).init(allocator) };
        }

        /// Initialize a set with items copied from `slice`.
        pub fn fromSlice(allocator: std.mem.Allocator, slice: []const T) !Self {
            var self = init(allocator);
            errdefer self.deinit();

            try self.putSlice(slice);

            return self;
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        /// True if this set contains `item`.
        pub fn contains(self: Self, item: T) bool {
            return self.map.contains(item);
        }

        /// Number of items in this set.
        pub fn count(self: Self) usize {
            return self.map.count();
        }

        /// Returns a new `Set` whose items are the difference of this set and `other`. The difference consists of
        /// all items in this set that are not contained in `other`.
        pub fn diff(
            self: Self,
            allocator: std.mem.Allocator,
            other: Self,
        ) !Self {
            var difference = init(allocator);
            errdefer difference.deinit();

            for (self.items()) |item| {
                if (!other.contains(item)) try difference.put(item);
            }

            return difference;
        }

        /// True if this set and `other` contain the same items.
        pub fn eql(self: Self, other: Self) bool {
            return self.in(other) and self.count() == other.count();
        }

        /// True if all of this Set's items are contained in `other`.
        pub fn in(self: Self, other: Self) bool {
            return for (self.items()) |item| {
                if (!other.contains(item)) break false;
            } else true;
        }

        /// Returns a pointer to the inner `std.AutoArrayHashMap`.
        pub fn inner(self: *Self) *std.AutoArrayHashMap(T, void) {
            return &self.map;
        }

        /// Returns a new `Set` whose items are the intersection of this set and `other`. The intersection
        /// consists of all items that are common to both sets.
        pub fn intersect(
            self: Self,
            allocator: std.mem.Allocator,
            other: Self,
        ) !Self {
            var intersection = init(allocator);
            errdefer intersection.deinit();

            for (self.map.keys()) |item| {
                if (other.contains(item)) try intersection.put(item);
            }

            return intersection;
        }

        /// True if all the items in this set are contained in `other` and `other` has additional items not in this set.
        pub fn isSubset(self: Self, other: Self) bool {
            return self.in(other) and self.count() < other.count();
        }

        /// True if all the items in `other` are contained in this set and this set has additional items.
        pub fn isSuperset(self: Self, other: Self) bool {
            return other.in(self) and other.count() < self.count();
        }

        /// Returns the slice of items contained in this set.
        pub fn items(self: Self) []T {
            return self.map.keys();
        }

        /// Returns the largest item contained in this set.
        pub fn max(self: Self) T {
            return std.mem.max(T, self.items());
        }

        /// Returns the smallest item contained in this set.
        pub fn min(self: Self) T {
            return std.mem.min(T, self.items());
        }

        /// Adds `item` to this set.
        pub fn put(self: *Self, item: T) !void {
            try self.map.put(item, {});
        }

        /// Adds all items in `slice` to this set.
        pub fn putSlice(self: *Self, slice: []const T) !void {
            for (slice) |item| try self.put(item);
        }

        /// Deletes `item` from this set.
        pub fn remove(self: *Self, item: T) bool {
            return self.map.swapRemove(item);
        }

        /// Returns a new `Set` whose items are the symmetric difference of this set and `other`. The symmetric
        /// difference consists of all items that are not common to both sets.
        pub fn symmetric(
            self: Self,
            allocator: std.mem.Allocator,
            other: Self,
        ) !Self {
            var sym = init(allocator);
            errdefer sym.deinit();

            for (self.items()) |item| {
                if (!other.contains(item)) try sym.put(item);
            }

            for (other.items()) |item| {
                if (!self.contains(item)) try sym.put(item);
            }

            return sym;
        }

        /// Returns a new `Set` whose items are the union of this set and `other`. The union is all the items
        /// from both sets.
        pub fn unite(
            self: Self,
            allocator: std.mem.Allocator,
            other: Self,
        ) !Self {
            var u = Set(T).init(allocator);
            errdefer u.deinit();

            try u.putSlice(self.items());
            try u.putSlice(other.items());

            return u;
        }
    };
}

test "intersection" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 3, 4, 5, 6 });
    defer set_b.deinit();

    var intersection = try set_a.intersect(std.testing.allocator, set_b);
    defer intersection.deinit();

    try std.testing.expectEqual(@as(usize, 2), intersection.count());
    try std.testing.expect(intersection.contains(3));
    try std.testing.expect(intersection.contains(4));
    try std.testing.expect(!intersection.contains(6));
}

test "union" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 3, 4, 5, 6 });
    defer set_b.deinit();

    var uni = try set_a.unite(std.testing.allocator, set_b);
    defer uni.deinit();

    try std.testing.expectEqual(@as(usize, 6), uni.count());

    for (set_a.items()) |item| {
        try std.testing.expect(uni.contains(item));
    }

    for (set_b.items()) |item| {
        try std.testing.expect(uni.contains(item));
    }
}

test "difference" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 3, 4, 5, 6 });
    defer set_b.deinit();

    var diff = try set_a.diff(std.testing.allocator, set_b);
    defer diff.deinit();

    try std.testing.expectEqual(@as(usize, 2), diff.count());
    try std.testing.expect(diff.contains(1));
    try std.testing.expect(diff.contains(2));
    try std.testing.expect(!diff.contains(3));
    try std.testing.expect(!diff.contains(4));
    try std.testing.expect(!diff.contains(5));
    try std.testing.expect(!diff.contains(6));
}

test "symmetric difference" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 3, 4, 5, 6 });
    defer set_b.deinit();

    var sym = try set_a.symmetric(std.testing.allocator, set_b);
    defer sym.deinit();

    try std.testing.expectEqual(@as(usize, 4), sym.count());
    try std.testing.expect(sym.contains(1));
    try std.testing.expect(sym.contains(2));
    try std.testing.expect(!sym.contains(3));
    try std.testing.expect(!sym.contains(4));
    try std.testing.expect(sym.contains(5));
    try std.testing.expect(sym.contains(6));
}

test "in" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 3, 4, 5, 6 });
    defer set_b.deinit();
    var set_c = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2 });
    defer set_c.deinit();
    var set_d = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 5, 6 });
    defer set_d.deinit();

    try std.testing.expect(set_c.in(set_a));
    try std.testing.expect(set_d.in(set_b));
    try std.testing.expect(!set_d.in(set_a));
}

test "comparison" {
    var set_a = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_a.deinit();
    var set_b = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set_b.deinit();
    var set_c = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2 });
    defer set_c.deinit();

    try std.testing.expect(set_c.isSubset(set_a));
    try std.testing.expect(set_a.isSuperset(set_c));
    try std.testing.expect(set_a.eql(set_b));
    try std.testing.expect(!set_a.eql(set_c));
}

test "max min" {
    var set = try Set(u8).fromSlice(std.testing.allocator, &[_]u8{ 1, 2, 3, 4 });
    defer set.deinit();

    try std.testing.expectEqual(@as(u8, 4), set.max());
    try std.testing.expectEqual(@as(u8, 1), set.min());
}
