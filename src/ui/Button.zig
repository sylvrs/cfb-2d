const rl = @import("raylib");
const ui = @import("ui.zig");
const utils = @import("../utils.zig");

const Self = @This();

/// The state of the button.
const State = enum {
    normal,
    mouse_hover,
    gamepad_hover,
    pressed,
};

/// The vtable for the button.
const VTable = ui.Element.createVTable(Self);

/// The text of the button.
text: [:0]const u8,
/// The bounds of the button.
x: i32,
y: i32,
width: i32,
height: i32,
/// The state of the button.
state: State = .normal,
/// The color of the button.
bg_color: rl.Color,
/// The color of the text.
text_color: rl.Color,
/// The size of the font.
font_size: i32 = 20,
/// The context to pass to the button's action.
context: *anyopaque,
/// The action to perform when the button is clicked.
onClickFn: *const fn (context: *anyopaque) anyerror!void,

/// Returns the element for the button.
pub fn element(self: *Self) ui.Element {
    return .{ .vtable = &VTable, .context = self };
}

/// Gets the bounding box of the button.
pub fn getBounds(self: Self) ui.BoundingBox {
    return .{
        .x = self.x - @divFloor(self.width, 2),
        .y = self.y - @divFloor(self.height, 2),
        .width = self.width,
        .height = self.height,
    };
}

/// Draws the button.
pub fn draw(self: Self) void {
    // The color to tint the button based on its state.
    const bg_color: rl.Color = switch (self.state) {
        .mouse_hover => rl.Color.tint(self.bg_color, rl.Color.light_gray),
        .pressed => rl.Color.tint(self.bg_color, rl.Color.gray),
        else => self.bg_color,
    };
    rl.drawRectangle(
        self.x - @divFloor(self.width, 2),
        self.y - @divFloor(self.height, 2),
        self.width,
        self.height,
        bg_color,
    );
    utils.drawCenteredText(
        self.text,
        self.x,
        self.y,
        self.font_size,
        self.text_color,
    );

    if (self.state == .gamepad_hover) {
        rl.drawRectangleLinesEx(
            .{
                .x = @floatFromInt(self.x - @divFloor(self.width, 2)),
                .y = @floatFromInt(self.y - @divFloor(self.height, 2)),
                .width = @floatFromInt(self.width),
                .height = @floatFromInt(self.height),
            },
            5,
            rl.Color.brightness(self.bg_color, -1),
        );
    }
}

/// Returns a rectangle representing the bounds of the button.
pub inline fn bounds(self: Self) rl.Rectangle {
    return rl.Rectangle{
        .x = @floatFromInt(self.x),
        .y = @floatFromInt(self.y),
        .width = @floatFromInt(self.width),
        .height = @floatFromInt(self.height),
    };
}

/// Updates the state when the button is hovered.
pub fn onHover(self: *Self, current_input: ui.Menu.InputType) void {
    self.state = switch (current_input) {
        .mouse => .mouse_hover,
        .gamepad => .gamepad_hover,
    };
}

/// Updates the state when the button is no longer hovered.
pub fn onUnhover(self: *Self) void {
    self.state = .normal;
}

pub fn onPress(self: *Self) void {
    self.state = .pressed;
}

/// Updates the state & calls the onClickFn when the button is clicked.
pub fn onSelect(self: *Self) anyerror!void {
    try (self.onClickFn)(self.context);
}

pub fn update(self: *Self) void {
    _ = self;
}
