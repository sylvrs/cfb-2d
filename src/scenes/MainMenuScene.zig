const std = @import("std");
const GameState = @import("../GameState.zig");
const Scene = @import("../Scene.zig");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const ui = @import("../ui/ui.zig");

const Self = @This();

/// The allocator to use for this scene.
allocator: std.mem.Allocator,
/// The buttons to display on the main menu.
buttons: std.ArrayListUnmanaged(ui.Button),
/// The current game state.
game_state: *GameState,

/// Creates a new MainMenu scene.
pub fn init(allocator: std.mem.Allocator, game_state: *GameState) Self {
    return Self{
        .allocator = allocator,
        .buttons = .{},
        .game_state = game_state,
    };
}

/// Deinitializes the MainMenu scene.
pub fn deinit(erased_self: *anyopaque) void {
    const self = utils.alignAndCast(Self, erased_self);
    self.buttons.deinit(self.allocator);
}

/// Sets up the buttons for the MainMenu scene.
pub fn setup(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    try self.addButton(ui.Button{
        .text = "Play",
        .bg_color = rl.Color.maroon,
        .text_color = rl.Color.white,
        .x = @divFloor(rl.getScreenWidth(), 2) - 100,
        .y = @divFloor(rl.getScreenHeight(), 2),
        .width = 200,
        .height = 50,
        .onClickFn = onPlayClick,
        .context = self,
    });
}

/// Adds a button to the MainMenu scene.
pub fn addButton(self: *Self, button: ui.Button) std.mem.Allocator.Error!void {
    try self.buttons.append(self.allocator, button);
}

/// Updates the MainMenu scene.
pub fn update(erased_self: *anyopaque) anyerror!void {
    const self = utils.alignAndCast(Self, erased_self);
    for (self.buttons.items) |*btn| {
        try btn.update();
    }
}

/// Draws the MainMenu scene.
pub fn draw(erased_self: *anyopaque) anyerror!void {
    const self = utils.alignAndCast(Self, erased_self);
    rl.clearBackground(rl.Color.ray_white);

    utils.drawCenteredText("College Football", @divFloor(rl.getScreenWidth(), 2), @divFloor(rl.getScreenHeight(), 4), 60, rl.Color.maroon);
    for (self.buttons.items) |btn| {
        btn.draw();
    }
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
