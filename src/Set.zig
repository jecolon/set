const std = @import("std");

pub fn Set(comptime T: type) type {
    return struct {
        map: std.AutoArrayHashMap(T, void),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .map = std.AutoArrayHashMap(T, void).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn contains(self: Self, item: T) bool {
            return self.map.contains(item);
        }

        pub fn count(self: Self) usize {
            return self.map.count();
        }

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

        pub fn eql(self: Self, other: Self) bool {
            return self.in(other) and self.count() == other.count();
        }

        pub fn get(self: *Self, item: T) ?T {
            return self.map.get(item);
        }

        pub fn in(self: Self, other: Self) bool {
            return for (self.items()) |item| {
                if (!other.contains(item)) break false;
            } else true;
        }

        pub fn inner(self: *Self) *std.AutoArrayHashMap(T, void) {
            return &self.map;
        }

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

        pub fn isSubset(self: Self, other: Self) bool {
            return self.in(other) and self.count() < other.count();
        }

        pub fn isSuperset(self: Self, other: Self) bool {
            return other.in(self) and other.count() < self.count();
        }

        pub fn items(self: Self) []T {
            return self.map.keys();
        }

        pub fn max(self: Self) T {
            return std.mem.max(T, self.items());
        }

        pub fn min(self: Self) T {
            return std.mem.min(T, self.items());
        }

        pub fn put(self: *Self, item: T) !void {
            try self.map.put(item, {});
        }

        pub fn putSlice(self: *Self, slice: []const T) !void {
            for (slice) |item| try self.put(item);
        }

        pub fn remove(self: *Self, item: T) bool {
            return self.map.swapRemove(item);
        }

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
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 3, 4, 5, 6 });

    var intersection = try set_a.intersect(std.testing.allocator, set_b);
    defer intersection.deinit();

    try std.testing.expectEqual(@as(usize, 2), intersection.count());
    try std.testing.expect(intersection.contains(3));
    try std.testing.expect(intersection.contains(4));
    try std.testing.expect(!intersection.contains(6));
}

test "union" {
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 3, 4, 5, 6 });

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
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 3, 4, 5, 6 });

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
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 3, 4, 5, 6 });

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
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();
    var set_c = Set(u8).init(std.testing.allocator);
    defer set_c.deinit();
    var set_d = Set(u8).init(std.testing.allocator);
    defer set_d.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 3, 4, 5, 6 });
    try set_c.putSlice(&[_]u8{ 1, 2 });
    try set_d.putSlice(&[_]u8{ 5, 6 });

    try std.testing.expect(set_c.in(set_a));
    try std.testing.expect(set_d.in(set_b));
    try std.testing.expect(!set_d.in(set_a));
}

test "comparison" {
    var set_a = Set(u8).init(std.testing.allocator);
    defer set_a.deinit();
    var set_b = Set(u8).init(std.testing.allocator);
    defer set_b.deinit();
    var set_c = Set(u8).init(std.testing.allocator);
    defer set_c.deinit();
    var set_d = Set(u8).init(std.testing.allocator);
    defer set_d.deinit();

    try set_a.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_b.putSlice(&[_]u8{ 1, 2, 3, 4 });
    try set_c.putSlice(&[_]u8{ 1, 2 });

    try std.testing.expect(set_c.isSubset(set_a));
    try std.testing.expect(set_a.isSuperset(set_c));
    try std.testing.expect(set_a.eql(set_b));
    try std.testing.expect(!set_a.eql(set_c));
}

test "max min" {
    var set = Set(u8).init(std.testing.allocator);
    defer set.deinit();

    try set.putSlice(&[_]u8{ 1, 2, 3, 4 });

    try std.testing.expectEqual(@as(u8, 4), set.max());
    try std.testing.expectEqual(@as(u8, 1), set.min());
}
