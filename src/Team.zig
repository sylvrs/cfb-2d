/// This struct represents a team that is playing the game.
const std = @import("std");
const rl = @import("raylib");
const Player = @import("./player/Player.zig");

const Self = @This();

/// The FBS conferences.
pub const FBSConference = enum {
    big_12,
    big_ten,
    sec,
    acc,
    mac,
    mwc,
    sun_belt,
    aac,
    cusa,
    independents,
};

pub const FCSConference = enum {
    big_sky,
    big_south,
    caa,
    independent,
    meac,
    mvfc,
    nec,
    ovc,
    patriot,
    pioneer,
    socon,
    southland,
    swac,
    united,
    ivy,
};

pub const DivisionIIConference = enum {
    ciaa,
    gac,
    gliac,
    glvc,
    gmwac,
    gsc,
    independents,
    lsc,
    miaa,
    mountain_east,
    ne10,
    nsic,
    psac,
    rmac,
    sac,
    siac,
};

pub const Division = union(enum) {
    fbs: FBSConference,
    fcs: FCSConference,
    d2: DivisionIIConference,
};

pub const GameSite = enum { home, away };

/// The team's jersey colors.
pub const Jersey = struct {
    primary_color: rl.Color,
    secondary_color: rl.Color,
};

pub const JerseyType = enum { home, away, alternate };

/// The maximum number of players on a team.
pub const MaxPlayers = 11;

/// A team state that is used in game
pub const State = struct {
    score: u32 = 0,
    site: GameSite,
    alternates: bool = false,
    players: [MaxPlayers]?Player = [_]?Player{null} ** MaxPlayers,

    /// Sets the player at the given index.
    pub fn setPlayer(self: *State, index: usize, player: Player) void {
        self.players[index] = player;
    }

    /// Gets the player at the given index.
    pub fn getPlayer(self: *State, index: usize) *?Player {
        return &self.players[index];
    }

    /// Gets the player or returns an error if the player is null.
    pub inline fn getNonNullPlayer(self: *State, index: usize) !*Player {
        if (self.players[index] == null) return error.UnknownPlayer;
        return &(self.players[index].?);
    }

    /// Draws the team's players.
    pub fn draw(self: *State) void {
        for (0..MaxPlayers) |index| {
            if (self.players[index] == null) continue;
            self.players[index].?.draw();
        }
    }

    /// Updates the team's players.
    pub fn update(self: *State) void {
        for (0..MaxPlayers) |index| {
            if (self.players[index] == null) continue;
            self.players[index].?.update();
        }
    }
};

/// The team's name.
name: [:0]const u8,
/// The team's mascot
mascot: [:0]const u8,
/// The team's acronym.
acronym: [:0]const u8,
/// The team's primary color.
primary_color: rl.Color,
/// The team's secondary color.
secondary_color: rl.Color,
/// The team's custom field color (if applicable).
field_color: ?rl.Color = null,
/// The team's custom endzone color (if applicable).
endzone_color: ?rl.Color = null,
/// The team's list of jerseys.
jerseys: std.EnumArray(JerseyType, Jersey),
/// The team's division (holds both division and conference).
division: Division,

pub const AllTeams = std.ComptimeStringMap(Self, .{
    // -- FBS
    // BIG 12 teams
    fbsInit("Baylor", "Bears", "BU", .big_12, 0x154734, 0xFFB81C, .{}),
    fbsInit("BYU", "Cougars", "BYU", .big_12, 0x0062B8, 0xFFFFFF, .{}),
    fbsInit("Iowa State", "Cyclones", "ISU", .big_12, 0xC8102E, 0xF1BE48, .{}),
    fbsInit("Kansas", "Jayhawks", "KU", .big_12, 0x0051BA, 0xE8000D, .{}),
    fbsInit("Kansas State", "Wildcats", "K-State", .big_12, 0x512888, 0xD1D1D1, .{}),
    fbsInit("Oklahoma State", "Cowboys", "Oklahoma St", .big_12, 0xFF7300, 0x000000, .{}),
    fbsInit("TCU", "Horned Frogs", "TCU", .big_12, 0x4D1979, 0xC1C6C8, .{}),
    fbsInit("Texas Tech", "Red Raiders", "TTU", .big_12, 0xCC0000, 0x000000, .{}),
    fbsInit("West Virginia", "Mountaineers", "WVU", .big_12, 0x002855, 0xEAAA00, .{}),
    // MWC teams
    fbsInit("Boise State", "Broncos", "Boise St", .mwc, 0xD64309, 0x0033A0, .{ .field_color = 0x0033A0 }),
    // SBC teams
    fbsInit("Coastal Carolina", "Chanticleers", "Coastal", .sun_belt, 0x006F71, 0xA27752, .{ .field_color = 0x006F71, .endzone_color = 0xA27752 }),
    // -- FCS
    // Big Sky teams
    fcsInit("Eastern Washington", "Eagles", "EWU", .big_sky, 0xA10022, 0x000000, .{ .field_color = 0xA10022, .endzone_color = 0x000000 }),
    // MVFC teams
    fcsInit("North Dakota State", "Bison", "NDSU", .mvfc, 0x0A5640, 0xFFC72A, .{ .endzone_color = 0xFFC72A }),
    // -- Division II
    // Mountain East
    d2Init("West Virginia State", "Yellow Jackets", "WVSU", .mountain_east, 0xCFAB2B, 0x000000, .{ .endzone_color = 0x00000 }),
});

const MapOptions = struct {
    /// The custom field color.
    field_color: ?u32 = null,
    /// The custom endzone color.
    endzone_color: ?u32 = null,
};

/// Initializes an FBS team for the `AllTeams` map.
inline fn fbsInit(
    name: [:0]const u8,
    mascot: [:0]const u8,
    acronym: [:0]const u8,
    conference: FBSConference,
    primary_color: u32,
    secondary_color: u32,
    options: MapOptions,
) struct { []const u8, Self } {
    return mapInit(name, mascot, acronym, .{ .fbs = conference }, primary_color, secondary_color, options);
}

/// Initializes an FCS team for the `AllTeams` map.
inline fn fcsInit(
    name: [:0]const u8,
    mascot: [:0]const u8,
    acronym: [:0]const u8,
    conference: FCSConference,
    primary_color: u32,
    secondary_color: u32,
    options: MapOptions,
) struct { []const u8, Self } {
    return mapInit(name, mascot, acronym, .{ .fcs = conference }, primary_color, secondary_color, options);
}

/// Initializes a Division II team for the `AllTeams` map.
inline fn d2Init(
    name: [:0]const u8,
    mascot: [:0]const u8,
    acronym: [:0]const u8,
    conference: DivisionIIConference,
    primary_color: u32,
    secondary_color: u32,
    options: MapOptions,
) struct { []const u8, Self } {
    return mapInit(name, mascot, acronym, .{ .d2 = conference }, primary_color, secondary_color, options);
}

/// Initializes a team for the `AllTeams` map.
inline fn mapInit(
    name: [:0]const u8,
    mascot: [:0]const u8,
    acronym: [:0]const u8,
    division: Division,
    primary_color: u32,
    secondary_color: u32,
    options: MapOptions,
) struct { []const u8, Self } {
    return .{
        name, Self{
            .name = name,
            .mascot = mascot,
            .acronym = acronym,
            .primary_color = resolveColor(primary_color),
            .secondary_color = resolveColor(secondary_color),
            .field_color = if (options.field_color) |color| resolveColor(color) else null,
            .endzone_color = if (options.endzone_color) |color| resolveColor(color) else null,
            .jerseys = makeJerseysFromColors(primary_color, secondary_color),
            .division = division,
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
            .primary_color = resolveColor(secondary),
            .secondary_color = resolveColor(primary),
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
