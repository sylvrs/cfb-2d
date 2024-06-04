const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const utils = @import("utils.zig");
const Animation = @import("./engine/Animation.zig");
const Team = @import("Team.zig");

const Self = @This();
const CameraSmoothing = 0.15;

const PlayerScale = 2;

const BaseSpeed = 1.5;
const MaxSpeed = BaseSpeed * 1.5;
const Acceleration = 0.5;

pub const SkinColor = enum {
    const Map = std.ComptimeStringMap(rl.Color, .{
        .{ "white_1", rl.Color.init(255, 231, 209, 255) },
        .{ "black_1", rl.Color.init(59, 34, 25, 255) },
    });

    white_1,
    black_1,

    pub fn color(self: SkinColor) rl.Color {
        return Map.get(@tagName(self)).?;
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

/// The camera following the player.
camera: rl.Camera2D,
/// The player's position.
position: rl.Vector2,
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

/// Creates a new player.
pub fn init(position: rl.Vector2, zoom: f32, team: Team, skin_color: SkinColor) Self {
    return .{
        .camera = .{
            // center the camera on the screen
            .offset = .{
                .x = @as(f32, @floatFromInt(rl.getRenderWidth())) / 2.0,
                .y = @as(f32, @floatFromInt(rl.getRenderHeight())) / 2.0,
            },
            .target = position,
            .rotation = 0.0,
            .zoom = zoom,
        },
        .position = position,
        .team = team,
        .skin_color = skin_color,
        .animation = Animation.init(
            loadAndShadeTexture(team, skin_color),
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

/// Updates the player.
pub fn update(self: *Self) void {
    // update the player's speed based on input
    self.speed = if (rl.isKeyDown(.key_left_shift) or rl.isGamepadButtonDown(0, .gamepad_button_right_trigger_2))
        rlm.lerp(self.speed, MaxSpeed, Acceleration)
    else
        rlm.lerp(self.speed, BaseSpeed, Acceleration);

    // debug key to change the player's team
    if (rl.isKeyDown(.key_t) or rl.isGamepadButtonPressed(0, .gamepad_button_right_face_up)) {
        self.team = Team.random();
        self.animation.texture = loadAndShadeTexture(self.team, self.skin_color);
        utils.fmtTrace(.log_info, 64, "New Team: {s}", .{self.team.name}) catch unreachable;
    }

    // move the player based on input
    if (rl.isKeyDown(.key_w) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_up)) {
        self.position.y -= self.speed;
    }
    if (rl.isKeyDown(.key_s) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_down)) {
        self.position.y += self.speed;
    }
    if (rl.isKeyDown(.key_a) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_left)) {
        self.position.x -= self.speed;
    }
    if (rl.isKeyDown(.key_d) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_right)) {
        self.position.x += self.speed;
    }

    // limit the player's position to the bounds of the screen
    self.position.x = rlm.clamp(self.position.x, 0.0, @as(f32, @floatFromInt(rl.getRenderWidth())) - self.animation.width());
    self.position.y = rlm.clamp(self.position.y, 0.0, @as(f32, @floatFromInt(rl.getRenderHeight())) - self.animation.height());

    self.animation.update();
}

/// Updates the camera's zoom
pub fn setZoom(self: *Self, zoom: f32) void {
    self.camera.zoom = zoom;
}

/// Indicates the camera to start following the player.
pub fn startCamera(self: *Self) void {
    self.camera.begin();
}

/// Indicates the camera to stop following the player.
pub fn endCamera(self: *Self) void {
    self.camera.end();
}

pub fn draw(self: *Self) void {
    // interpolate the camera target towards the player's position
    self.camera.target = rlm.vector2Lerp(self.camera.target, self.position, CameraSmoothing);

    // limit the camera target to the bounds of the screen
    self.camera.target.x = rlm.clamp(self.camera.target.x, 0.0, @as(f32, @floatFromInt(rl.getRenderWidth())));
    self.camera.target.y = rlm.clamp(self.camera.target.y, 0.0, @as(f32, @floatFromInt(rl.getRenderHeight())));

    self.animation.draw(self.position);
}

/// Loads the player's texture and shades it based on the team & skin color
fn loadAndShadeTexture(team: Team, skin_color: SkinColor) rl.Texture {
    var image = rl.loadImage("assets/player.png");
    defer image.unload();
    var copied = image.copy();
    defer copied.unload();

    const jersey = team.fetchJersey(if (team.site == .home) .home else .away);
    inline for (ColorReplacementMap.kvs) |entry| {
        const color = if (std.mem.eql(u8, entry.key, "primary_color"))
            jersey.primary_color
        else if (std.mem.eql(u8, entry.key, "secondary_color"))
            jersey.secondary_color
        else
            skin_color.color();

        copied.replaceColor(entry.value, color);
    }

    return rl.Texture.fromImage(copied);
}
