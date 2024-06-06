const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");

const Scene = @import("../Scene.zig");
const Team = @import("../Team.zig");

const Self = @This();

/// The allocator to use for this scene.
allocator: std.mem.Allocator,
/// The currently selected away team.
away_team: Team,
/// The currently selected home team.
home_team: Team,
/// The team that the user is currently on.
user_team: ?Team.GameSite = null,

/// Creates a new Exhibition scene.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        // Select random teams for the home and away teams
        .home_team = Team.random(),
        .away_team = Team.random(),
    };
}

/// Sets up the Exhibition scene.
pub fn setup(self: *Self) !void {
    _ = self;
}

/// Deinitializes the Exhibition scene.
pub fn deinit(self: *Self) void {
    _ = self;
}

/// Updates the Exhibition scene.
pub fn update(self: *Self) anyerror!void {
    _ = self;
}

/// Draws the MainMenu scene.
pub fn draw(self: *Self) anyerror!void {
    rl.clearBackground(rl.Color.ray_white);

    utils.drawCenteredText("Exhibition", @divFloor(rl.getScreenWidth(), 2), @divFloor(rl.getScreenHeight(), 4), 60, rl.Color.maroon);
    _ = self;
}

/// Creates the Scene interface for the Exhibition scene.
pub fn scene(self: *Self) Scene {
    return Scene.init(self);
}
