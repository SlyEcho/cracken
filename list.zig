const std = @import("std");
const app = @import("app.zig");

const ItemType = ?*anyopaque;
const fn_delete = *const fn (ItemType) callconv(.C) void;
pub const ContainerType = std.ArrayList(ItemType);

pub fn create(capacity: usize) callconv(.C) *ContainerType {
    const b = app.allocator.create(ContainerType) catch {
        unreachable;
    };

    b.* = ContainerType.initCapacity(app.allocator, capacity) catch {
        unreachable;
    };

    return b;
}

pub fn delete(b: *ContainerType, deleter: ?fn_delete) callconv(.C) void {
    if (deleter) |del| {
        for (b.items) |i| {
            if (i != null) {
                del(i);
            }
        }
    }
    b.deinit();
    app.allocator.destroy(b);
}

pub fn append(b: *ContainerType, data: ItemType) callconv(.C) void {
    b.append(data) catch {
        unreachable;
    };
}

pub fn length(b: *const ContainerType) callconv(.C) usize {
    return b.items.len;
}

pub fn get(b: *const ContainerType, i: usize) callconv(.C) ItemType {
    return b.items[i];
}

pub fn set(b: *ContainerType, i: usize, data: ItemType) callconv(.C) void {
    b.items[i] = data;
}

comptime {
    @export(create, .{ .name = "List_create", .linkage = .strong });
    @export(delete, .{ .name = "List_delete", .linkage = .strong });
    @export(append, .{ .name = "List_append", .linkage = .strong });
    @export(length, .{ .name = "List_length", .linkage = .strong });
    @export(get, .{ .name = "List_get", .linkage = .strong });
    @export(set, .{ .name = "List_set", .linkage = .strong });
}
