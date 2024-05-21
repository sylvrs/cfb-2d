const rl = @import("raylib");
const utils = @import("../utils.zig");

const Self = @This();

/// The state of the button.
const State = enum {
    normal,
    hovered,
    pressed,
};

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

/// Draws the button.
pub fn draw(self: Self) void {
    // The color to tint the button based on its state.
    const bg_color: rl.Color = switch (self.state) {
        .normal => self.bg_color,
        .hovered => rl.Color.tint(self.bg_color, rl.Color.light_gray),
        .pressed => rl.Color.tint(self.bg_color, rl.Color.gray),
    };
    rl.drawRectangle(self.x, self.y, self.width, self.height, bg_color);
    utils.drawCenteredText(
        self.text,
        self.x + @divFloor(self.width, 2),
        self.y + @divFloor(self.height, 2),
        self.font_size,
        self.text_color,
    );
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

/// Updates the button & calls the action if the button is clicked.
pub fn update(self: *Self) !void {
    const mouse_pos = rl.getMousePosition();
    if (!rl.checkCollisionPointRec(mouse_pos, self.bounds())) {
        self.state = .normal;
        return;
    }

    if (rl.isMouseButtonDown(.mouse_button_left)) {
        self.state = .pressed;
    } else {
        self.state = .hovered;
    }

    if (rl.isMouseButtonPressed(.mouse_button_left)) {
        try (self.onClickFn(self.context));
    }
}
