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

pub inline fn cIntToFloat(i: c_int) f32 {
    return @as(f32, @floatFromInt(i));
}
