const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Scene = @import("Scene.zig");

/// The scenes that the game can switch between.
const MainMenuScene = @import("scenes/MainMenuScene.zig");
const GameScene = @import("scenes/GameScene.zig");
const OptionsScene = @import("scenes/OptionsScene.zig");

const Self = @This();

/// The scale factor to use for the game.
pub const Scale = 2;
/// The starting width of the window (predefined as the size of the field by the scale factor)
pub const ScreenWidth = 720 * Scale;
/// The starting height of the window. (predefined as the size of the field by the scale factor)
pub const ScreenHeight = 320 * Scale;
/// The title of the window.
pub const Title = "College Ball";
/// The period, in seconds, between each update of the window title.
const TitleUpdatePeriod = 3.0 / 4.0;

/// The different scenes that the game can be in.
const SceneState = enum {
    main_menu,
    game,
    options,
};

const SceneWrapperMetadata = struct {
    /// The size of the scene wrapper struct.
    size: usize,
    /// The alignment of the scene wrapper struct.
    alignment: u8,
    /// A pointer to the current scene struct.
    scene_ptr: *anyopaque,
};

/// The allocator that the game uses.
allocator: std.mem.Allocator,
/// The task that updates the window title.
title_task: utils.Task(Self) = undefined,
/// A pointer to the current scene struct.
scene_wrapper_metadata: ?SceneWrapperMetadata = null,
/// The current scene that the game is in.
current_scene: Scene = undefined,

/// Initializes the game state.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{ .allocator = allocator };
}

/// Deinitializes the game state.
pub fn deinit(self: *Self) void {
    self.current_scene.deinit();
}

/// Sets up the game state.
pub fn setup(self: *Self) !void {
    self.title_task = utils.Task(Self).init(TitleUpdatePeriod, updateTitle, self);
    try self.setScene(.main_menu);
}

/// Updates the window title with the current scene's title and the current FPS.
fn updateTitle(_: *Self) !void {
    try utils.setFmtWindowTitle(32, "{s} [FPS: {d}]", .{ Title, rl.getFPS() });
}

/// Updates the game state as needed.
pub fn update(self: *Self) anyerror!void {
    try self.title_task.tick();
    try self.current_scene.update();
}

pub fn draw(self: *Self) anyerror!void {
    try self.current_scene.draw();
}

pub fn setScene(self: *Self, scene: SceneState) !void {
    // self.destroyCurrentSceneWrapper();
    switch (scene) {
        .main_menu => try self.setupScene(MainMenuScene.init(self.allocator, self)),
        .game => try self.setupScene(GameScene.init(Scale, rl.Vector2{
            .x = @divExact(ScreenWidth, Scale),
            .y = @divExact(ScreenHeight, Scale),
        }, [_]GameScene.Team{
            .{ .name = "Team 1", .color = rl.Color.red },
            .{ .name = "Team 2", .color = rl.Color.blue },
        })),
        .options => try self.setupScene(OptionsScene.init(self.allocator, self)),
    }
}

/// Setups the scene with the given setup function
fn setupScene(self: *Self, scene: anytype) !void {
    const T = @TypeOf(scene);
    var created_scene = try self.allocator.create(T);
    created_scene.* = scene;
    self.current_scene = created_scene.scene();
    try self.current_scene.setup();
    self.scene_wrapper_metadata = SceneWrapperMetadata{
        .size = @sizeOf(T),
        .alignment = @alignOf(T),
        .scene_ptr = created_scene,
    };
}

pub fn destroyCurrentSceneWrapper(self: *Self) void {
    if (self.scene_wrapper_metadata == null) {
        return;
    }
    const unwrapped = self.scene_wrapper_metadata.?;
    const wrapper_many_ptr: [*]u8 = @ptrCast(@constCast(unwrapped.scene_ptr));
    self.allocator.rawFree(wrapper_many_ptr[0..unwrapped.size], unwrapped.alignment, @returnAddress());
}
