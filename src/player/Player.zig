const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const utils = @import("../utils.zig");
const GameState = @import("../GameState.zig");
const Animation = @import("../engine/Animation.zig");
const Hitbox = @import("../engine/Hitbox.zig");
const Team = @import("../Team.zig");

const Self = @This();

const PlayerScale = 2;

pub const BaseSpeed = 1.5;
pub const MaxSpeed = BaseSpeed * 1.5;
pub const Acceleration = 0.5;

pub const SkinColor = enum {
    const Map = std.ComptimeStringMap(rl.Color, .{
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
const ColorReplacementMap = std.ComptimeStringMap(rl.Color, .{
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

/// The player's position.
position: rl.Vector2,
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
    bounds.x = rlm.clamp(bounds.x, 0, GameState.FieldWidth - bounds.width);
    bounds.y = rlm.clamp(bounds.y, 0, GameState.FieldHeight - bounds.height);

    // set the position based on the bounds & hitbox
    self.position.x = bounds.x - @as(f32, @floatFromInt(self.hitbox.width * PlayerScale)) / 2.0;
    self.position.y = bounds.y - @as(f32, @floatFromInt(self.hitbox.height * PlayerScale)) / 2.0;

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
fn loadAndShadeTexture(team: Team, team_state: Team.State, skin_color: SkinColor) rl.Texture {
    if (player_image == null) {
        player_image = rl.loadImage("assets/player.png");
    }
    var copied = player_image.?.copy();
    defer copied.unload();

    const jersey = team.fetchJersey(if (team_state.alternates) .alternate else if (team_state.site == .home) .home else .away);
    inline for (ColorReplacementMap.kvs) |entry| {
        const color = if (std.mem.eql(u8, entry.key, "primary_color"))
            jersey.primary_color
        else if (std.mem.eql(u8, entry.key, "secondary_color"))
            jersey.secondary_color
        else
            skin_color.color();

        copied.replaceColor(entry.value, color);
    }

    return copied.toTexture();
}
