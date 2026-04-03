const std = @import("std");
const app = @import("app.zig");

const ItemType = ?*anyopaque;
const fn_delete = *const fn (ItemType) void;
pub const ContainerType = std.ArrayList(ItemType);

pub fn create(capacity: usize) *ContainerType {
    const b = app.allocator.create(ContainerType) catch {
        unreachable;
    };

    b.* = ContainerType.initCapacity(app.allocator, capacity) catch {
        unreachable;
    };

    return b;
}

pub fn delete(b: *ContainerType, deleter: ?fn_delete) void {
    if (deleter) |del| {
        for (b.items) |i| {
            if (i != null) {
                del(i);
            }
        }
    }
    b.deinit(app.allocator);
    app.allocator.destroy(b);
}

pub fn append(b: *ContainerType, data: ItemType) void {
    b.append(app.allocator, data) catch {
        unreachable;
    };
}

pub fn length(b: *const ContainerType) usize {
    return b.items.len;
}

pub fn get(b: *const ContainerType, i: usize) ItemType {
    return b.items[i];
}

pub fn set(b: *ContainerType, i: usize, data: ItemType) void {
    b.items[i] = data;
}

