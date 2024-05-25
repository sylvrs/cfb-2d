const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const Field = @import("../Field.zig");
const Player = @import("../Player.zig");
const Scene = @import("../Scene.zig");
const GameState = @import("../GameState.zig");

const Self = @This();

/// A team that is playing the game.
pub const Team = struct {
    name: [:0]const u8,
    color: rl.Color,
    score: u32 = 0,
};

/// The teams that are playing the game.
teams: [2]Team,
/// The current quarter of the game.
quarter: u8 = 1,
/// The time remaining in the current quarter.
time_remaining: u32 = 60 * 15,
/// The time remaining in the current playclock.
playclock: u32 = 40,
/// The player that is currently playing.
player: Player,
/// The field that the player is playing on.
field: Field,

/// Initializes a new instance of the game scene.
pub fn init(scale: f32, player_pos: rl.Vector2, teams: [2]Team) Self {
    return Self{
        .teams = teams,
        .player = Player.init(player_pos, scale),
        .field = Field.init(scale),
    };
}

/// Deinitializes the game scene.
pub fn deinit(erased_self: *anyopaque) void {
    const self = utils.alignAndCast(Self, erased_self);
    self.field.deinit();
    self.player.deinit();
}

/// Updates the game scene.
pub fn update(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    self.field.update();
    self.player.update();
}

/// Draws the game scene.
pub fn draw(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);

    self.drawWorld();
    try self.drawHud();
}

/// Draws the non-HUD elements of the game scene.
pub fn drawWorld(self: *Self) void {
    self.player.startCamera();
    defer self.player.endCamera();

    self.field.draw();
    self.player.draw();
}

/// Draws the HUD elements of the game scene.
pub fn drawHud(self: *Self) !void {
    _ = self;
}

/// Returns an instance of the scene
pub fn scene(self: *Self) Scene {
    return .{ .context = @ptrCast(self), .updateFn = update, .drawFn = draw, .deinitFn = deinit };
}
