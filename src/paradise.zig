const std = @import("std");
const platform = @import("platform.zig");
const qoi = @import("qoi");
const zlm = @import("zlm");
const gl = platform.gl;

pub const Image = struct {
    width: u32,
    height: u32,
    data: []u8,

    pub fn load(allocator: std.mem.Allocator, data: []const u8) !Image {
        var qoi_image = try qoi.decodeBuffer(allocator, data);
        return Image{
            .width = qoi_image.width,
            .height = qoi_image.height,
            .data = std.mem.sliceAsBytes(qoi_image.pixels),
        };
    }

    pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }
};

pub const Texture = struct {
    id: c_uint,

    pub fn loadImage(image: Image) !Texture {
        var texture: Texture = undefined;
        texture.id = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture.id);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @intCast(c_int, image.width), @intCast(c_int, image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data.ptr);
        return texture;
    }

    pub fn bind(self: *Texture, unit: u32) void {
        gl.activeTexture(gl.TEXTURE0 + unit);
        gl.bindTexture(gl.TEXTURE_2D, self.id);
    }

    pub fn deinit(self: *Texture) void {
        gl.deleteTexture(self.id);
    }
};

pub const Shader = struct {
    id: c_uint,

    pub fn load(vs_src: []const u8, fs_src: []const u8) !Shader {
        var vs = gl.createShader(gl.VERTEX_SHADER);
        defer gl.deleteShader(vs);
        gl.shaderSource(vs, 1, vs_src.ptr, vs_src.len);
        gl.compileShader(vs);
        if (gl.getShaderParameter(vs, gl.COMPILE_STATUS) == gl.FALSE) {
            return error.VertexShaderCompilationError;
        }
        var fs = gl.createShader(gl.FRAGMENT_SHADER);
        defer gl.deleteShader(fs);
        gl.shaderSource(fs, 1, fs_src.ptr, fs_src.len);
        gl.compileShader(fs);
        if (gl.getShaderParameter(fs, gl.COMPILE_STATUS) == gl.FALSE) {
            return error.FragmentShaderCompilationError;
        }
        var program = gl.createProgram();
        gl.attachShader(program, vs);
        gl.attachShader(program, fs);
        gl.linkProgram(program);
        if (gl.getProgramParameter(program, gl.LINK_STATUS) == gl.FALSE) {
            return error.ShaderProgramCompilationError;
        }
        return Shader{ .id = program };
    }

    pub fn use(self: *Shader) void {
        gl.useProgram(self.id);
    }

    pub fn uniform1i(self: *Shader, location: []const u8, value: c_int) void {
        gl.uniform1i(gl.getUniformLocation(self.id, location), value);
    }

    pub fn uniform1f(self: *Shader, location: []const u8, value: f32) void {
        gl.uniform1f(gl.getUniformLocation(self.id, location), value);
    }

    pub fn deinit(self: *Shader) void {
        gl.deleteProgram(self.id);
    }
};

pub const Sprite = struct {
    texture: Texture,
    texcoords: [4]f32,
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    r: f32,
    ox: f32,
    oy: f32,

    pub fn fromImage(image: Image) !Sprite {
        return try Sprite.fromSubImage(image, 0, 0, image.width, image.height);
    }

    pub fn fromSubImage(image: Image, x: u32, y: u32, w: u32, h: u32) !Sprite {
        var sprite: Sprite = undefined;
        sprite.texture = try Texture.loadImage(image);
        sprite.texcoords[0] = @intToFloat(f32, x) / @intToFloat(f32, image.width);
        sprite.texcoords[1] = @intToFloat(f32, y) / @intToFloat(f32, image.height);
        sprite.texcoords[2] = @intToFloat(f32, x + w) / @intToFloat(f32, image.width);
        sprite.texcoords[3] = @intToFloat(f32, y + h) / @intToFloat(f32, image.height);
        // set position at 0, 0
        sprite.x = 0.0;
        sprite.y = 0.0;
        // original size
        sprite.w = @intToFloat(f32, w);
        sprite.h = @intToFloat(f32, h);
        sprite.r = 0.0;
        // origin at center
        sprite.ox = @intToFloat(f32, w) / 2.0;
        sprite.oy = @intToFloat(f32, h) / 2.0;
        return sprite;
    }
};

pub const Renderer = struct {
    buffer: c_uint,
    texture: Texture, // we are not owning this texture
    shader: Shader,
    data: std.ArrayList(f32),
    projection: zlm.Mat4,

    pub fn init(allocator: std.mem.Allocator) Renderer {
        var result: Renderer = undefined;
        result.data = std.ArrayList(f32).init(allocator);
        result.shader = Shader.load(@embedFile("assets/2d.vs.glsl"), @embedFile("assets/2d.fs.glsl")) catch unreachable;
        result.buffer = gl.createBuffer();
        return result;
    }

    pub fn deinit(self: *Renderer) void {
        self.data.deinit();
        self.shader.deinit();
        gl.deleteBuffer(self.buffer);
    }

    pub fn start(self: *Renderer, width: u32, height: u32) void {
        gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));

        self.projection = zlm.Mat4.createOrthogonal(0.0, @intToFloat(f32, width), @intToFloat(f32, height), 0.0, -1.0, 1.0);
        gl.disable(gl.DEPTH_TEST);
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        self.shader.use();
        self.shader.uniform1i("texsampler", 0);
    }

    fn flush(self: *Renderer) void {
        if (self.data.items.len == 0) {
            return;
        }

        gl.bindBuffer(gl.ARRAY_BUFFER, self.buffer);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(c_int, self.data.items.len * @sizeOf(f32)), self.data.items.ptr, gl.DYNAMIC_DRAW);

        self.texture.bind(0);

        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * @sizeOf(f32), @intToPtr(*allowzero anyopaque, 0));
        gl.drawArrays(gl.TRIANGLES, 0, @intCast(c_int, self.data.items.len / 4));

        self.data.clearRetainingCapacity();
    }

    pub fn renderSprite(self: *Renderer, sprite: Sprite) void {
        if (self.texture.id != sprite.texture.id) {
            self.flush();
        }
        self.texture = sprite.texture;

        // mvp = model x view x projection
        var final = zlm.Mat4.identity;
        final = final.mul(zlm.Mat4.createScale(sprite.w, sprite.h, 1.0));
        final = final.mul(zlm.Mat4.createTranslationXYZ(-sprite.ox, -sprite.oy, 0.0));
        final = final.mul(zlm.Mat4.createAngleAxis(.{ .x = 0.0, .y = 0.0, .z = 1.0 }, sprite.r));
        final = final.mul(zlm.Mat4.createTranslationXYZ(sprite.x + sprite.ox, sprite.y + sprite.oy, 0.0));
        final = final.mul(self.projection);

        // vector = vector x mvp
        var vectors: [4]zlm.Vec4 = undefined;
        vectors[0] = zlm.vec4(0.0, 0.0, 0.0, 1.0).transform(final);
        vectors[1] = zlm.vec4(1.0, 0.0, 0.0, 1.0).transform(final);
        vectors[2] = zlm.vec4(0.0, 1.0, 0.0, 1.0).transform(final);
        vectors[3] = zlm.vec4(1.0, 1.0, 0.0, 1.0).transform(final);

        self.data.append(vectors[0].x) catch unreachable;
        self.data.append(vectors[0].y) catch unreachable;
        self.data.append(sprite.texcoords[0]) catch unreachable;
        self.data.append(sprite.texcoords[1]) catch unreachable;

        self.data.append(vectors[1].x) catch unreachable;
        self.data.append(vectors[1].y) catch unreachable;
        self.data.append(sprite.texcoords[2]) catch unreachable;
        self.data.append(sprite.texcoords[1]) catch unreachable;

        self.data.append(vectors[2].x) catch unreachable;
        self.data.append(vectors[2].y) catch unreachable;
        self.data.append(sprite.texcoords[0]) catch unreachable;
        self.data.append(sprite.texcoords[3]) catch unreachable;

        self.data.append(vectors[3].x) catch unreachable;
        self.data.append(vectors[3].y) catch unreachable;
        self.data.append(sprite.texcoords[2]) catch unreachable;
        self.data.append(sprite.texcoords[3]) catch unreachable;

        self.data.append(vectors[1].x) catch unreachable;
        self.data.append(vectors[1].y) catch unreachable;
        self.data.append(sprite.texcoords[2]) catch unreachable;
        self.data.append(sprite.texcoords[1]) catch unreachable;

        self.data.append(vectors[2].x) catch unreachable;
        self.data.append(vectors[2].y) catch unreachable;
        self.data.append(sprite.texcoords[0]) catch unreachable;
        self.data.append(sprite.texcoords[3]) catch unreachable;
    }

    pub fn stop(self: *Renderer) void {
        self.flush();
    }
};
