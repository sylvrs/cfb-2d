const std = @import("std");
const rl = @import("raylib");
const Color = rl.Color;

const Field = @import("Field.zig");
const Player = @import("Player.zig");
const utils = @import("utils.zig");

const Scale = 2;
/// The starting width of the window (predefined as the size of the field by the scale factor)
const ScreenWidth = 720 * Scale;
/// The starting height of the window. (predefined as the size of the field by the scale factor)
const ScreenHeight = 320 * Scale;
/// The title of the window.
const Title = "College Ball";
/// The period, in seconds, between each update of the window title.
const TitleUpdatePeriod = 3.0 / 4.0;

const ShouldFullscreen = false;

pub fn main() anyerror!void {
    rl.setConfigFlags(.flag_vsync_hint);
    rl.initWindow(ScreenWidth, ScreenHeight, Title);
    defer rl.closeWindow();
    rl.setWindowState(.flag_window_resizable);

    var title_task = Task{
        .period = 1.0 / 2.0,
        .task = struct {
            pub fn run() anyerror!void {
                try utils.setFmtWindowTitle(32, "{s} [FPS: {d}]", .{ Title, rl.getFPS() });
            }
        }.run,
    };

    var field = Field.init(Scale);
    var player = Player.init(.{ .x = ScreenWidth / 2, .y = ScreenHeight / 2 }, Scale);
    while (!rl.windowShouldClose()) {
        try title_task.tick();

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(Color.black);

        // set the player's zoom & field's scale based on the size of the window
        const new_scale: f32 = @floatFromInt(@divFloor(
            rl.getScreenWidth(),
            rl.getScreenHeight(),
        ));
        if (new_scale != field.scale) {
            player.setZoom(new_scale);
            field.setScale(new_scale);
        }

        // update the player
        player.update();
        // try utils.fmtTrace(.log_info, 48, "Player: (x: {d}, y: {d})", .{ player.position.x, player.position.y });

        // draw the field and player
        player.startCamera();
        defer player.endCamera();

        field.draw();
        player.draw();
    }
}

const Task = struct {
    /// The period, in seconds, between each run of the task.
    period: f32,
    /// An internal counter to keep track of the last time the task was run.
    last_run: f64 = 0,
    /// A constant function pointer to the task to run.
    task: *const fn () anyerror!void,

    /// Ticks the task, running it if the period has elapsed & updating the last run time.
    pub fn tick(self: *Task) anyerror!void {
        const now = rl.getTime();

        if (now - self.last_run >= self.period) {
            self.last_run = now;
            try (self.task)();
        }
    }
};
