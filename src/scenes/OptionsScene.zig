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

/// Creates a new OptionsScene scene.
pub fn init(allocator: std.mem.Allocator, game_state: *GameState) Self {
    return Self{
        .allocator = allocator,
        .game_state = game_state,
        .menu = ui.Menu.init(allocator),
    };
}

/// Deinitializes the OptionsScene scene.
pub fn deinit(erased_self: *anyopaque) void {
    const self = utils.alignAndCast(Self, erased_self);
    self.menu.deinit();
}

/// Sets up the buttons for the OptionsScene scene.
pub fn setup(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    try self.menu.addElement(ui.Button{
        .text = "Back",
        .bg_color = rl.Color.blue,
        .text_color = rl.Color.white,
        .x = @divFloor(rl.getScreenWidth(), 2),
        .y = @divFloor(rl.getScreenHeight(), 2),
        .width = 200,
        .height = 50,
        .onClickFn = struct {
            pub fn onClick(erased_scene: *anyopaque) anyerror!void {
                const menu_scene = utils.alignAndCast(Self, erased_scene);
                try menu_scene.game_state.setScene(.main_menu);
            }
        }.onClick,
        .context = self,
    });
}

/// Adds a button to the MainMenu scene.
pub fn addButton(self: *Self, button: ui.Button) std.mem.Allocator.Error!void {
    try self.buttons.append(self.allocator, button);
}

/// Updates the MainMenu scene.
pub fn update(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    try self.menu.update();
}

/// Draws the MainMenu scene.
pub fn draw(erased_self: *anyopaque) anyerror!void {
    const self = utils.alignAndCast(Self, erased_self);
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
    return .{
        .context = @ptrCast(self),
        .updateFn = update,
        .drawFn = draw,
        .setupFn = setup,
        .deinitFn = deinit,
    };
}
