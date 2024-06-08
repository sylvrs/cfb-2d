const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const GameState = @import("../GameState.zig");
const Animation = @import("../engine/Animation.zig");
const Hitbox = @import("../engine/Hitbox.zig");
const Team = @import("../Team.zig");

const Self = @This();

const PlayerScale = 2;

pub const BaseSpeed = 2.25;
pub const MaxSpeed = BaseSpeed * 1.5;
pub const Acceleration = 0.5;

pub const Drag = 0.75;

pub const SkinColor = enum {
    const Map = std.StaticStringMap(rl.Color).initComptime(.{
        .{ "white_1", rl.Color.init(255, 231, 209, 255) },
        .{ "black_1", rl.Color.init(59, 34, 25, 255) },
    });
    const Values = std.enums.values(SkinColor);

    white_1,
    black_1,

    pub fn color(self: SkinColor) rl.Color {
        return Map.get(@tagName(self)).?;
    }

    /// Returns a random skin color.
    pub fn random() SkinColor {
        return Values[@intCast(rl.getRandomValue(0, Values.len - 1))];
    }
};

/// A map of field names to colors for color replacement.
const ColorReplacementMap = std.StaticStringMap(rl.Color).initComptime(.{
    .{ "primary_color", rl.Color.init(82, 82, 82, 255) },
    .{ "secondary_color", rl.Color.init(167, 167, 167, 255) },
    .{ "skin_color", rl.Color.white },
});

const AnimationSize = 32;
const AnimationType = enum(u8) {
    idle = 0,
    walk = 1,
    run = 2,
};

const Facing = enum { left, right };

/// Stores the player's team index and offset in the team.
pub const IndexData = struct { team_index: u8, player_index: u8 };

/// The player's position.
position: rl.Vector2,
/// The player's velocity.
velocity: rl.Vector2 = .{ .x = 0, .y = 0 },
/// The player's hitbox.
hitbox: Hitbox,
/// The player's speed.
speed: f32 = BaseSpeed,
/// The player's team.
team: Team,
/// The player's skin color.
skin_color: SkinColor,
/// The player's animation spritesheet.
animation: Animation,
/// The player's current animation.
current_animation: AnimationType = .idle,
/// The direction the player is facing.
facing: Facing = .right,

/// Creates a new player.
pub fn init(position: rl.Vector2, team: Team, team_state: Team.State, skin_color: SkinColor) Self {
    return .{
        .position = position,
        .hitbox = Hitbox{ .width = 14, .height = 20 },
        .team = team,
        .facing = if (team_state.site == .away) .left else .right,
        .skin_color = skin_color,
        .animation = Animation.init(
            loadAndShadeTexture(team, team_state, skin_color),
            1.25,
            AnimationSize,
            PlayerScale,
        ),
    };
}

/// Deinitializes the player.
pub fn deinit(self: *Self) void {
    self.animation.deinit();
}

/// Sets the player's team & updates the player's texture.
pub fn setTeam(self: *Self, team: Team, team_state: Team.State) void {
    self.team = team;
    self.animation.texture = loadAndShadeTexture(team, team_state, self.skin_color);
    self.facing = if (team_state.site == .away) .left else .right;
}

/// Updates the player.
pub fn update(self: *Self) void {
    // limit the player's position to the field
    var bounds = self.calculateBounds();

    // clamp the bounds to the field
    bounds.x = rl.math.clamp(bounds.x, 0, GameState.FieldWidth - bounds.width);
    bounds.y = rl.math.clamp(bounds.y, 0, GameState.FieldHeight - bounds.height);

    // update the player's velocity based on input
    self.velocity = self.velocity.clampValue(0, self.speed);

    self.position = self.velocity.add(self.position);
    self.velocity = self.velocity.scale(Drag);

    // set the position based on the bounds & hitbox
    // self.position.x = bounds.x - @as(f32, @floatFromInt(self.hitbox.width * PlayerScale)) / 2.0;
    // self.position.y = bounds.y - @as(f32, @floatFromInt(self.hitbox.height * PlayerScale)) / 2.0;

    // clamp the position based on the hitbox bounds
    self.position.x = rl.math.clamp(self.position.x, 0, GameState.FieldWidth - @as(f32, @floatFromInt(self.hitbox.width * PlayerScale)));
    self.position.y = rl.math.clamp(self.position.y, 0, GameState.FieldHeight - @as(f32, @floatFromInt(self.hitbox.height * PlayerScale)));

    self.animation.update();
}

/// Draws the player.
pub fn draw(self: *Self) void {
    self.animation.draw(self.position, if (self.facing == .right) .original else .flipped_x);
}

pub inline fn calculateBounds(self: *Self) rl.Rectangle {
    return .{
        .x = self.position.x + @as(f32, @floatFromInt(self.hitbox.width * PlayerScale)) / 2.0,
        .y = self.position.y + @as(f32, @floatFromInt(self.hitbox.height * PlayerScale)) / 2.0,
        .width = @floatFromInt(self.hitbox.width * PlayerScale),
        .height = @floatFromInt(self.hitbox.height * PlayerScale),
    };
}

/// The player's texture.
var player_image: ?rl.Image = null;

/// Loads the player's texture and shades it based on the team & skin color
/// TODO: we should keep a texture manager to avoid reloading/copying the same texture multiple times
fn loadAndShadeTexture(team: Team, team_state: Team.State, skin_color: SkinColor) rl.Texture2D {
    if (player_image == null) {
        player_image = rl.loadImage("assets/player.png");
    }
    var copied = player_image.?.copy();
    defer copied.unload();

    const jersey = team.fetchJersey(if (team_state.alternates) .alternate else if (team_state.site == .home) .home else .away);
    for (ColorReplacementMap.keys(), ColorReplacementMap.values()) |key, value| {
        const color = if (std.mem.eql(u8, key, "primary_color"))
            jersey.primary_color
        else if (std.mem.eql(u8, key, "secondary_color"))
            jersey.secondary_color
        else
            skin_color.color();

        copied.replaceColor(value, color);
    }

    return copied.toTexture();
}
