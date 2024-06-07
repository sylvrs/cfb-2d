const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");

const GameState = @import("../GameState.zig");
const GameScene = @import("../scenes/GameScene.zig");
const Player = @import("./Player.zig");

const Self = @This();

const CameraSmoothing = 0.15;

const SelectedPlayerData = struct { team_index: usize, player_index: usize };

/// The camera following the user's player.
camera: rl.Camera2D,
/// The player being controlled by the user.
player_data: ?SelectedPlayerData = null,

pub fn init(zoom: f32) Self {
    return Self{
        .camera = rl.Camera2D{
            // center the camera on the screen
            .offset = .{
                .x = @as(f32, @floatFromInt(rl.getRenderWidth())) / 2.0,
                .y = @as(f32, @floatFromInt(rl.getRenderHeight())) / 2.0,
            },
            .target = rl.Vector2.init(0, 0),
            .rotation = 0.0,
            .zoom = zoom,
        },
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

/// Sets the player and teleports the camera to the player.
pub fn setSelectedPlayer(self: *Self, game: *GameScene, team_index: usize, player_index: usize) !void {
    self.player_data = .{ .team_index = team_index, .player_index = player_index };

    var team_state = try game.getTeamState(team_index);
    const player = try team_state.getNonNullPlayer(player_index);

    self.camera.target = player.position;
}

/// Updates the camera to follow the player.
pub fn update(self: *Self, game: *GameScene) !void {
    // center the camera on the screen
    self.centerCamera();

    try self.updatePlayer(game);

    // limit the camera target to the bounds of the screen using the player's calculated bounds
    self.camera.target.x = rlm.clamp(self.camera.target.x, 0, GameState.FieldWidth);
    self.camera.target.y = rlm.clamp(self.camera.target.y, 0, GameState.FieldHeight);
}

/// Updates the player if one is selected.
fn updatePlayer(self: *Self, game: *GameScene) !void {
    const data = self.player_data orelse return;
    var team = try game.getTeamState(data.team_index);
    var player = try team.getNonNullPlayer(data.player_index);
    // update the player's speed based on input
    player.speed = if (rl.isKeyDown(.key_left_shift) or rl.isGamepadButtonDown(0, .gamepad_button_right_trigger_2))
        rlm.lerp(player.speed, Player.MaxSpeed, Player.Acceleration)
    else
        rlm.lerp(player.speed, Player.BaseSpeed, Player.Acceleration);

    // move the player based on input
    if (rl.isKeyDown(.key_w) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_up)) {
        player.position.y -= player.speed;
    }
    if (rl.isKeyDown(.key_s) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_down)) {
        player.position.y += player.speed;
    }
    if (rl.isKeyDown(.key_a) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_left)) {
        player.position.x -= player.speed;
    }
    if (rl.isKeyDown(.key_d) or rl.isGamepadButtonDown(0, .gamepad_button_left_face_right)) {
        player.position.x += player.speed;
    }

    // interpolate the camera target towards the player's position
    self.camera.target = rlm.vector2Lerp(self.camera.target, player.position, CameraSmoothing);
}
