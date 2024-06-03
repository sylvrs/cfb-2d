const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const Field = @import("../Field.zig");
const Player = @import("../Player.zig");
const Scene = @import("../Scene.zig");
const GameState = @import("../GameState.zig");
const Team = @import("../Team.zig");

const Self = @This();

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
/// The task that is responsible for ticking the game.
tick_task: ?utils.Task(Self) = null,

/// Initializes a new instance of the game scene.
pub fn init(scale: f32, player_pos: rl.Vector2, teams: [2]Team) Self {
    return Self{
        .teams = teams,
        .player = Player.init(player_pos, scale),
        .field = Field.init(scale, teams[0]),
        .tick_task = null,
    };
}

/// Starts the tick task for the game scene.
pub fn setup(self: *Self) !void {
    self.tick_task = utils.Task(Self).init(1, tick, self);
}

/// Deinitializes the game scene.
pub fn deinit(self: *Self) void {
    self.field.deinit();
    self.player.deinit();
}

/// Updates the game scene.
pub fn update(self: *Self) !void {
    self.field.update();
    self.player.update();

    try self.tick_task.?.tick();
}

/// Ticks the game scene.
pub fn tick(self: *Self) !void {
    self.time_remaining -= 1;
    if (self.time_remaining == 0) {
        self.time_remaining = 60 * 15;
        self.quarter += 1;
    }
}

/// Draws the game scene.
pub fn draw(self: *Self) !void {
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
    utils.drawCenteredRectangle(@divFloor(rl.getScreenWidth(), 2), rl.getScreenHeight() - 100, 300, 50, rl.Color.black);

    try utils.drawCenteredFmtText(@divFloor(rl.getScreenWidth(), 2), rl.getScreenHeight() - 100, 32, rl.Color.white, 64, "Q{d} | {d:0>2}:{d:0>2} | {d}", .{
        self.quarter,
        @divFloor(self.time_remaining, 60),
        self.time_remaining % 60,
        self.playclock,
    });
}

/// Returns an instance of the scene
pub fn scene(self: *Self) Scene {
    return Scene.init(self);
}
