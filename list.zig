const std = @import("std");
const ItemType = ?*anyopaque;
const fn_delete = *const fn (ItemType) callconv(.C) void;
const ContainerType = std.ArrayList(ItemType);

pub var allocator: std.mem.Allocator = undefined;

pub export fn List_create(capacity: usize) callconv(.C) *ContainerType {
    const b = allocator.create(ContainerType) catch {
        unreachable;
    };

    b.* = ContainerType.initCapacity(allocator, capacity) catch {
        unreachable;
    };

    return b;
}

pub export fn List_delete(b: *ContainerType, deleter: ?fn_delete) callconv(.C) void {
    if (deleter) |del| {
        for (b.items) |i| {
            if (i != null) {
                del(i);
            }
        }
    }
    b.deinit();
    allocator.destroy(b);
}

pub export fn List_append(b: *ContainerType, data: ItemType) callconv(.C) void {
    b.append(data) catch {
        unreachable;
    };
}

pub export fn List_length(b: *const ContainerType) callconv(.C) usize {
    return b.items.len;
}

pub export fn List_get(b: *const ContainerType, i: usize) callconv(.C) ItemType {
    return b.items[i];
}

pub export fn List_set(b: *ContainerType, i: usize, data: ItemType) callconv(.C) void {
    b.items[i] = data;
}
