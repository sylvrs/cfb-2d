const rl = @import("raylib");
const utils = @import("utils.zig");

const Self = @This();

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
/// The scale at which to draw the field
scale: f32 = 2,

/// Initializes an instance of the field
pub fn init(scale: f32) Self {
    return Self{
        .base_texture = rl.loadTexture("assets/field_base.png"),
        .markers_texture = rl.loadTexture("assets/field_markers.png"),
        .endzones_texture = rl.loadTexture("assets/field_endzones.png"),
        .base_tint = rl.Color.dark_green,
        .endzones_tint = rl.Color.orange,
        .scale = scale,
    };
}

pub fn setScale(self: *Self, scale: f32) void {
    self.scale = scale;
}

/// Draws the field to the screen
pub fn draw(self: Self) void {
    utils.drawScaledTexture(self.base_texture, 0, 0, self.scale, self.base_tint);
    utils.drawScaledTexture(self.endzones_texture, 0, 0, self.scale, self.endzones_tint);
    utils.drawScaledTexture(self.markers_texture, 0, 0, self.scale, rl.Color.white);
}
