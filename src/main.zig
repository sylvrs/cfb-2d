const std = @import("std");
const rl = @import("raylib");
const Color = rl.Color;

const Field = @import("Field.zig");
const Player = @import("player/Player.zig");
const utils = @import("utils.zig");
const Scene = @import("Scene.zig");

/// The game state, which holds the current scene and the task that updates the window title.
const GameState = @import("GameState.zig");

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    rl.setConfigFlags(.{ .vsync_hint = true });
    rl.setExitKey(.key_null);
    rl.initWindow(GameState.FieldWidth, GameState.FieldHeight, GameState.Title);
    defer rl.closeWindow();
    rl.setWindowState(.{ .window_resizable = true });

    var state = GameState.init(allocator);
    defer state.deinit();
    try state.setup();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(Color.black);

        try state.update();
        try state.draw();
    }
}
