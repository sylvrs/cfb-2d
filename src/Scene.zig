const std = @import("std");
const utils = @import("utils.zig");
const Self = @This();

/// The context for the scene.
context: *anyopaque,
/// A function that updates the scene.
updateFn: *const fn (context: *anyopaque) anyerror!void,
/// A function that draws the scene.
drawFn: *const fn (context: *anyopaque) anyerror!void,
/// A function that initializes the scene (if needed)
setupFn: *const fn (context: *anyopaque) anyerror!void,
/// A function that deinitializes the scene (if needed)
deinitFn: *const fn (context: *anyopaque) void,

/// Initializes a scene from a pointer to a type that implements the `Scene` interface.
pub fn init(scene_ptr: anytype) Self {
    const scene_ptr_info = @typeInfo(@TypeOf(scene_ptr));
    if (scene_ptr_info != .Pointer) {
        @compileError("The scene pointer must be a pointer type.");
    }
    const SceneType = scene_ptr_info.Pointer.child;

    const generated = struct {
        pub fn update(context: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(SceneType, context);
            try self.update();
        }

        pub fn draw(context: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(SceneType, context);
            try self.draw();
        }

        pub fn setup(context: *anyopaque) anyerror!void {
            const self = utils.alignAndCast(SceneType, context);
            try self.setup();
        }

        pub fn deinit(context: *anyopaque) void {
            const self = utils.alignAndCast(SceneType, context);
            self.deinit();
        }
    };

    return Self{
        .context = scene_ptr,
        .updateFn = generated.update,
        .drawFn = generated.draw,
        .setupFn = generated.setup,
        .deinitFn = generated.deinit,
    };
}

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
    try (self.setupFn)(self.context);
}

/// Deinitializes the scene as directed by `deinitFn`.
pub fn deinit(self: *Self) void {
    (self.deinitFn)(self.context);
}
