const std = @import("std");
const rl = @import("raylib");

const Team = @import("../Team.zig");

const Self = @This();

/// The allocator to use for this scene.
allocator: std.mem.Allocator,
/// The currently selected away team.
away_team: Team,
/// The currently selected home team.
home_team: Team,

/// Creates a new Exhibition scene.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        // Select random teams for the home and away teams
        .home_team = Team.random(),
        .away_team = Team.random(),
    };
}

/// Deinitializes the Exhibition scene.
pub fn deinit(self: *Self) void {
    _ = self;
}

/// Updates the Exhibition scene.
pub fn update(self: *Self) anyerror!void {
    _ = self;
}

/// Draws the Exhibition scene.
pub fn draw(self: *Self) anyerror!void {
    _ = self;
}
