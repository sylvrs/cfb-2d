const rl = @import("raylib");
const rlm = @import("raylib-math");
const utils = @import("utils.zig");

const Self = @This();
const CameraSmoothing = 0.15;

const BaseSpeed = 1.5;
const MaxSpeed = BaseSpeed * 1.5;
const Acceleration = 0.5;

/// The camera following the player.
camera: rl.Camera2D,
/// The player's position.
position: rl.Vector2,
/// The player's speed.
speed: f32 = BaseSpeed,
/// The player's size.
size: rl.Vector2 = .{ .x = 20, .y = 40 },
/// The player's color.
color: rl.Color = rl.Color.red,

/// Creates a new player.
pub fn init(position: rl.Vector2, zoom: f32) Self {
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
    };
}

/// Deinitializes the player.
pub fn deinit(self: *Self) void {
    _ = self;
    // TODO: unload the textures once we load them
}

/// Updates the player.
pub fn update(self: *Self) void {
    // update the player's speed based on input
    self.speed = if (rl.isKeyDown(.key_left_shift) or rl.isGamepadButtonDown(0, .gamepad_button_right_trigger_2))
        rlm.lerp(self.speed, MaxSpeed, Acceleration)
    else
        rlm.lerp(self.speed, BaseSpeed, Acceleration);

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
    self.position.x = rlm.clamp(self.position.x, 0.0, @as(f32, @floatFromInt(rl.getRenderWidth())) - self.size.x);
    self.position.y = rlm.clamp(self.position.y, 0.0, @as(f32, @floatFromInt(rl.getRenderHeight())) - self.size.y);
}

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
    rl.drawRectangleV(self.position, self.size, self.color);
}
