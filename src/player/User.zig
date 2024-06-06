const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const GameState = @import("../GameState.zig");
const Player = @import("./Player.zig");

const Self = @This();

const CameraSmoothing = 0.15;

/// The camera following the user's player.
camera: rl.Camera2D,
/// The player being controlled by the user.
player: *Player,

pub fn init(player: *Player, zoom: f32) Self {
    return Self{
        .camera = .{
            // center the camera on the screen
            .offset = .{
                .x = @as(f32, @floatFromInt(rl.getRenderWidth())) / 2.0,
                .y = @as(f32, @floatFromInt(rl.getRenderHeight())) / 2.0,
            },
            .target = player.position,
            .rotation = 0.0,
            .zoom = zoom,
        },
        .player = player,
    };
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

/// Centers the camera on the player based on the screen size.
fn centerCamera(self: *Self) void {
    self.camera.offset = .{
        .x = @as(f32, @floatFromInt(rl.getRenderWidth())) / 2.0,
        .y = @as(f32, @floatFromInt(rl.getRenderHeight())) / 2.0,
    };
}

/// Updates the camera to follow the player.
pub fn update(self: *Self) void {
    // center the camera on the screen
    self.centerCamera();
    // interpolate the camera target towards the player's position
    self.camera.target = rlm.vector2Lerp(self.camera.target, self.player.position, CameraSmoothing);

    // limit the camera target to the bounds of the screen using the player's calculated bounds
    self.camera.target.x = rlm.clamp(self.camera.target.x, 0, GameState.FieldWidth);
    self.camera.target.y = rlm.clamp(self.camera.target.y, 0, GameState.FieldHeight);
}
