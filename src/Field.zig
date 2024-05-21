const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const GameState = @import("GameState.zig");

const Self = @This();

const EndzoneText = struct {
    const Bounds = [_]struct { x: f32, y: f32, rotation: f32 }{
        .{ .x = 70, .y = GameState.ScreenHeight / 2, .rotation = 270 },
        .{ .x = GameState.ScreenWidth - 70, .y = GameState.ScreenHeight / 2, .rotation = 90 },
    };
    const Size = 56;
    const Spacing = 8;
    const BrightnessFactor = 0.75;
};

/// The texture of the base field
base_texture: rl.Texture2D,
/// The texture of the field markers
markers_texture: rl.Texture2D,
/// The texture of the endzones
endzones_texture: rl.Texture2D,
/// The tint of the base field
base_tint: rl.Color,
/// The tint of the endzones
endzones_tint: rl.Color,
/// The text to display in the endzones
endzone_text: [:0]const u8,
/// The scale at which to draw the field
scale: f32 = 2,

/// Initializes an instance of the field
pub fn init(scale: f32) Self {
    return Self{
        .base_texture = rl.loadTexture("assets/field_base.png"),
        .markers_texture = rl.loadTexture("assets/field_markers.png"),
        .endzones_texture = rl.loadTexture("assets/field_endzones.png"),
        .base_tint = rl.Color.dark_green,
        .endzone_text = "COLLEGE FOOTBALL",
        // randomize the endzone tint
        .endzones_tint = tint: {
            const r: u8 = @intCast(rl.getRandomValue(1, 255));
            const g: u8 = @intCast(rl.getRandomValue(1, 255));
            const b: u8 = @intCast(rl.getRandomValue(1, 255));

            break :tint rl.Color.init(r, g, b, 255);
        },
        .scale = scale,
    };
}

/// Deinitializes the current instance of the field
pub fn deinit(self: *Self) void {
    rl.unloadTexture(self.base_texture);
    rl.unloadTexture(self.markers_texture);
    rl.unloadTexture(self.endzones_texture);
}

pub fn setScale(self: *Self, scale: f32) void {
    self.scale = scale;
}

/// Updates the field
pub fn update(self: *Self) void {
    _ = self;
}

/// Draws the field to the screen
pub fn draw(self: Self) void {
    utils.drawScaledTexture(self.base_texture, 0, 0, self.scale, self.base_tint);
    utils.drawScaledTexture(self.markers_texture, 0, 0, self.scale, rl.Color.white);
    self.drawEndzones();
}

/// Draws the endzones to the screen
pub fn drawEndzones(self: Self) void {
    utils.drawScaledTexture(self.endzones_texture, 0, 0, self.scale, self.endzones_tint);

    for (EndzoneText.Bounds) |bound| {
        utils.drawCenteredTextPro(
            rl.getFontDefault(),
            self.endzone_text,
            rl.Vector2.init(bound.x, bound.y),
            rl.Vector2.init(0, 0),
            bound.rotation,
            EndzoneText.Size,
            EndzoneText.Spacing,
            self.endzones_tint.brightness(EndzoneText.BrightnessFactor),
        );
    }
}
