const std = @import("std");
const rl = @import("raylib");

/// Formats and logs a message to the Raylib trace log. Requires a comptime known buffer size.
pub fn fmtTrace(log_level: rl.TraceLogLevel, comptime buf_size: usize, comptime fmt: []const u8, args: anytype) std.fmt.BufPrintError!void {
    var msg_buf: [buf_size]u8 = undefined;
    const msg = try std.fmt.bufPrintZ(&msg_buf, fmt, args);
    rl.traceLog(log_level, msg);
}

/// Formats and sets the window title. Requires a comptime known buffer size.
pub fn setFmtWindowTitle(comptime buf_size: usize, comptime fmt: []const u8, args: anytype) std.fmt.BufPrintError!void {
    var title_buf: [buf_size]u8 = undefined;
    const title = try std.fmt.bufPrintZ(&title_buf, fmt, args);
    rl.setWindowTitle(title);
}

/// Formats and draws text at the specified position. Requires a comptime known buffer size.
pub fn drawFmtText(x: i32, y: i32, font_size: i32, color: rl.Color, comptime buf_size: usize, comptime fmt: []const u8, args: anytype) std.fmt.BufPrintError!void {
    var text_buf: [buf_size]u8 = undefined;
    const text = try std.fmt.bufPrintZ(&text_buf, fmt, args);
    rl.drawText(text, x, y, font_size, color);
}

/// Formats, centers, and draws text at the specified position. Requires a comptime known buffer size.
pub fn drawCenteredFmtText(x: i32, y: i32, font_size: i32, color: rl.Color, comptime buf_size: usize, comptime fmt: []const u8, args: anytype) std.fmt.BufPrintError!void {
    var text_buf: [buf_size]u8 = undefined;
    const text = try std.fmt.bufPrintZ(&text_buf, fmt, args);
    drawCenteredText(text, x, y, font_size, color);
}

/// Formats and draws text with a background rectangle. Requires a comptime known buffer size.
pub fn drawFmtTextWithBackground(x: i32, y: i32, font_size: i32, text_color: rl.Color, bg_color: rl.Color, comptime buf_size: usize, comptime fmt: []const u8, args: anytype) std.fmt.BufPrintError!void {
    var text_buf: [buf_size]u8 = undefined;
    const text = try std.fmt.bufPrintZ(&text_buf, fmt, args);
    const text_size = rl.measureText(text, font_size);

    rl.drawRectangle(
        x,
        y,
        text_size,
        font_size,
        bg_color,
    );
    rl.drawText(text, x, y, font_size, text_color);
}

/// Draws text centered at the specified position.
pub fn drawCenteredText(text: [:0]const u8, x: i32, y: i32, font_size: i32, text_color: rl.Color) void {
    const text_size = rl.measureText(text, font_size);
    const text_x = x - @divFloor(text_size, 2);
    const text_y = y - @divFloor(font_size, 2);

    rl.drawText(text, text_x, text_y, font_size, text_color);
}

/// Draws text centered at the specified position.
pub fn drawCenteredTextPro(font: rl.Font, text: [:0]const u8, position: rl.Vector2, origin: rl.Vector2, rotation: f32, font_size: f32, spacing: f32, text_color: rl.Color) void {
    const text_bounds = rl.measureTextEx(font, text, font_size, spacing);
    rl.drawTextPro(
        font,
        text,
        position,
        rl.Vector2.init(origin.x + text_bounds.x / 2, origin.y + text_bounds.y / 2),
        rotation,
        font_size,
        spacing,
        text_color,
    );
}

/// Draws a centered rectangle at the specified position.
pub inline fn drawCenteredRectangle(x: i32, y: i32, width: i32, height: i32, color: rl.Color) void {
    rl.drawRectangle(
        x - @divFloor(width, 2),
        y - @divFloor(height, 2),
        width,
        height,
        color,
    );
}

/// Draws a texture at the specified position with the specified scale.
pub fn drawScaledTexture(texture: rl.Texture2D, pos_x: f32, pos_y: f32, scale: f32, tint: rl.Color) void {
    rl.drawTexturePro(
        texture,
        .{ .x = 0, .y = 0, .width = cIntToFloat(texture.width), .height = cIntToFloat(texture.height) },
        .{ .x = pos_x, .y = pos_y, .width = cIntToFloat(texture.width) * scale, .height = cIntToFloat(texture.height) * scale },
        .{ .x = 0, .y = 0 },
        0.0,
        tint,
    );
}

/// Creates a randomized color with the given type, low, and high values.
pub fn randomColor() rl.Color {
    const r: u8 = @intCast(rl.getRandomValue(1, 255));
    const g: u8 = @intCast(rl.getRandomValue(1, 255));
    const b: u8 = @intCast(rl.getRandomValue(1, 255));
    return rl.Color.init(r, g, b, 255);
}

pub inline fn cIntToFloat(i: c_int) f32 {
    return @as(f32, @floatFromInt(i));
}

/// Casts an opaque pointer to a typed pointer.
pub fn alignAndCast(comptime T: type, erased_ptr: *anyopaque) *T {
    return @alignCast(@ptrCast(erased_ptr));
}

/// A simple task struct that runs a function pointer at a specified period.
pub fn Task(comptime TContext: type) type {
    return struct {
        const Self = @This();

        /// The period, in seconds, between each run of the task.
        period: f32,
        /// An internal counter to keep track of the last time the task was run.
        last_run: f64 = 0,
        /// A constant function pointer to the task to run.
        task: *const fn (*TContext) anyerror!void,
        context: *TContext,

        /// Initializes the task with the specified period, task function pointer, and context.
        pub fn init(period: f32, task: *const fn (*TContext) anyerror!void, context: *TContext) Self {
            return Self{ .period = period, .task = task, .context = context };
        }

        /// Ticks the task, running it if the period has elapsed & updating the last run time.
        pub fn tick(self: *Self) anyerror!void {
            const now = rl.getTime();

            if (now - self.last_run >= self.period) {
                self.last_run = now;
                try (self.task)(self.context);
            }
        }
    };
}
