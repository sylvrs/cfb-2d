const std = @import("std");

const Self = @This();

/// The context for the scene.
context: *anyopaque,
/// A function that updates the scene.
updateFn: *const fn (context: *anyopaque) anyerror!void,
/// A function that draws the scene.
drawFn: *const fn (context: *anyopaque) anyerror!void,
/// A function that initializes the scene (if needed)
setupFn: ?*const fn (context: *anyopaque) anyerror!void = null,
/// A function that deinitializes the scene (if needed)
deinitFn: ?*const fn (context: *anyopaque) void = null,

/// Updates the scene as directed by `updateFn`.
pub fn update(self: *Self) !void {
    try (self.updateFn)(self.context);
}

/// Draws the scene as directed by `drawFn`.
pub fn draw(self: *Self) !void {
    try (self.drawFn)(self.context);
}

/// Initializes the scene as directed by `setupFn`.
pub fn setup(self: *Self) !void {
    if (self.setupFn) |setupFn| {
        try (setupFn)(self.context);
    }
}

/// Deinitializes the scene as directed by `deinitFn`.
pub fn deinit(self: *Self) void {
    if (self.deinitFn) |deinitFn| {
        (deinitFn)(self.context);
    }
}
