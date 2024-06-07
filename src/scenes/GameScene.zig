const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const Field = @import("../Field.zig");
const Player = @import("../player/Player.zig");
const User = @import("../player/User.zig");
const Scene = @import("../Scene.zig");
const GameState = @import("../GameState.zig");
const Team = @import("../Team.zig");
const Scorebug = @import("../Scorebug.zig");

const Self = @This();

const QuarterLength = 60 * 5;

/// The allocator to use for this scene.
allocator: std.mem.Allocator,
/// The teams that are playing in the game.
teams: [2]Team,
/// The team states for the teams that are playing in the game.
team_states: [2]Team.State,
/// The current quarter of the game.
quarter: u8 = 1,
/// The time remaining in the current quarter.
time_remaining: u32 = QuarterLength,
/// The time remaining in the current playclock.
playclock: u8 = 40,
/// The current down of the drive.
current_down: u8 = 1,
/// How many yards the team has to go to get a first down.
yards_to_go: u8 = 10,
/// The user that is currently playing.
user: User,
/// The field that the player is playing on.
field: Field,
/// The scorebug for the game.
scorebug: Scorebug,
/// The task that is responsible for ticking the game.
tick_task: ?utils.Task(Self) = null,

/// Initializes a new instance of the game scene.
pub fn init(allocator: std.mem.Allocator, home_team: Team, away_team: Team) Self {
    return Self{
        .allocator = allocator,
        .teams = [_]Team{ home_team, away_team },
        .team_states = [_]Team.State{ .{ .site = .home }, .{ .site = .away } },
        // initialize the User as undefined until we set up a valid player
        .user = User.init(GameState.Scale),
        .field = Field.init(GameState.Scale, home_team),
        .scorebug = Scorebug.init(home_team, away_team),
        .tick_task = null,
    };
}

/// Starts the tick task for the game scene.
pub fn setup(self: *Self) !void {
    for (&self.team_states, self.teams) |*team_state, team| {
        inline for (0..Team.MaxPlayers) |i| {
            team_state.setPlayer(i, Player.init(
                randomPosition(),
                team,
                team_state.*,
                Player.SkinColor.random(),
            ));
        }
    }

    try self.user.setSelectedPlayer(self, 0, 0);
    self.tick_task = utils.Task(Self).init(1, tick, self);
}

/// Deinitializes the game scene.
pub fn deinit(self: *Self) void {
    self.field.deinit();
    self.scorebug.deinit();
}

/// Updates the game scene.
pub fn update(self: *Self) !void {
    self.field.update();
    self.scorebug.update();
    try self.user.update(self);

    inline for (&self.team_states) |*team_state| {
        team_state.*.update();
    }

    if (rl.isKeyPressed(.key_one)) {
        self.setTeam(0, Team.random());
    } else if (rl.isKeyPressed(.key_two)) {
        self.setTeam(1, Team.random());
    }

    // switch home and away teams
    if (rl.isKeyPressed(.key_y)) {
        for (&self.team_states) |*team_state| {
            team_state.site = if (team_state.site == .home) .away else .home;
        }
        self.updateTeams();
    }

    if (rl.isKeyPressed(.key_g)) {
        const player_data = self.user.player_data.?;
        try self.user.setSelectedPlayer(self, player_data.team_index, (player_data.player_index + 1) % 11);
    }

    try self.tick_task.?.tick();
}

/// Ticks the game scene.
pub fn tick(self: *Self) !void {
    self.time_remaining -= 1;
    if (self.time_remaining == 0) {
        self.time_remaining = QuarterLength;
        self.quarter += 1;
    }

    // self.playclock -= 1;
    // if (self.playclock == 0) { }
}

/// Draws the game scene.
pub fn draw(self: *Self) !void {
    self.drawWorld();
    try self.scorebug.draw(self);
}

/// Draws the non-HUD elements of the game scene.
pub fn drawWorld(self: *Self) void {
    self.user.startCamera();
    defer self.user.endCamera();

    self.field.draw();

    inline for (&self.team_states) |*team_state| {
        team_state.*.draw();
    }
}

pub fn updateTeams(self: *Self) void {
    for (&self.team_states, self.teams) |*team_state, team| {
        if (team_state.site == .home) {
            self.field.setTeam(team);
            self.scorebug.setHomeTeam(team);
        } else {
            self.scorebug.setAwayTeam(team);
        }

        for (&team_state.players) |*player| {
            if (player.* == null) continue;
            player.*.?.setTeam(team, team_state.*);
        }
    }
}

/// Gets the team at the given index.
pub inline fn getTeam(self: *Self, team_index: usize) Team {
    return self.teams[team_index];
}

/// Gets the home team based on the team site
pub inline fn getHomeTeam(self: *Self) Team {
    return if (self.team_states[0].site == .home) self.teams[0] else self.teams[1];
}

/// Gets the away team based on the team site
pub inline fn getAwayTeam(self: *Self) Team {
    return if (self.team_states[1].site == .away) self.teams[1] else self.teams[0];
}

/// Sets the team at the given index.
pub inline fn setTeam(self: *Self, team_index: usize, team: Team) void {
    self.teams[team_index] = team;
    self.updateTeams();
}

/// Returns the team state for the given team index
pub fn getTeamState(self: *Self, team_index: usize) !*Team.State {
    if (team_index < 0 or team_index >= self.team_states.len) return error.OutOfBounds;
    return &(self.team_states[team_index]);
}

/// Returns an instance of the scene
pub fn scene(self: *Self) Scene {
    return Scene.init(self);
}

/// Returns a random position on the field
inline fn randomPosition() rl.Vector2 {
    return .{
        .x = @floatFromInt(rl.getRandomValue(GameState.FieldWidth / 8, GameState.FieldWidth - GameState.FieldWidth / 8)),
        .y = @floatFromInt(rl.getRandomValue(GameState.FieldHeight / 8, GameState.FieldHeight - GameState.FieldHeight / 8)),
    };
}
