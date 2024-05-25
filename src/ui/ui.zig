const rl = @import("raylib");
const utils = @import("../utils.zig");

pub const Menu = @import("./Menu.zig");
pub const Element = @import("./Element.zig");

pub const Button = @import("./Button.zig");

pub const BoundingBox = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    /// Converts the bounding box to a Raylib rectangle
    pub fn toRect(self: BoundingBox) rl.Rectangle {
        return .{
            .x = @floatFromInt(self.x),
            .y = @floatFromInt(self.y),
            .width = @floatFromInt(self.width),
            .height = @floatFromInt(self.height),
        };
    }
};
