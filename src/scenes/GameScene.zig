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

const EndzoneBounds = struct {
    const Away = rl.Rectangle{ .x = 5 * GameState.Scale, .y = 5 * GameState.Scale, .width = 60 * GameState.Scale, .height = 320 * GameState.Scale };
    const Home = rl.Rectangle{ .x = 665 * GameState.Scale, .y = 5 * GameState.Scale, .width = 60 * GameState.Scale, .height = 320 * GameState.Scale };
};

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
/// The player that is currently carrying the ball (if any).
ballcarrier_data: ?Player.IndexData = null,

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
    const player = self.getUserPlayer().?;
    const team_state = if (std.mem.eql(u8, player.team.name, self.teams[0].name)) &self.team_states[0] else &self.team_states[1];
    const new_bounds = if (team_state.site == .home) EndzoneBounds.Away else EndzoneBounds.Home;
    player.position = rl.Vector2.init(new_bounds.x + @divFloor(new_bounds.width, 2), new_bounds.y + @divFloor(new_bounds.height, 2));

    try self.setBallcarrier(0, 0);
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
        const new_player_index = (player_data.player_index + 1) % 11;
        try self.user.setSelectedPlayer(self, player_data.team_index, new_player_index);
        try self.setBallcarrier(player_data.team_index, new_player_index);
    }

    if (self.ballcarrier_data) |data| {
        const team_state = try self.getTeamState(data.team_index);
        const player = try team_state.getNonNullPlayer(data.player_index);

        const rect = rl.Rectangle.init(
            player.position.x,
            player.position.y,
            @as(f32, @floatFromInt(player.hitbox.width)),
            @as(f32, @floatFromInt(player.hitbox.height)),
        );

        // check if the player is in the endzone for their team
        const endzone_bounds: rl.Rectangle = switch (team_state.site) {
            .home => EndzoneBounds.Home,
            .away => EndzoneBounds.Away,
        };

        if (rect.checkCollision(endzone_bounds)) {
            // touchdown
            team_state.score += 6;

            // teleport to other side of field
            const new_bounds = if (team_state.site == .home) EndzoneBounds.Away else EndzoneBounds.Home;
            player.position = rl.Vector2.init(new_bounds.x + @divFloor(new_bounds.width, 2), new_bounds.y + @divFloor(new_bounds.height, 2));
        }

        const other_team_state = try self.getTeamState((data.player_index + 1) % 2);
        for (0..Team.MaxPlayers) |index| {
            var current_player = &(other_team_state.players[index] orelse continue);

            // run towards player
            const distance = current_player.position.distance(player.position);

            const breakpoint = @as(f32, @floatFromInt(player.hitbox.width)) * GameState.Scale;
            if (distance <= breakpoint) {
                // teleport to other side of field
                const new_bounds = if (team_state.site == .home) EndzoneBounds.Away else EndzoneBounds.Home;
                player.position = rl.Vector2.init(new_bounds.x + @divFloor(new_bounds.width, 2), new_bounds.y + @divFloor(new_bounds.height, 2));
            } else if (distance < breakpoint * 5.0) {
                const direction = player.position.subtract(current_player.position).normalize();
                // set velocity
                current_player.velocity = direction.scale(current_player.speed);
            }
        }
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

pub fn getUserPlayer(self: *Self) ?*Player {
    const player_data = self.user.player_data orelse return null;
    const team_state = self.getTeamState(player_data.team_index) catch return null;
    return team_state.getNonNullPlayer(player_data.player_index) catch null;
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

/// Gets the home team state based on the team site
pub inline fn getHomeTeamState(self: *Self) *Team.State {
    return &(if (self.team_states[0].site == .home) self.team_states[0] else self.team_states[1]);
}

/// Gets the away team based on the team site
pub inline fn getAwayTeam(self: *Self) Team {
    return if (self.team_states[1].site == .away) self.teams[1] else self.teams[0];
}

/// Gets the away team state based on the team site
pub inline fn getAwayTeamState(self: *Self) *Team.State {
    return &(if (self.team_states[1].site == .away) self.team_states[1] else self.team_states[0]);
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

/// Sets the ballcarrier based on the team and player index.
pub fn setBallcarrier(self: *Self, team_index: u8, player_index: u8) !void {
    if (team_index < 0 or team_index >= self.team_states.len) return error.InvalidTeamIndex;
    if (player_index < 0 or player_index >= Team.MaxPlayers) return error.InvalidPlayerIndex;
    if (self.team_states[team_index].players[player_index] == null) return error.UnknownPlayer;

    self.ballcarrier_data = .{ .team_index = team_index, .player_index = player_index };
}

/// Clears the ballcarrier data from the game scene.
pub fn clearBallcarrier(self: *Self) void {
    self.ballcarrier_data = null;
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
