# Overview

Paradise is a wasm first game engine written in zig.

# Status

Development stopped for now until zig stage2 async.

# Architecture

All images are embedded qoi images.

Keep engine as simple as possible.

# TODO

* Use package manager to fetch modules (priority)
* Find a way to fetch resources (not embed). We should wait for zig async/await in stage2.
* Find js object/function/string leaks.
* Port to other platforms (not now).

Add audio engine.

# Usage

```zig
const std = @import("std");
const platform = @import("platform.zig");
const paradise = @import("paradise.zig");

comptime {
    _ = platform;
}

pub const log = platform.log;
pub const gl = platform.gl;

var renderer: paradise.Renderer = undefined;
var sprite: paradise.Sprite = undefined;

fn update(_: f32) void {
    gl.viewport(0, 0, 800, 600);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.clearColor(0.2, 0.3, 0.3, 1.0);

    renderer.start(800, 600);
    renderer.renderSprite(sprite);
    renderer.stop();
}

pub fn onKeyDown(key: u16) void {
    if (key == 37) {
        sprite.x -= 10;
        sprite.w = -@fabs(sprite.w);
    }
    if (key == 39) {
        sprite.x += 10;
        sprite.w = @fabs(sprite.w);
    }
}

pub fn main() !void {
    platform.init();

    platform.onKeyDown(onKeyDown);

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
```

see **src/main.zig**

# Credits

https://github.com/hexops/mach - for sysjs, for wasmserve

https://github.com/ziglibs/zlm - vector math

https://github.com/MasterQ32/zig-qoi - for image loading
