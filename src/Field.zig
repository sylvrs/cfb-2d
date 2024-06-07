const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const GameState = @import("GameState.zig");
const Team = @import("Team.zig");

const Self = @This();

const EndzoneText = struct {
    const Bounds = [_]struct { x: f32, y: f32, rotation: f32 }{
        .{ .x = 70, .y = GameState.FieldHeight / 2, .rotation = 270 },
        .{ .x = GameState.FieldWidth - 70, .y = GameState.FieldHeight / 2, .rotation = 90 },
    };
    // The height of the endzone text
    const Height = 60;
    const BaseSpacing = 96;
    const BrightnessFactor = 0.75;
};

const BaseTint = rl.Color.lime;

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
endzone_text: [:0]const u8,
/// The scale at which to draw the field
scale: f32 = 2,

/// Initializes an instance of the field
pub fn init(scale: f32, home_team: Team) Self {
    return Self{
        .base_texture = rl.loadTexture("assets/field_base.png"),
        .markers_texture = rl.loadTexture("assets/field_markers.png"),
        .endzones_texture = rl.loadTexture("assets/field_endzones.png"),
        .base_tint = if (home_team.field_color) |color| color else BaseTint,
        .endzones_tint = if (home_team.endzone_color) |color| color else home_team.primary_color,
        .endzone_text = home_team.name,
        // randomize the endzone tint
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

/// Sets the team of the field
pub fn setTeam(self: *Self, team: Team) void {
    self.endzones_tint = if (team.endzone_color) |color| color else team.primary_color;
    self.base_tint = if (team.field_color) |color| color else BaseTint;
    self.endzone_text = team.name;
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

    inline for (EndzoneText.Bounds) |bound| {
        utils.drawCenteredTextPro(
            rl.getFontDefault(),
            rl.textToUpper(self.endzone_text),
            rl.Vector2.init(bound.x, bound.y),
            rl.Vector2.init(0, 0),
            bound.rotation,
            // make the text 75% of the height of the endzone
            EndzoneText.Height * 0.85,
            EndzoneText.BaseSpacing / @as(f32, @floatFromInt(self.endzone_text.len)),
            self.endzones_tint.brightness(EndzoneText.BrightnessFactor),
        );
    }
}
