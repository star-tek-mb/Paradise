const std = @import("std");
const platform = @import("platform.zig");
const paradise = @import("paradise.zig");

pub const log = platform.log;
pub const gl = platform.gl;

pub const Character = struct {
    moving_left: bool = false,
    moving_right: bool = false,
    moving_up: bool = false,
    moving_down: bool = false,
    large: bool = false,
};

var renderer: paradise.Renderer = undefined;
var sprite: paradise.Sprite = undefined;
var character = Character{};

fn update(delta: f32) void {
    gl.viewport(0, 0, 800, 600);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.clearColor(0.2, 0.3, 0.3, 1.0);

    // movement
    if (character.moving_left) {
        sprite.x -= 500 * delta;
        sprite.flip_x = true;
    }
    if (character.moving_right) {
        sprite.x += 500 * delta;
        sprite.flip_x = false;
    }
    if (character.moving_down) {
        sprite.y += 500 * delta;
    }
    if (character.moving_up) {
        sprite.y -= 500 * delta;
    }
    // screen bound
    if (sprite.x < 0.0) {
        sprite.x = 800.0;
    }
    if (sprite.y < 0.0) {
        sprite.y = 600.0;
    }
    if (sprite.x > 800.0) {
        sprite.x = 0.0;
    }
    if (sprite.y > 600.0) {
        sprite.y = 0.0;
    }
    // some action
    if (character.large) {
        sprite.w = 128.0;
        sprite.h = 128.0;
    } else {
        sprite.w = 64.0;
        sprite.h = 64.0;
    }

    renderer.start(800, 600);
    renderer.renderSprite(sprite);
    renderer.stop();
}

pub fn onKeyDown(key: u16) void {
    switch (key) {
        37 => character.moving_left = true,
        39 => character.moving_right = true,
        40 => character.moving_down = true,
        38 => character.moving_up = true,
        32 => character.large = !character.large,
        else => {},
    }
}

pub fn onKeyUp(key: u16) void {
    switch (key) {
        37 => character.moving_left = false,
        39 => character.moving_right = false,
        40 => character.moving_down = false,
        38 => character.moving_up = false,
        else => {},
    }
}

pub fn main() !void {
    platform.init();

    platform.onKeyDown(onKeyDown);
    platform.onKeyUp(onKeyUp);

    var image = try paradise.Image.load(std.heap.page_allocator, @embedFile("assets/character.qoi"));
    defer image.deinit(std.heap.page_allocator);
    sprite = try paradise.Sprite.fromImage(image);
    sprite.x = 100.0;
    sprite.y = 100.0;
    sprite.w = 64.0;
    sprite.h = 64.0;
    sprite.ox = 32.0;
    sprite.oy = 32.0;
    renderer = paradise.Renderer.init(std.heap.page_allocator);

    platform.run(update);
}
