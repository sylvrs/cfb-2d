const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const utils = @import("../utils.zig");
const Field = @import("../Field.zig");
const Player = @import("../player/Player.zig");
const Scene = @import("../Scene.zig");
const GameState = @import("../GameState.zig");
const Team = @import("../Team.zig");
const Scorebug = @import("../Scorebug.zig");

const Self = @This();

const QuarterLength = 60 * 1;

/// The team that is hosting the game.
home_team: Team,
/// The team that is visiting the game.
away_team: Team,
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
/// The player that is currently playing.
player: Player,
/// The field that the player is playing on.
field: Field,
/// The scorebug for the game.
scorebug: Scorebug,
/// The task that is responsible for ticking the game.
tick_task: ?utils.Task(Self) = null,

/// Initializes a new instance of the game scene.
pub fn init(scale: f32, player_pos: rl.Vector2, home_team: Team, away_team: Team) Self {
    return Self{
        .home_team = home_team,
        .away_team = away_team,
        .player = Player.init(player_pos, scale, home_team, .black_1),
        .field = Field.init(scale, home_team),
        .scorebug = Scorebug.init(home_team, away_team),
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
    self.scorebug.deinit();
}

/// Updates the game scene.
pub fn update(self: *Self) !void {
    self.field.update();
    self.player.update();
    self.scorebug.update();

    // T-key or Y-button to generate new teams
    if (rl.isKeyPressed(.key_t) or rl.isGamepadButtonPressed(0, .gamepad_button_right_face_up)) {
        self.setHomeTeam(Team.random());
        self.setAwayTeam(Team.random());
    }

    // Y-key or A-button to switch the game site
    if (rl.isKeyPressed(.key_y) or rl.isGamepadButtonPressed(0, .gamepad_button_right_face_down)) {
        self.setSite(if (self.home_team.site == .home) .away else .home);
    }

    // R-key or B-button to switch the player's team
    if (rl.isKeyPressed(.key_r) or rl.isGamepadButtonPressed(0, .gamepad_button_right_face_right)) {
        const new_team = if (std.mem.eql(u8, self.player.team.name, self.home_team.name)) self.away_team else self.home_team;
        self.player.setTeam(new_team);
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
    // if (self.playclock == 0) {
    //     self.playclock = 40;
    // }
}

/// Draws the game scene.
pub fn draw(self: *Self) !void {
    self.drawWorld();
    try self.scorebug.draw(self);
}

/// Draws the non-HUD elements of the game scene.
pub fn drawWorld(self: *Self) void {
    self.player.startCamera();
    defer self.player.endCamera();

    self.field.draw();
    self.player.draw();
}

/// Sets the home team of the game.
pub fn setHomeTeam(self: *Self, team: Team) void {
    self.home_team = team;
    self.home_team.site = .home;
    self.player.setTeam(team);
    self.scorebug.setHomeTeam(team);
    self.field.setTeam(team);
}

/// Sets the away team of the game.
pub fn setAwayTeam(self: *Self, team: Team) void {
    self.away_team = team;
    self.away_team.site = .away;
    self.scorebug.setAwayTeam(team);
}

/// Sets the site of the game.
pub fn setSite(self: *Self, site: Team.GameSite) void {
    const home_team = self.home_team;
    const away_team = self.away_team;

    self.setHomeTeam(if (site == .home) home_team else away_team);
    self.setAwayTeam(if (site == .home) away_team else home_team);
}

/// Returns an instance of the scene
pub fn scene(self: *Self) Scene {
    return Scene.init(self);
}
