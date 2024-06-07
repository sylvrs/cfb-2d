const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Team = @import("Team.zig");
const GameScene = @import("./scenes/GameScene.zig");

const Self = @This();

const Scale = 3;
/// The angle of the parellelogram that the scorebug is drawn on.
const Angle: f32 = 25.2;
/// The offset of the parellelogram.
const Offset: f32 = std.math.tan(std.math.degreesToRadians(Angle));
/// The alignment of the elements.
const Alignment = enum { left, right };

const ReplaceMap = std.StaticStringMap(rl.Color).initComptime(.{
    .{ "home_team", rl.Color.init(88, 88, 88, 255) },
    .{ "away_team", rl.Color.init(255, 255, 255, 255) },
});

home_team: Team,
away_team: Team,
texture: rl.Texture,

pub fn init(home_team: Team, away_team: Team) Self {
    return Self{
        .home_team = home_team,
        .away_team = away_team,
        .texture = createReplacedTexture(home_team, away_team),
    };
}

pub fn deinit(self: *Self) void {
    self.texture.unload();
}

/// Updates the scorebug.
pub fn update(self: *Self) void {
    _ = self;
}

/// Draws the scorebug at the given position with the given tint.
pub fn draw(self: *Self, game: *GameScene) !void {
    utils.drawCenteredScaledTexture(
        self.texture,
        @floatFromInt(midpointWidth()),
        @floatFromInt(rl.getScreenHeight() - 50),
        Scale,
        rl.Color.light_gray,
    );

    try self.drawHomeHud(game);
    try self.drawAwayHud(game);

    try self.drawQuarter(game);
    try self.drawClock(game);
    try self.drawPlayClock(game);

    try self.drawDown(game);
}

/// Draws the play clock for the game.
inline fn drawPlayClock(self: *Self, game: *GameScene) !void {
    const width_diff: i32 = @intFromFloat(Offset * scaleByType(f32, self.texture.height));

    try utils.drawFmtText(
        midpointWidth() - scaleAndDivide(width_diff, 5),
        rl.getScreenHeight() - 20,
        scaleAndDivide(self.texture.height, 5),
        switch (game.playclock) {
            0...5 => rl.Color.red,
            else => rl.Color.yellow,
        },
        4,
        "{d:0>2}",
        .{game.playclock},
    );
}

/// Returns the ordinal suffix for the given number.
inline fn numberToOrdinal(number: u8) []const u8 {
    return switch (number) {
        1 => "st",
        2 => "nd",
        3 => "rd",
        else => "th",
    };
}

inline fn drawQuarter(self: *Self, game: *GameScene) !void {
    const width_diff: i32 = @intFromFloat(Offset * scaleByType(f32, self.texture.height));

    const actual_width = scaleByType(f32, self.texture.width);

    try utils.drawFmtText(
        midpointWidth() - @as(i32, @intFromFloat(@divFloor(actual_width, 2.0))) + scaleAndDivide(width_diff, 5),
        rl.getScreenHeight() - 20,
        scaleAndDivide(self.texture.height, 5),
        rl.Color.white,
        4,
        "{d}{s}",
        .{
            game.quarter,
            numberToOrdinal(game.quarter),
        },
    );
}

inline fn drawDown(self: *Self, game: *GameScene) !void {
    const half_width = scaleAndDivide(self.texture.width, 3);
    const font_size = scaleAndDivide(self.texture.height, 5);

    var text_buf: [16]u8 = undefined;
    const text = try std.fmt.bufPrintZ(&text_buf, "{d}{s} & {d}", .{ game.current_down, numberToOrdinal(game.current_down), game.yards_to_go });
    const text_width = rl.measureText(text, font_size);
    rl.drawText(
        text,
        midpointWidth() + @as(i32, half_width) - scaleAndDivide(text_width, 2),
        rl.getScreenHeight() - 20,
        font_size,
        rl.Color.white,
    );
}

inline fn drawClock(self: *Self, game: *GameScene) !void {
    const width_diff: i32 = @intFromFloat(Offset * scaleByType(f32, self.texture.height));

    const actual_width = scaleByType(f32, self.texture.width);

    try utils.drawFmtText(
        midpointWidth() - @as(i32, @intFromFloat(@divFloor(actual_width, 3.0))) + scaleAndDivide(width_diff, 5),
        rl.getScreenHeight() - 20,
        scaleAndDivide(self.texture.height, 5),
        rl.Color.white,
        8,
        "{d:0>2}:{d:0>2}",
        .{ game.time_remaining / 60, game.time_remaining % 60 },
    );
}

/// Draws the score for the given team at the given x offset.
inline fn drawScore(self: *Self, team_state: *Team.State, alignment: Alignment) !void {
    const width_diff: i32 = @intFromFloat(Offset * scaleByType(f32, self.texture.height));

    try utils.drawFmtText(
        midpointWidth() + switch (alignment) {
            .left => -width_diff,
            .right => @as(i32, @intFromFloat(@divFloor(@as(f32, @floatFromInt(width_diff)), 1.5))),
        },
        rl.getScreenHeight() - 42 - scaleAndDivide(self.texture.height, 2),
        scaleAndDivide(self.texture.height, 1.75),
        rl.Color.white,
        4,
        "{d}",
        .{team_state.score},
    );
}

/// Scales a value by the scorebug's scale.
inline fn scale(value: anytype) @TypeOf(value) {
    return scaleByType(@TypeOf(value), value);
}

/// Scales a value by the scorebug's scale and returns it as the given type.
inline fn scaleByType(comptime T: type, value: anytype) T {
    const type_info = @typeInfo(T);
    const value_type_info = @typeInfo(@TypeOf(value));
    return switch (value_type_info) {
        .Int => blk: {
            const value_as_float: f32 = @floatFromInt(value);
            break :blk if (type_info == .Int) @as(T, @intFromFloat(value_as_float * Scale)) else @as(T, value_as_float * Scale);
        },
        .Float => blk: {
            break :blk if (type_info == .Int) @as(T, @intFromFloat(value * Scale)) else @as(T, value * Scale);
        },
        else => @compileError("Unsupported type"),
    };
}

/// Scales and divides a value by the scorebug's scale and a divisor.
inline fn scaleAndDivide(value: anytype, divisor: f32) @TypeOf(value) {
    const result = (@as(f32, @floatFromInt(value)) * Scale) / divisor;
    return @as(@TypeOf(value), if (@typeInfo(@TypeOf(value)) == .Int) @intFromFloat(result) else result);
}

/// Draws a team's name to the scorebug given the team and alignment.
inline fn drawTeamName(self: *Self, team: Team, alignment: Alignment) !void {
    const name = rl.textToUpper(if (team.name.len > 13) team.acronym else team.name);

    // the width between the edge of the texture and the start of the parellelogram
    const font_size: i32 = scaleAndDivide(self.texture.height, 4.65);

    const actual_width = scaleByType(f32, self.texture.width);

    const half_texture_width: i32 = @intFromFloat(@divFloor(actual_width, 2.0));
    // offset the x position based on the alignment
    const starting_x = midpointWidth() + half_texture_width * switch (alignment) {
        .left => -1,
        .right => 1,
    };

    const name_width = rl.measureText(name, font_size);

    const width_diff: i32 = @intFromFloat(Offset * scaleByType(f32, self.texture.height));
    // where to move the x position based on the alignment
    const x_offset: i32 = switch (alignment) {
        // calculate the x offset based on the angle of the parellelogram and the width of the texture
        .left => width_diff,
        // otherwise, subtract part of the width from the calculated width difference
        .right => -width_diff - scaleAndDivide(name_width, Scale + 0.5),
    };

    try utils.drawFmtText(
        starting_x + x_offset,
        rl.getScreenHeight() - 85,
        font_size,
        rl.Color.white,
        16,
        "{s}",
        .{name},
    );
}

/// Returns the width of the screen divided by 2.
inline fn midpointWidth() i32 {
    return @divFloor(rl.getScreenWidth(), 2);
}

/// Draws the home team's HUD elements.
inline fn drawHomeHud(self: *Self, game: *GameScene) !void {
    try self.drawScore(try game.getTeamState(0), .left);
    try self.drawTeamName(game.getHomeTeam(), .right);
}

/// Draws the away team's HUD elements.
inline fn drawAwayHud(self: *Self, game: *GameScene) !void {
    try self.drawScore(try game.getTeamState(1), .right);
    try self.drawTeamName(game.getAwayTeam(), .left);
}

/// Sets the home team of the scorebug.
pub fn setHomeTeam(self: *Self, team: Team) void {
    self.home_team = team;
    self.texture.unload();
    self.texture = createReplacedTexture(team, self.away_team);
}

/// Sets the away team of the scorebug.
pub fn setAwayTeam(self: *Self, team: Team) void {
    self.away_team = team;
    self.texture.unload();
    self.texture = createReplacedTexture(self.home_team, team);
}

var scorebug_image: ?rl.Image = null;

/// Creates a new scorebug texture with the given teams.
fn createReplacedTexture(home_team: Team, away_team: Team) rl.Texture {
    if (scorebug_image == null) {
        scorebug_image = rl.loadImage("assets/scorebug.png");
    }
    var copied = scorebug_image.?.copy();
    defer copied.unload();

    copied.replaceColor(ReplaceMap.get("home_team").?, home_team.primary_color);
    copied.replaceColor(ReplaceMap.get("away_team").?, away_team.primary_color);

    return copied.toTexture();
}
