const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");

const Self = @This();

/// The texture to animate.
texture: rl.Texture,
/// How much time should pass before the next frame.
animation_time: f32,
/// The current frame of the animation.
current_frame: usize,
/// The time since the last frame change.
time_since_last_frame: f32,
/// The width of each frame in the texture.
frame_width: usize,
/// The total number of frames in the animation.
total_frames: usize,
/// The scale to render the texture at.
scale: f32 = 1.0,

/// Creates a new animation.
pub fn init(texture: rl.Texture, animation_speed: f32, frame_width: usize, scale: f32) Self {
    return Self{
        .texture = texture,
        .animation_time = 1.0 / animation_speed,
        .current_frame = 0,
        .time_since_last_frame = 0.0,
        .total_frames = @as(usize, @intCast(texture.width)) / frame_width,
        .frame_width = frame_width,
        .scale = scale,
    };
}

/// Deinitializes the animation.
pub fn deinit(self: *Self) void {
    self.texture.unload();
}

/// Returns the width of the animation given the scale.
pub inline fn width(self: Self) f32 {
    return @as(f32, @floatFromInt(self.frame_width)) * self.scale;
}

/// Returns the height of the animation given the scale.
pub inline fn height(self: Self) f32 {
    return @as(f32, @floatFromInt(self.texture.height)) * self.scale;
}

/// Updates the animation.
pub fn update(self: *Self) void {
    self.time_since_last_frame += rl.getFrameTime();
    if (self.time_since_last_frame >= self.animation_time) {
        self.current_frame = (self.current_frame + 1) % self.total_frames;
        self.time_since_last_frame = 0.0;
    }
}

/// Draws the animation at the given position.
pub fn draw(self: *Self, position: rl.Vector2) void {
    self.texture.drawPro(
        .{
            .x = @floatFromInt(self.current_frame * self.frame_width),
            .y = 0,
            .width = @floatFromInt(self.frame_width),
            .height = @floatFromInt(self.texture.height),
        },
        .{
            .x = position.x,
            .y = position.y,
            .width = self.width(),
            .height = self.height(),
        },
        .{ .x = 0, .y = 0 },
        0.0,
        rl.Color.light_gray,
    );
}
