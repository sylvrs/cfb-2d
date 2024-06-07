const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Scene = @import("Scene.zig");
const Team = @import("Team.zig");

/// The scenes that the game can switch between.
const MainMenuScene = @import("scenes/MainMenuScene.zig");
const ExhibitionScene = @import("scenes/ExhibitionScene.zig");
const GameScene = @import("scenes/GameScene.zig");
const OptionsScene = @import("scenes/OptionsScene.zig");

const Self = @This();

/// The scale factor to use for the game.
pub const Scale = 2;
/// The starting width of the window (predefined as the size of the field by the scale factor)
pub const FieldWidth = 730 * Scale;
/// The starting height of the window. (predefined as the size of the field by the scale factor)
pub const FieldHeight = 330 * Scale;
/// The title of the window.
pub const Title = "College Ball";
/// The period, in seconds, between each update of the window title.
const TitleUpdatePeriod = 0.01;

/// The different scenes that the game can be in.
const SceneState = enum {
    main_menu,
    exhibition,
    game,
    options,
};

const SceneRefMetadata = struct {
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
/// A pointer to the last scene struct.
last_ref_metadata: ?SceneRefMetadata = null,
/// A pointer to the current scene struct.
current_ref_metadata: ?SceneRefMetadata = null,
/// The last scene that the game was in.
last_scene: ?Scene = null,
/// The current scene that the game is in.
current_scene: ?Scene = null,

/// Initializes the game state.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{ .allocator = allocator };
}

/// Deinitializes the game state.
pub fn deinit(self: *Self) void {
    self.current_scene.?.deinit();
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
    try self.current_scene.?.update();

    // Destroy the last scene if it exists.
    self.destroyLastScene();
}

pub fn draw(self: *Self) anyerror!void {
    try self.current_scene.?.draw();
}

/// Set the scene given the scene state.
pub fn setScene(self: *Self, scene: SceneState) !void {
    switch (scene) {
        .main_menu => try self.setupScene(MainMenuScene.init(self.allocator, self)),
        .exhibition => try self.setupScene(ExhibitionScene.init(self.allocator)),
        .game => try self.setupScene(GameScene.init(
            self.allocator,
            Team.random(),
            Team.random(),
            // try Team.find("West Virginia State"),
            // try Team.find("West Virginia"),
        )),
        .options => try self.setupScene(OptionsScene.init(self.allocator, self)),
    }
}

/// Setups the scene with the given setup function
pub fn setupScene(self: *Self, scene: anytype) !void {
    self.last_scene = self.current_scene;
    const T = @TypeOf(scene);
    var created_scene = try self.allocator.create(T);
    created_scene.* = scene;
    self.current_scene = created_scene.scene();
    try self.current_scene.?.setup();
    errdefer self.allocator.destroy(created_scene);

    // Set the last wrapper metadata to the current one.
    self.last_ref_metadata = self.current_ref_metadata;
    // Set the current wrapper metadata to the new one.
    self.current_ref_metadata = SceneRefMetadata{
        .size = @sizeOf(T),
        .alignment = @alignOf(T),
        .scene_ptr = created_scene,
    };
}

pub fn destroyLastScene(self: *Self) void {
    if (self.last_ref_metadata == null or self.last_scene == null) {
        return;
    }
    self.last_scene.?.deinit();

    const unwrapped = self.last_ref_metadata.?;
    const wrapper_many_ptr: [*]u8 = @alignCast(@ptrCast(unwrapped.scene_ptr));
    self.allocator.rawFree(wrapper_many_ptr[0..unwrapped.size], unwrapped.alignment, @returnAddress());

    self.last_ref_metadata = null;
    self.last_scene = null;
}
