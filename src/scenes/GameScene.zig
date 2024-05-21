const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const Field = @import("../Field.zig");
const Player = @import("../Player.zig");
const Scene = @import("../Scene.zig");

const Self = @This();

/// The player that is currently playing.
player: Player,
/// The field that the player is playing on.
field: Field,

/// Initializes a new instance of the game scene.
pub fn init(scale: f32, player_pos: rl.Vector2) Self {
    return Self{ .player = Player.init(player_pos, scale), .field = Field.init(scale) };
}

/// Deinitializes the game scene.
pub fn deinit(erased_self: *anyopaque) void {
    const self = utils.alignAndCast(Self, erased_self);
    self.field.deinit();
    self.player.deinit();
}

/// Updates the game scene.
pub fn update(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    self.player.update();
}

/// Draws the game scene.
pub fn draw(erased_self: *anyopaque) !void {
    const self = utils.alignAndCast(Self, erased_self);
    self.player.startCamera();
    defer self.player.endCamera();

    self.field.draw();
    self.player.draw();
}

/// Returns an instance of the scene
pub fn scene(self: *Self) Scene {
    return .{ .context = @ptrCast(self), .updateFn = update, .drawFn = draw, .deinitFn = deinit };
}
