/// This struct represents a team that is playing the game.
const std = @import("std");
const rl = @import("raylib");

const Self = @This();

/// The team's conference.
pub const Conference = enum {
    big_12,
    big_ten,
    sec,
    acc,
    mac,
    mwc,
    sun_belt,
    aac,
    cusa,
};

/// The team's name.
name: [:0]const u8,
/// The team's primary color.
primary_color: rl.Color,
/// The team's secondary color.
secondary_color: rl.Color,
/// The team's conference.
conference: Conference,
/// The team's current score.
score: u32 = 0,

pub const AllTeams = std.ComptimeStringMap(Self, .{
    // BIG 12 teams
    mapInit("Baylor", 0x154734, 0xFFB81C, .big_12),
    mapInit("Iowa State", 0xC8102E, 0xF1BE48, .big_12),
    mapInit("Kansas", 0x0051BA, 0xE8000D, .big_12),
    mapInit("Kansas State", 0x512888, 0xD1D1D1, .big_12),
    mapInit("Oklahoma State", 0xFF7300, 0x000000, .big_12),
    mapInit("TCU", 0x4D1979, 0xC1C6C8, .big_12),
    mapInit("Texas Tech", 0xCC0000, 0x000000, .big_12),
    mapInit("West Virginia", 0x002855, 0xEAAA00, .big_12),
});

/// Initializes a team for the `AllTeams` map.
inline fn mapInit(name: [:0]const u8, primary_color: u32, secondary_color: u32, conference: Conference) struct { []const u8, Self } {
    return .{ name, Self{
        .name = name,
        .primary_color = resolveColor(primary_color),
        .secondary_color = resolveColor(secondary_color),
        .conference = conference,
    } };
}

/// Resolves a color from a hex value.
/// This is used instad of `rl.getColor` because it can be used at comptime.
inline fn resolveColor(hex: u32) rl.Color {
    return rl.Color{
        .r = (hex >> 16) & 0xFF,
        .g = (hex >> 8) & 0xFF,
        .b = hex & 0xFF,
        .a = 0xFF,
    };
}

/// Finds a team from the `AllTeams` map or returns `null` if the team does not exist.
pub fn find(name: [:0]const u8) !Self {
    return AllTeams.get(name) orelse error.UnknownTeam;
}

/// Returns a random team from the `AllTeams` map.
pub fn random() Self {
    const index = rl.getRandomValue(0, AllTeams.kvs.len - 1);
    const entry = AllTeams.kvs[@as(usize, @intCast(index))];
    return AllTeams.get(entry.key).?;
}
