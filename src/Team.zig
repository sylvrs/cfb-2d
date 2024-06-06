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

pub const GameSite = enum { home, away };

/// The team's jersey colors.
pub const Jersey = struct {
    primary_color: rl.Color,
    secondary_color: rl.Color,
};

pub const JerseyType = enum { home, away, alternate };

/// A team state that is used in game
pub const State = struct {
    score: u32 = 0,
    site: GameSite,
};

/// The team's name.
name: [:0]const u8,
/// The team's acronym.
acronym: [:0]const u8,
/// The team's primary color.
primary_color: rl.Color,
/// The team's secondary color.
secondary_color: rl.Color,
/// The team's custom field color (if applicable).
field_color: ?rl.Color = null,
/// The team's list of jerseys.
jerseys: std.EnumArray(JerseyType, Jersey),
/// The team's conference.
conference: Conference,

pub const AllTeams = std.ComptimeStringMap(Self, .{
    // BIG 12 teams
    mapInit("Baylor", "BU", .big_12, 0x154734, 0xFFB81C, .{}),
    mapInit("BYU", "BYU", .big_12, 0x0062B8, 0xFFFFFF, .{}),
    mapInit("Iowa State", "ISU", .big_12, 0xC8102E, 0xF1BE48, .{}),
    mapInit("Kansas", "KU", .big_12, 0x0051BA, 0xE8000D, .{}),
    mapInit("Kansas State", "K-State", .big_12, 0x512888, 0xD1D1D1, .{}),
    mapInit("Oklahoma State", "Oklahoma St", .big_12, 0xFF7300, 0x000000, .{}),
    mapInit("TCU", "TCU", .big_12, 0x4D1979, 0xC1C6C8, .{}),
    mapInit("Texas Tech", "TTU", .big_12, 0xCC0000, 0x000000, .{}),
    mapInit("West Virginia", "WVU", .big_12, 0x002855, 0xEAAA00, .{}),
    // MWC teams
    mapInit("Boise State", "Boise St", .mwc, 0xD64309, 0x0033A0, .{ .field_color = 0x0033A0 }),
});

const MapOptions = struct {
    field_color: ?u32 = null,
};

/// Initializes a team for the `AllTeams` map.
inline fn mapInit(name: [:0]const u8, acronym: [:0]const u8, conference: Conference, primary_color: u32, secondary_color: u32, options: MapOptions) struct { []const u8, Self } {
    return .{
        name, Self{
            .name = name,
            .acronym = acronym,
            .primary_color = resolveColor(primary_color),
            .secondary_color = resolveColor(secondary_color),
            .field_color = if (options.field_color) |color| resolveColor(color) else null,
            .jerseys = makeJerseysFromColors(primary_color, secondary_color),
            .conference = conference,
        },
    };
}

/// Creates an `EnumArray` of `Jersey` structs from primary and secondary colors.
inline fn makeJerseysFromColors(primary: u32, secondary: u32) std.EnumArray(JerseyType, Jersey) {
    return std.EnumArray(JerseyType, Jersey).init(.{
        .home = .{
            .primary_color = resolveColor(primary),
            .secondary_color = resolveColor(secondary),
        },
        .away = .{
            .primary_color = resolveColor(0xFFFFFF),
            .secondary_color = resolveColor(primary),
        },
        .alternate = .{
            .primary_color = resolveColor(primary),
            .secondary_color = resolveColor(0xFFFFFF),
        },
    });
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

/// Finds a team from the `AllTeams` map or throws an `UnknownTeam` error if not found.
pub fn find(name: [:0]const u8) !Self {
    return AllTeams.get(name) orelse error.UnknownTeam;
}

/// Returns a random team from the `AllTeams` map.
pub fn random() Self {
    const index = rl.getRandomValue(0, AllTeams.kvs.len - 1);
    const entry = AllTeams.kvs[@as(usize, @intCast(index))];
    return AllTeams.get(entry.key).?;
}

/// Returns the team's jersey based on the `JerseyType`.
pub fn fetchJersey(team: Self, jersey_type: JerseyType) Jersey {
    return team.jerseys.get(jersey_type);
}
