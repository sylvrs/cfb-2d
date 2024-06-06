const std = @import("std");
const GameState = @import("../GameState.zig");
const Scene = @import("../Scene.zig");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const ui = @import("../ui/ui.zig");

const Self = @This();

/// The allocator to use for this scene.
allocator: std.mem.Allocator,
/// The current game state.
game_state: *GameState,
/// The menu for the scene.
menu: ui.Menu,

/// Creates a new MainMenu scene.
pub fn init(allocator: std.mem.Allocator, game_state: *GameState) Self {
    return Self{
        .allocator = allocator,
        .game_state = game_state,
        .menu = ui.Menu.init(allocator),
    };
}

/// Deinitializes the MainMenu scene.
pub fn deinit(self: *Self) void {
    self.menu.deinit();
}

/// Sets up the buttons for the MainMenu scene.
pub fn setup(self: *Self) !void {
    try self.menu.addElement(ui.Button{
        .text = "Exhibition",
        .bg_color = rl.Color.maroon,
        .text_color = rl.Color.white,
        .x = @divFloor(rl.getScreenWidth(), 2),
        .y = @divFloor(rl.getScreenHeight(), 2),
        .width = 200,
        .height = 50,
        .onClickFn = onPlayClick,
        .context = @ptrCast(self),
    });
    try self.menu.addElement(ui.Button{
        .text = "Options",
        .bg_color = rl.Color.blue,
        .text_color = rl.Color.white,
        .x = @divFloor(rl.getScreenWidth(), 2),
        .y = @divFloor(rl.getScreenHeight(), 2) + 75,
        .width = 200,
        .height = 50,
        .onClickFn = struct {
            pub fn onClick(erased_scene: *anyopaque) anyerror!void {
                const menu_scene = utils.alignAndCast(Self, erased_scene);
                try menu_scene.game_state.setScene(.options);
            }
        }.onClick,
        .context = @ptrCast(self),
    });
}

/// Updates the MainMenu scene.
pub fn update(self: *Self) anyerror!void {
    try self.menu.update();
}

/// Draws the MainMenu scene.
pub fn draw(self: *Self) anyerror!void {
    rl.clearBackground(rl.Color.ray_white);

    utils.drawCenteredText("College Football", @divFloor(rl.getScreenWidth(), 2), @divFloor(rl.getScreenHeight(), 4), 60, rl.Color.maroon);
    try self.menu.draw();
}

/// Called when the play button is clicked.
pub fn onPlayClick(erased_self: *anyopaque) anyerror!void {
    const self = utils.alignAndCast(Self, erased_self);
    try self.game_state.setScene(.game);
}

/// Returns a scene object for the MainMenu scene.
pub fn scene(self: *Self) Scene {
    return Scene.init(self);
}
