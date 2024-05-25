const std = @import("std");
const ui = @import("ui.zig");
const utils = @import("../utils.zig");

const Self = @This();

pub const VTable = struct {
    /// The function that will be called to get the bounds of the element
    getBounds: *const fn (ctx: *anyopaque) ui.BoundingBox,
    /// The function that will be called when the element is hovered
    onHover: *const fn (ctx: *anyopaque, current_input: ui.Menu.InputType) anyerror!void,
    /// The function that will be called when the element is no longer hovered
    onUnhover: *const fn (ctx: *anyopaque) anyerror!void,
    /// The function that will be called when the element is pressed (but not released)
    onPress: *const fn (ctx: *anyopaque) anyerror!void,
    /// The function that will be called when the element is selected
    onSelect: *const fn (ctx: *anyopaque) anyerror!void,
    /// The function that will be called to draw the element
    draw: *const fn (ctx: *anyopaque) anyerror!void,
    /// The function that will be called to update the element
    update: *const fn (ctx: *anyopaque) anyerror!void,
};

/// Creates a new vtable for the element with the given wrapper
pub inline fn createVTable(comptime T: type) VTable {
    const generated = struct {
        pub fn getBounds(ctx: *anyopaque) ui.BoundingBox {
            const self = utils.alignAndCast(T, ctx);
            return self.getBounds();
        }

        pub fn onHover(ctx: *anyopaque, current_input: ui.Menu.InputType) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.onHover(current_input);
        }

        pub fn onUnhover(ctx: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.onUnhover();
        }

        pub fn onPress(ctx: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.onPress();
        }

        pub fn onSelect(ctx: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.onSelect();
        }

        pub fn draw(ctx: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.draw();
        }

        pub fn update(ctx: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(T, ctx);
            return self.update();
        }
    };

    return VTable{
        .getBounds = generated.getBounds,
        .onHover = generated.onHover,
        .onUnhover = generated.onUnhover,
        .onPress = generated.onPress,
        .onSelect = generated.onSelect,
        .draw = generated.draw,
        .update = generated.update,
    };
}

/// The context of the element
context: *anyopaque,
/// The vtable of the element
vtable: *const VTable,

/// Gets the bounds of the element
pub inline fn getBounds(self: *Self) ui.BoundingBox {
    return (self.vtable.getBounds)(self.context);
}

/// Called when the element is hovered
pub inline fn onHover(self: *Self, current_input: ui.Menu.InputType) !void {
    return (self.vtable.onHover)(self.context, current_input);
}

/// Called when the element is no longer hovered
pub inline fn onUnhover(self: *Self) !void {
    return (self.vtable.onUnhover)(self.context);
}

/// Called when the element is pressed (but not released)
pub inline fn onPress(self: *Self) !void {
    return (self.vtable.onPress)(self.context);
}

/// Called when the element is selected
pub inline fn onSelect(self: *Self) !void {
    return (self.vtable.onSelect)(self.context);
}

/// Draws the element on the screen
pub inline fn draw(self: *Self) !void {
    return (self.vtable.draw)(self.context);
}

/// Updates the element
pub inline fn update(self: *Self) !void {
    return (self.vtable.update)(self.context);
}
