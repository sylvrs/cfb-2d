const std = @import("std");
const rl = @import("raylib");
const ui = @import("ui.zig");
const utils = @import("../utils.zig");

const Self = @This();

/// The different types of input that the game can receive.
pub const InputType = enum { mouse, gamepad };

const ElementMetadata = struct {
    data_ptr: *anyopaque,
    size: usize,
    alignment: u8,
    element: ui.Element,
};

/// The allocator used by the menu to manage elements.
allocator: std.mem.Allocator,
/// The elements in the menu.
element_metadata: std.ArrayListUnmanaged(ElementMetadata) = .{},
/// The currently selected element.
selected_index: ?usize = null,
/// The current input type.
current_input: InputType = .mouse,

/// Initializes the menu.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        .current_input = if (rl.isGamepadAvailable(0)) .gamepad else .mouse,
    };
}

/// Deinitializes the menu.
pub fn deinit(self: *Self) void {
    // deallocate all element wrappers
    for (self.element_metadata.items) |metadata| {
        const wrapper_many_ptr: [*]u8 = @ptrCast(@constCast(metadata.data_ptr));
        self.allocator.rawFree(wrapper_many_ptr[0..metadata.size], metadata.alignment, @returnAddress());
    }
    self.element_metadata.deinit(self.allocator);
}

/// Allocates and adds an element to the menu.
pub fn addElement(self: *Self, wrapper: anytype) std.mem.Allocator.Error!void {
    const WrapperType = @TypeOf(wrapper);
    if (!@hasDecl(WrapperType, "element")) {
        @compileError("Element must declare an \"element\" method");
    }

    // copy the wrapper into memory
    const allocated = try self.allocator.create(WrapperType);
    allocated.* = wrapper;

    try self.element_metadata.append(self.allocator, ElementMetadata{
        .data_ptr = allocated,
        .size = @sizeOf(WrapperType),
        .alignment = @alignOf(WrapperType),
        .element = allocated.element(),
    });
}

/// Updates the menu's elements
pub fn update(self: *Self) !void {
    // update the current input type
    if ((rl.getMouseDelta().x != 0 or rl.getMouseDelta().y != 0 or rl.isMouseButtonPressed(.mouse_button_left)) and self.current_input != .mouse) {
        self.current_input = .mouse;
        self.selected_index = null;
    } else if (rl.getGamepadButtonPressed() != .gamepad_button_unknown and self.current_input != .gamepad) {
        self.current_input = .gamepad;
        self.selected_index = 0;
    }

    switch (self.current_input) {
        .mouse => try self.checkMouseInputs(),
        .gamepad => try self.checkGamepadInputs(),
    }

    for (self.element_metadata.items) |*metadata| {
        try metadata.element.update();
    }
}

/// Checks for mouse inputs & updates the menu as necessary.
pub fn checkMouseInputs(self: *Self) !void {
    const mouse_pos = rl.getMousePosition();

    const last_index = self.selected_index;
    var new_index: ?usize = null;
    for (self.element_metadata.items, 0..) |*metadata, current_index| {
        const bounds = metadata.element.getBounds();

        if (rl.checkCollisionPointRec(mouse_pos, bounds.toRect())) {
            new_index = current_index;
            if (self.selected_index == null or self.selected_index != current_index) {
                try self.onHover(current_index);
            }

            if (rl.isMouseButtonPressed(.mouse_button_left)) {
                try metadata.element.onPress();
            } else if (rl.isMouseButtonReleased(.mouse_button_left)) {
                try metadata.element.onSelect();
            }

            // only hover over one element at a time
            break;
        }
    }

    if (last_index != null and last_index != new_index) {
        try self.onUnhover(last_index.?);
    }
}

/// Checks for gamepad inputs & updates the menu as necessary.
pub fn checkGamepadInputs(self: *Self) !void {
    const last_index = self.selected_index;
    var new_index: ?usize = null;
    if (rl.isGamepadButtonPressed(0, .gamepad_button_left_face_up)) {
        new_index = (if (self.selected_index != null and self.selected_index.? > 0) self.selected_index.? - 1 else 0) % self.element_metadata.items.len;
    } else if (rl.isGamepadButtonPressed(0, .gamepad_button_left_face_down)) {
        new_index = (if (self.selected_index) |index| index + 1 else 0) % self.element_metadata.items.len;
    }

    if (new_index != null and new_index != last_index) {
        if (last_index) |index| try self.onUnhover(index);
        try self.onHover(new_index.?);
    }

    if (self.selected_index) |index| {
        const element = try self.resolveElement(index);
        if (rl.isGamepadButtonDown(0, .gamepad_button_right_face_down)) {
            try element.onPress();
        } else if (rl.isGamepadButtonReleased(0, .gamepad_button_right_face_down)) {
            try element.onSelect();
        }
    }
}

/// Called when an element is hovered over.
pub fn onHover(self: *Self, new_index: usize) !void {
    const element = try self.resolveElement(new_index);
    try element.onHover(self.current_input);
    self.selected_index = new_index;
}

/// Called when an element is unhovered.
pub fn onUnhover(self: *Self, previous_index: usize) !void {
    const element = try self.resolveElement(previous_index);
    try element.onUnhover();
    if (self.current_input == .mouse) {
        self.selected_index = null;
    }
}

/// Draws the menu.
pub fn draw(self: *Self) !void {
    for (self.element_metadata.items) |*metadata| {
        try metadata.element.draw();
    }
}

/// Resolves an element by its index or returns null if the index is out of bounds.
pub inline fn resolveElement(self: *Self, index: usize) !*ui.Element {
    if (index < 0 or index >= self.element_metadata.items.len) {
        return error.InvalidElement;
    }
    return &self.element_metadata.items[index].element;
}
