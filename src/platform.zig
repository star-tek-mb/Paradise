const std = @import("std");
const sysjs = @import("sysjs");
const root = @import("root");
const Self = @This();


pub fn log(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    const level_txt = comptime level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    var log_string = std.fmt.allocPrint(std.heap.page_allocator, level_txt ++ prefix2 ++ format ++ "\n", args) catch unreachable;

    var js_string = sysjs.createString(log_string);
    defer js_string.deinit();

    _ = sysjs.global().get("console").view(.object).call("log", &.{js_string.toValue()});
}

pub const UpdateFn = *const fn (f32) void;
var start: f64 = 0.0;
var update_fn: UpdateFn = undefined;

fn update_js_func(_: sysjs.Object, _: u32, _: []sysjs.Value) sysjs.Value {
    var current = sysjs.global().get("Date").view(.object).call("now", &.{}).view(.num);

    update_fn(@floatCast(f32, (current - start) / 1000.0));

    var update_js = sysjs.global().get("update");
    _ = sysjs.global().get("window").view(.object).call("requestAnimationFrame", &.{update_js});

    start = sysjs.global().get("Date").view(.object).call("now", &.{}).view(.num);

    return sysjs.createUndefined();
}

fn key_down_js_func(args: sysjs.Object, _: u32, _: []sysjs.Value) sysjs.Value {
    var keyCode = args.getIndex(0).view(.object).get("keyCode").view(.num);
    var keyEventFnPoitner = @floatToInt(usize, sysjs.global().get("keydown_function").view(.num));
    if (keyEventFnPoitner != 0) {
        var keyEventFn = @intToPtr(KeyEventFn, keyEventFnPoitner);
        keyEventFn(@floatToInt(u16, keyCode));
    }
    return sysjs.createUndefined();
}

fn key_up_js_func(args: sysjs.Object, _: u32, _: []sysjs.Value) sysjs.Value {
    var keyCode = args.getIndex(0).view(.object).get("keyCode").view(.num);
    var keyEventFnPoitner = @floatToInt(usize, sysjs.global().get("keyup_function").view(.num));
    if (keyEventFnPoitner != 0) {
        var keyEventFn = @intToPtr(KeyEventFn, keyEventFnPoitner);
        keyEventFn(@floatToInt(u16, keyCode));
    }
    return sysjs.createUndefined();
}

pub fn init() void {
    gl.init();

    var key_down_func_js = sysjs.createFunction(key_down_js_func, &.{});
    var key_down_string = sysjs.createString("keydown");
    defer key_down_string.deinit();
    _ = sysjs.global().set("keydown_function", sysjs.createNumber(0.0));
    _ = sysjs.global().get("window").view(.object).call("addEventListener", &.{ key_down_string.toValue(), key_down_func_js.toValue() });

    var key_up_func_js = sysjs.createFunction(key_up_js_func, &.{});
    var key_up_string = sysjs.createString("keyup");
    defer key_up_string.deinit();
    _ = sysjs.global().set("keyup_function", sysjs.createNumber(0.0));
    _ = sysjs.global().get("window").view(.object).call("addEventListener", &.{ key_up_string.toValue(), key_up_func_js.toValue() });
}

pub const KeyEventFn = *const fn (keycode: u16) void;
pub fn onKeyDown(func: KeyEventFn) void {
    var func_pointer = sysjs.createNumber(@intToFloat(f64, @ptrToInt(func)));
    _ = sysjs.global().set("keydown_function", func_pointer);
}

pub fn onKeyUp(func: KeyEventFn) void {
    var func_pointer = sysjs.createNumber(@intToFloat(f64, @ptrToInt(func)));
    _ = sysjs.global().set("keyup_function", func_pointer);
}

pub fn run(updateFn: UpdateFn) void {
    update_fn = updateFn;

    start = sysjs.global().get("Date").view(.object).call("now", &.{}).view(.num);

    var update_js = sysjs.createFunction(update_js_func, &.{});
    defer update_js.deinit();
    _ = sysjs.global().set("update", update_js.toValue());
    _ = sysjs.global().get("window").view(.object).call("requestAnimationFrame", &.{update_js.toValue()});
}

pub const gl = struct {
    var ctx: sysjs.Object = undefined;

    pub const FALSE: c_uint = 0;
    pub const TRUE: c_uint = 1;
    pub const DEPTH_BUFFER_BIT: c_uint = 256;
    pub const STENCIL_BUFFER_BIT: c_uint = 1024;
    pub const COLOR_BUFFER_BIT: c_uint = 16384;
    pub const POINTS: c_uint = 0;
    pub const LINES: c_uint = 1;
    pub const LINE_LOOP: c_uint = 2;
    pub const LINE_STRIP: c_uint = 3;
    pub const TRIANGLES: c_uint = 4;
    pub const TRIANGLE_STRIP: c_uint = 5;
    pub const TRIANGLE_FAN: c_uint = 6;
    pub const ZERO: c_uint = 0;
    pub const ONE: c_uint = 1;
    pub const SRC_COLOR: c_uint = 768;
    pub const ONE_MINUS_SRC_COLOR: c_uint = 769;
    pub const SRC_ALPHA: c_uint = 770;
    pub const ONE_MINUS_SRC_ALPHA: c_uint = 771;
    pub const DST_ALPHA: c_uint = 772;
    pub const ONE_MINUS_DST_ALPHA: c_uint = 773;
    pub const DST_COLOR: c_uint = 774;
    pub const ONE_MINUS_DST_COLOR: c_uint = 775;
    pub const SRC_ALPHA_SATURATE: c_uint = 776;
    pub const FUNC_ADD: c_uint = 32774;
    pub const BLEND_EQUATION: c_uint = 32777;
    pub const BLEND_EQUATION_RGB: c_uint = 32777;
    pub const BLEND_EQUATION_ALPHA: c_uint = 34877;
    pub const FUNC_SUBTRACT: c_uint = 32778;
    pub const FUNC_REVERSE_SUBTRACT: c_uint = 32779;
    pub const BLEND_DST_RGB: c_uint = 32968;
    pub const BLEND_SRC_RGB: c_uint = 32969;
    pub const BLEND_DST_ALPHA: c_uint = 32970;
    pub const BLEND_SRC_ALPHA: c_uint = 32971;
    pub const CONSTANT_COLOR: c_uint = 32769;
    pub const ONE_MINUS_CONSTANT_COLOR: c_uint = 32770;
    pub const CONSTANT_ALPHA: c_uint = 32771;
    pub const ONE_MINUS_CONSTANT_ALPHA: c_uint = 32772;
    pub const BLEND_COLOR: c_uint = 32773;
    pub const ARRAY_BUFFER: c_uint = 34962;
    pub const ELEMENT_ARRAY_BUFFER: c_uint = 34963;
    pub const ARRAY_BUFFER_BINDING: c_uint = 34964;
    pub const ELEMENT_ARRAY_BUFFER_BINDING: c_uint = 34965;
    pub const STREAM_DRAW: c_uint = 35040;
    pub const STATIC_DRAW: c_uint = 35044;
    pub const DYNAMIC_DRAW: c_uint = 35048;
    pub const BUFFER_SIZE: c_uint = 34660;
    pub const BUFFER_USAGE: c_uint = 34661;
    pub const CURRENT_VERTEX_ATTRIB: c_uint = 34342;
    pub const FRONT: c_uint = 1028;
    pub const BACK: c_uint = 1029;
    pub const FRONT_AND_BACK: c_uint = 1032;
    pub const TEXTURE_2D: c_uint = 3553;
    pub const CULL_FACE: c_uint = 2884;
    pub const BLEND: c_uint = 3042;
    pub const DITHER: c_uint = 3024;
    pub const STENCIL_TEST: c_uint = 2960;
    pub const DEPTH_TEST: c_uint = 2929;
    pub const SCISSOR_TEST: c_uint = 3089;
    pub const POLYGON_OFFSET_FILL: c_uint = 32823;
    pub const SAMPLE_ALPHA_TO_COVERAGE: c_uint = 32926;
    pub const SAMPLE_COVERAGE: c_uint = 32928;
    pub const NO_ERROR: c_uint = 0;
    pub const INVALID_ENUM: c_uint = 1280;
    pub const INVALID_VALUE: c_uint = 1281;
    pub const INVALID_OPERATION: c_uint = 1282;
    pub const OUT_OF_MEMORY: c_uint = 1285;
    pub const CW: c_uint = 2304;
    pub const CCW: c_uint = 2305;
    pub const LINE_WIDTH: c_uint = 2849;
    pub const ALIASED_POINT_SIZE_RANGE: c_uint = 33901;
    pub const ALIASED_LINE_WIDTH_RANGE: c_uint = 33902;
    pub const CULL_FACE_MODE: c_uint = 2885;
    pub const FRONT_FACE: c_uint = 2886;
    pub const DEPTH_RANGE: c_uint = 2928;
    pub const DEPTH_WRITEMASK: c_uint = 2930;
    pub const DEPTH_CLEAR_VALUE: c_uint = 2931;
    pub const DEPTH_FUNC: c_uint = 2932;
    pub const STENCIL_CLEAR_VALUE: c_uint = 2961;
    pub const STENCIL_FUNC: c_uint = 2962;
    pub const STENCIL_FAIL: c_uint = 2964;
    pub const STENCIL_PASS_DEPTH_FAIL: c_uint = 2965;
    pub const STENCIL_PASS_DEPTH_PASS: c_uint = 2966;
    pub const STENCIL_REF: c_uint = 2967;
    pub const STENCIL_VALUE_MASK: c_uint = 2963;
    pub const STENCIL_WRITEMASK: c_uint = 2968;
    pub const STENCIL_BACK_FUNC: c_uint = 34816;
    pub const STENCIL_BACK_FAIL: c_uint = 34817;
    pub const STENCIL_BACK_PASS_DEPTH_FAIL: c_uint = 34818;
    pub const STENCIL_BACK_PASS_DEPTH_PASS: c_uint = 34819;
    pub const STENCIL_BACK_REF: c_uint = 36003;
    pub const STENCIL_BACK_VALUE_MASK: c_uint = 36004;
    pub const STENCIL_BACK_WRITEMASK: c_uint = 36005;
    pub const VIEWPORT: c_uint = 2978;
    pub const SCISSOR_BOX: c_uint = 3088;
    pub const COLOR_CLEAR_VALUE: c_uint = 3106;
    pub const COLOR_WRITEMASK: c_uint = 3107;
    pub const UNPACK_ALIGNMENT: c_uint = 3317;
    pub const PACK_ALIGNMENT: c_uint = 3333;
    pub const MAX_TEXTURE_SIZE: c_uint = 3379;
    pub const MAX_VIEWPORT_DIMS: c_uint = 3386;
    pub const SUBPIXEL_BITS: c_uint = 3408;
    pub const RED_BITS: c_uint = 3410;
    pub const GREEN_BITS: c_uint = 3411;
    pub const BLUE_BITS: c_uint = 3412;
    pub const ALPHA_BITS: c_uint = 3413;
    pub const DEPTH_BITS: c_uint = 3414;
    pub const STENCIL_BITS: c_uint = 3415;
    pub const POLYGON_OFFSET_UNITS: c_uint = 10752;
    pub const POLYGON_OFFSET_FACTOR: c_uint = 32824;
    pub const TEXTURE_BINDING_2D: c_uint = 32873;
    pub const SAMPLE_BUFFERS: c_uint = 32936;
    pub const SAMPLES: c_uint = 32937;
    pub const SAMPLE_COVERAGE_VALUE: c_uint = 32938;
    pub const SAMPLE_COVERAGE_INVERT: c_uint = 32939;
    pub const COMPRESSED_TEXTURE_FORMATS: c_uint = 34467;
    pub const DONT_CARE: c_uint = 4352;
    pub const FASTEST: c_uint = 4353;
    pub const NICEST: c_uint = 4354;
    pub const GENERATE_MIPMAP_HINT: c_uint = 33170;
    pub const BYTE: c_uint = 5120;
    pub const UNSIGNED_BYTE: c_uint = 5121;
    pub const SHORT: c_uint = 5122;
    pub const UNSIGNED_SHORT: c_uint = 5123;
    pub const INT: c_uint = 5124;
    pub const UNSIGNED_INT: c_uint = 5125;
    pub const FLOAT: c_uint = 5126;
    pub const DEPTH_COMPONENT: c_uint = 6402;
    pub const ALPHA: c_uint = 6406;
    pub const RGB: c_uint = 6407;
    pub const RGBA: c_uint = 6408;
    pub const LUMINANCE: c_uint = 6409;
    pub const LUMINANCE_ALPHA: c_uint = 6410;
    pub const UNSIGNED_SHORT_4_4_4_4: c_uint = 32819;
    pub const UNSIGNED_SHORT_5_5_5_1: c_uint = 32820;
    pub const UNSIGNED_SHORT_5_6_5: c_uint = 33635;
    pub const FRAGMENT_SHADER: c_uint = 35632;
    pub const VERTEX_SHADER: c_uint = 35633;
    pub const MAX_VERTEX_ATTRIBS: c_uint = 34921;
    pub const MAX_VERTEX_UNIFORM_VECTORS: c_uint = 36347;
    pub const MAX_VARYING_VECTORS: c_uint = 36348;
    pub const MAX_COMBINED_TEXTURE_IMAGE_UNITS: c_uint = 35661;
    pub const MAX_VERTEX_TEXTURE_IMAGE_UNITS: c_uint = 35660;
    pub const MAX_TEXTURE_IMAGE_UNITS: c_uint = 34930;
    pub const MAX_FRAGMENT_UNIFORM_VECTORS: c_uint = 36349;
    pub const SHADER_TYPE: c_uint = 35663;
    pub const DELETE_STATUS: c_uint = 35712;
    pub const LINK_STATUS: c_uint = 35714;
    pub const VALIDATE_STATUS: c_uint = 35715;
    pub const ATTACHED_SHADERS: c_uint = 35717;
    pub const ACTIVE_UNIFORMS: c_uint = 35718;
    pub const ACTIVE_ATTRIBUTES: c_uint = 35721;
    pub const SHADING_LANGUAGE_VERSION: c_uint = 35724;
    pub const CURRENT_PROGRAM: c_uint = 35725;
    pub const NEVER: c_uint = 512;
    pub const LESS: c_uint = 513;
    pub const EQUAL: c_uint = 514;
    pub const LEQUAL: c_uint = 515;
    pub const GREATER: c_uint = 516;
    pub const NOTEQUAL: c_uint = 517;
    pub const GEQUAL: c_uint = 518;
    pub const ALWAYS: c_uint = 519;
    pub const KEEP: c_uint = 7680;
    pub const REPLACE: c_uint = 7681;
    pub const INCR: c_uint = 7682;
    pub const DECR: c_uint = 7683;
    pub const INVERT: c_uint = 5386;
    pub const INCR_WRAP: c_uint = 34055;
    pub const DECR_WRAP: c_uint = 34056;
    pub const VENDOR: c_uint = 7936;
    pub const RENDERER: c_uint = 7937;
    pub const VERSION: c_uint = 7938;
    pub const NEAREST: c_uint = 9728;
    pub const LINEAR: c_uint = 9729;
    pub const NEAREST_MIPMAP_NEAREST: c_uint = 9984;
    pub const LINEAR_MIPMAP_NEAREST: c_uint = 9985;
    pub const NEAREST_MIPMAP_LINEAR: c_uint = 9986;
    pub const LINEAR_MIPMAP_LINEAR: c_uint = 9987;
    pub const TEXTURE_MAG_FILTER: c_uint = 10240;
    pub const TEXTURE_MIN_FILTER: c_uint = 10241;
    pub const TEXTURE_WRAP_S: c_uint = 10242;
    pub const TEXTURE_WRAP_T: c_uint = 10243;
    pub const TEXTURE: c_uint = 5890;
    pub const TEXTURE_CUBE_MAP: c_uint = 34067;
    pub const TEXTURE_BINDING_CUBE_MAP: c_uint = 34068;
    pub const TEXTURE_CUBE_MAP_POSITIVE_X: c_uint = 34069;
    pub const TEXTURE_CUBE_MAP_NEGATIVE_X: c_uint = 34070;
    pub const TEXTURE_CUBE_MAP_POSITIVE_Y: c_uint = 34071;
    pub const TEXTURE_CUBE_MAP_NEGATIVE_Y: c_uint = 34072;
    pub const TEXTURE_CUBE_MAP_POSITIVE_Z: c_uint = 34073;
    pub const TEXTURE_CUBE_MAP_NEGATIVE_Z: c_uint = 34074;
    pub const MAX_CUBE_MAP_TEXTURE_SIZE: c_uint = 34076;
    pub const TEXTURE0: c_uint = 33984;
    pub const ACTIVE_TEXTURE: c_uint = 34016;
    pub const REPEAT: c_uint = 10497;
    pub const CLAMP_TO_EDGE: c_uint = 33071;
    pub const MIRRORED_REPEAT: c_uint = 33648;
    pub const FLOAT_VEC2: c_uint = 35664;
    pub const FLOAT_VEC3: c_uint = 35665;
    pub const FLOAT_VEC4: c_uint = 35666;
    pub const INT_VEC2: c_uint = 35667;
    pub const INT_VEC3: c_uint = 35668;
    pub const INT_VEC4: c_uint = 35669;
    pub const BOOL: c_uint = 35670;
    pub const BOOL_VEC2: c_uint = 35671;
    pub const BOOL_VEC3: c_uint = 35672;
    pub const BOOL_VEC4: c_uint = 35673;
    pub const FLOAT_MAT2: c_uint = 35674;
    pub const FLOAT_MAT3: c_uint = 35675;
    pub const FLOAT_MAT4: c_uint = 35676;
    pub const SAMPLER_2D: c_uint = 35678;
    pub const SAMPLER_CUBE: c_uint = 35680;
    pub const VERTEX_ATTRIB_ARRAY_ENABLED: c_uint = 34338;
    pub const VERTEX_ATTRIB_ARRAY_SIZE: c_uint = 34339;
    pub const VERTEX_ATTRIB_ARRAY_STRIDE: c_uint = 34340;
    pub const VERTEX_ATTRIB_ARRAY_TYPE: c_uint = 34341;
    pub const VERTEX_ATTRIB_ARRAY_NORMALIZED: c_uint = 34922;
    pub const VERTEX_ATTRIB_ARRAY_POINTER: c_uint = 34373;
    pub const VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: c_uint = 34975;
    pub const IMPLEMENTATION_COLOR_READ_TYPE: c_uint = 35738;
    pub const IMPLEMENTATION_COLOR_READ_FORMAT: c_uint = 35739;
    pub const COMPILE_STATUS: c_uint = 35713;
    pub const LOW_FLOAT: c_uint = 36336;
    pub const MEDIUM_FLOAT: c_uint = 36337;
    pub const HIGH_FLOAT: c_uint = 36338;
    pub const LOW_INT: c_uint = 36339;
    pub const MEDIUM_INT: c_uint = 36340;
    pub const HIGH_INT: c_uint = 36341;
    pub const FRAMEBUFFER: c_uint = 36160;
    pub const RENDERBUFFER: c_uint = 36161;
    pub const RGBA4: c_uint = 32854;
    pub const RGB5_A1: c_uint = 32855;
    pub const RGB565: c_uint = 36194;
    pub const DEPTH_COMPONENT16: c_uint = 33189;
    pub const STENCIL_INDEX8: c_uint = 36168;
    pub const DEPTH_STENCIL: c_uint = 34041;
    pub const RENDERBUFFER_WIDTH: c_uint = 36162;
    pub const RENDERBUFFER_HEIGHT: c_uint = 36163;
    pub const RENDERBUFFER_INTERNAL_FORMAT: c_uint = 36164;
    pub const RENDERBUFFER_RED_SIZE: c_uint = 36176;
    pub const RENDERBUFFER_GREEN_SIZE: c_uint = 36177;
    pub const RENDERBUFFER_BLUE_SIZE: c_uint = 36178;
    pub const RENDERBUFFER_ALPHA_SIZE: c_uint = 36179;
    pub const RENDERBUFFER_DEPTH_SIZE: c_uint = 36180;
    pub const RENDERBUFFER_STENCIL_SIZE: c_uint = 36181;
    pub const FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE: c_uint = 36048;
    pub const FRAMEBUFFER_ATTACHMENT_OBJECT_NAME: c_uint = 36049;
    pub const FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL: c_uint = 36050;
    pub const FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE: c_uint = 36051;
    pub const COLOR_ATTACHMENT0: c_uint = 36064;
    pub const DEPTH_ATTACHMENT: c_uint = 36096;
    pub const STENCIL_ATTACHMENT: c_uint = 36128;
    pub const DEPTH_STENCIL_ATTACHMENT: c_uint = 33306;
    pub const NONE: c_uint = 0;
    pub const FRAMEBUFFER_COMPLETE: c_uint = 36053;
    pub const FRAMEBUFFER_INCOMPLETE_ATTACHMENT: c_uint = 36054;
    pub const FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: c_uint = 36055;
    pub const FRAMEBUFFER_INCOMPLETE_DIMENSIONS: c_uint = 36057;
    pub const FRAMEBUFFER_UNSUPPORTED: c_uint = 36061;
    pub const FRAMEBUFFER_BINDING: c_uint = 36006;
    pub const RENDERBUFFER_BINDING: c_uint = 36007;
    pub const MAX_RENDERBUFFER_SIZE: c_uint = 34024;
    pub const INVALID_FRAMEBUFFER_OPERATION: c_uint = 1286;
    pub const UNPACK_FLIP_Y_WEBGL: c_uint = 37440;
    pub const UNPACK_PREMULTIPLY_ALPHA_WEBGL: c_uint = 37441;
    pub const CONTEXT_LOST_WEBGL: c_uint = 37442;
    pub const UNPACK_COLORSPACE_CONVERSION_WEBGL: c_uint = 37443;
    pub const BROWSER_DEFAULT_WEBGL: c_uint = 37444;

    pub fn init() void {
        var canvasString = sysjs.createString("canvas");
        defer canvasString.deinit();
        var canvas = sysjs.global().get("document").view(.object).call("getElementById", &.{canvasString.toValue()}).view(.object);
        defer canvas.deinit();

        var webglString = sysjs.createString("webgl");
        defer webglString.deinit();
        gl.ctx = canvas.call("getContext", &.{webglString.toValue()}).view(.object);
        _ = sysjs.global().set("gl", gl.ctx.toValue());
    }

    pub fn deinit() void {
        gl.ctx.deinit();
    }

    pub fn clear(mask: c_uint) void {
        _ = gl.ctx.call("clear", &.{sysjs.createNumber(@intToFloat(f64, mask))});
    }
    pub fn clearColor(r: f32, g: f32, b: f32, a: f32) void {
        _ = gl.ctx.call("clearColor", &.{ sysjs.createNumber(r), sysjs.createNumber(g), sysjs.createNumber(b), sysjs.createNumber(a) });
    }
    pub fn activeTexture(unit: c_uint) void {
        _ = gl.ctx.call("activeTexture", &.{sysjs.createNumber(@intToFloat(f64, unit))});
    }
    pub fn attachShader(program_id: c_uint, shader_id: c_uint) void {
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        var shader = sysjs.Value{ .tag = .object, .val = .{ .ref = shader_id } };
        _ = gl.ctx.call("attachShader", &.{ program, shader });
    }
    // pub extern fn bindAttribLocation(3) void;
    // pub extern fn bindRenderbuffer(2) void;
    // pub extern fn blendColor(4) void;
    // pub extern fn blendEquation(1) void;
    // pub extern fn blendEquationSeparate(2) void;
    // pub extern fn blendFunc(2) void;
    pub fn blendFunc(sfactor: c_uint, dfactor: c_uint) void {
        _ = gl.ctx.call("blendFunc", &.{ sysjs.createNumber(@intToFloat(f64, sfactor)), sysjs.createNumber(@intToFloat(f64, dfactor)) });
    }
    // pub extern fn blendFuncSeparate(4) void;
    pub fn bufferData(target: c_uint, size: c_int, data: ?*const anyopaque, usage: c_uint) void {
        var memory = sysjs.global().get("memory").view(.object).get("buffer");
        var buffer: sysjs.Object = undefined;
        if (target == gl.ARRAY_BUFFER) {
            buffer = sysjs.constructType("Float32Array", &.{ memory, sysjs.createNumber(@intToFloat(f64, @ptrToInt(data))), sysjs.createNumber(@intToFloat(f64, @divTrunc(size, 4))) });
        } else if (target == gl.ELEMENT_ARRAY_BUFFER) {
            buffer = sysjs.constructType("Uint32Array", &.{ memory, sysjs.createNumber(@intToFloat(f64, @ptrToInt(data))), sysjs.createNumber(@intToFloat(f64, @divTrunc(size, 4))) });
        } else {
            unreachable;
        }
        defer buffer.deinit();
        _ = gl.ctx.call("bufferData", &.{ sysjs.createNumber(@intToFloat(f64, target)), buffer.toValue(), sysjs.createNumber(@intToFloat(f64, usage)) });
    }
    // pub extern fn bufferSubData(3) void;
    // pub extern fn checkFramebufferStatus(1) void;
    pub fn compileShader(shader_id: c_uint) void {
        var shader = sysjs.Value{ .tag = .object, .val = .{ .ref = shader_id } };
        _ = gl.ctx.call("compileShader", &.{shader});
    }
    // pub extern fn compressedTexImage2D(7) void;
    // pub extern fn compressedTexSubImage2D(8) void;
    // pub extern fn copyTexImage2D(8) void;
    // pub extern fn copyTexSubImage2D(8) void;
    pub fn createBuffer() c_uint {
        var buffer = gl.ctx.call("createBuffer", &.{});
        return @intCast(c_uint, buffer.val.ref);
    }
    // pub extern fn createFramebuffer(0) void;
    pub fn createProgram() c_uint {
        var program = gl.ctx.call("createProgram", &.{});
        return @intCast(c_uint, program.val.ref);
    }
    // pub extern fn createRenderbuffer(0) void;
    pub fn createShader(shader_type: c_uint) c_uint {
        var shader = gl.ctx.call("createShader", &.{sysjs.createNumber(@intToFloat(f64, shader_type))});
        return @intCast(c_uint, shader.val.ref);
    }
    pub fn createTexture() c_uint {
        var texture = gl.ctx.call("createTexture", &.{});
        return @intCast(c_uint, texture.val.ref);
    }
    // pub extern fn cullFace(1) void;
    pub fn deleteBuffer(buffer_id: c_uint) void {
        var buffer = sysjs.Value{ .tag = .object, .val = .{ .ref = buffer_id } };
        defer buffer.view(.object).deinit();
        _ = gl.ctx.call("deleteBuffer", &.{buffer});
    }
    // pub extern fn deleteFramebuffer(1) void;
    pub fn deleteProgram(program_id: c_uint) void {
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        defer program.view(.object).deinit();
        _ = gl.ctx.call("deleteProgram", &.{program});
    }
    // pub extern fn deleteRenderbuffer(1) void;
    pub fn deleteShader(shader_id: c_uint) void {
        var shader = sysjs.Value{ .tag = .object, .val = .{ .ref = shader_id } };
        defer shader.view(.object).deinit();
        _ = gl.ctx.call("deleteShader", &.{shader});
    }
    pub fn deleteTexture(texture_id: c_uint) void {
        var texture = sysjs.Value{ .tag = .object, .val = .{ .ref = texture_id } };
        defer texture.view(.object).deinit();
        _ = gl.ctx.call("deleteTexture", &.{texture});
    }
    // pub extern fn depthFunc(1) void;
    // pub extern fn depthMask(1) void;
    // pub extern fn depthRange(2) void;
    // pub extern fn detachShader(2) void;
    pub fn disable(capability: c_uint) void {
        _ = gl.ctx.call("disable", &.{sysjs.createNumber(@intToFloat(f64, capability))});
    }
    pub fn enable(capability: c_uint) void {
        _ = gl.ctx.call("enable", &.{sysjs.createNumber(@intToFloat(f64, capability))});
    }
    // pub extern fn finish(0) void;
    // pub extern fn flush(0) void;
    // pub extern fn framebufferRenderbuffer(4) void;
    // pub extern fn framebufferTexture2D(5) void;
    // pub extern fn frontFace(1) void;
    // pub extern fn generateMipmap(1) void;
    // pub extern fn getActiveAttrib(2) void;
    // pub extern fn getActiveUniform(2) void;
    // pub extern fn getAttachedShaders(1) void;
    // pub extern fn getAttribLocation(2) void;
    // pub extern fn getBufferParameter(2) void;
    // pub extern fn getContextAttributes(0) void;
    // pub extern fn getError(0) void;
    // pub extern fn getExtension(1) void;
    // pub extern fn getFramebufferAttachmentParameter(3) void;
    // pub extern fn getParameter(1) void;
    // pub extern fn getProgramInfoLog(1) void;
    pub fn getProgramParameter(program_id: c_uint, pname: c_int) c_int {
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        var result = gl.ctx.call("getProgramParameter", &.{ program, sysjs.createNumber(@intToFloat(f64, pname)) });
        if (result.tag == .bool) {
            return @boolToInt(result.view(.bool));
        } else {
            return @floatToInt(c_int, result.view(.num));
        }
    }
    // pub extern fn getRenderbufferParameter(2) void;
    // pub extern fn getShaderInfoLog(1) void;
    pub fn getShaderParameter(shader_id: c_uint, pname: c_int) c_int {
        var shader = sysjs.Value{ .tag = .object, .val = .{ .ref = shader_id } };
        var result = gl.ctx.call("getShaderParameter", &.{ shader, sysjs.createNumber(@intToFloat(f64, pname)) });
        if (result.tag == .bool) {
            return @boolToInt(result.view(.bool));
        } else {
            return @floatToInt(c_int, result.view(.num));
        }
    }
    // pub extern fn getShaderPrecisionFormat(2) void;
    // pub extern fn getShaderSource(1) void;
    // pub extern fn getSupportedExtensions(0) void;
    // pub extern fn getTexParameter(2) void;
    // pub extern fn getUniform(2) void;
    pub fn getUniformLocation(program_id: c_uint, name: []const u8) c_int {
        var name_js = sysjs.createString(name);
        defer name_js.deinit();
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        var result = gl.ctx.call("getUniformLocation", &.{ program, name_js.toValue() });
        return @intCast(c_int, result.val.ref);
    }
    // pub extern fn getVertexAttrib(2) void;
    // pub extern fn getVertexAttribOffset(2) void;
    // pub extern fn hint(2) void;
    // pub extern fn isBuffer(1) void;
    // pub extern fn isContextLost(0) void;
    // pub extern fn isEnabled(1) void;
    // pub extern fn isFramebuffer(1) void;
    // pub extern fn isProgram(1) void;
    // pub extern fn isRenderbuffer(1) void;
    // pub extern fn isShader(1) void;
    // pub extern fn isTexture(1) void;
    // pub extern fn lineWidth(1) void;
    pub fn linkProgram(program_id: c_uint) void {
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        _ = gl.ctx.call("linkProgram", &.{program});
    }
    // pub extern fn pixelStorei(2) void;
    // pub extern fn polygonOffset(2) void;
    // pub extern fn readPixels(7) void;
    // pub extern fn renderbufferStorage(4) void;
    // pub extern fn sampleCoverage(2) void;
    pub fn shaderSource(shader_id: c_uint, _: c_int, source: [*]const u8, len: c_uint) void {
        var source_js = sysjs.createString(source[0..len]);
        defer source_js.deinit();
        var shader = sysjs.Value{ .tag = .object, .val = .{ .ref = shader_id } };
        _ = gl.ctx.call("shaderSource", &.{ shader, source_js.toValue() });
    }
    // pub extern fn stencilFunc(3) void;
    // pub extern fn stencilFuncSeparate(4) void;
    // pub extern fn stencilMask(1) void;
    // pub extern fn stencilMaskSeparate(2) void;
    // pub extern fn stencilOp(3) void;
    // pub extern fn stencilOpSeparate(4) void;
    pub fn texImage2D(target: c_uint, level: c_int, internalFormat: c_int, width: c_int, height: c_int, border: c_int, format: c_uint, data_type: c_uint, data: [*]const u8) void {
        var memory = sysjs.global().get("memory").view(.object).get("buffer");
        var buffer = sysjs.constructType("Uint8Array", &.{ memory, sysjs.createNumber(@intToFloat(f64, @ptrToInt(data))) });
        defer buffer.deinit();
        _ = gl.ctx.call("texImage2D", &.{ sysjs.createNumber(@intToFloat(f64, target)), sysjs.createNumber(@intToFloat(f64, level)), sysjs.createNumber(@intToFloat(f64, internalFormat)), sysjs.createNumber(@intToFloat(f64, width)), sysjs.createNumber(@intToFloat(f64, height)), sysjs.createNumber(@intToFloat(f64, border)), sysjs.createNumber(@intToFloat(f64, format)), sysjs.createNumber(@intToFloat(f64, data_type)), buffer.toValue() });
    }
    // pub extern fn texParameterf(3) void;
    pub fn texParameteri(target: c_uint, pname: c_uint, value: c_int) void {
        _ = gl.ctx.call("texParameteri", &.{ sysjs.createNumber(@intToFloat(f64, target)), sysjs.createNumber(@intToFloat(f64, pname)), sysjs.createNumber(@intToFloat(f64, value)) });
    }
    // pub extern fn texSubImage2D(7) void;
    pub fn useProgram(program_id: c_uint) void {
        var program = sysjs.Value{ .tag = .object, .val = .{ .ref = program_id } };
        _ = gl.ctx.call("useProgram", &.{program});
    }
    // pub extern fn validateProgram(1) void;
    pub fn bindBuffer(target: c_uint, buffer_id: c_uint) void {
        var buffer = sysjs.Value{ .tag = .object, .val = .{ .ref = buffer_id } };
        _ = gl.ctx.call("bindBuffer", &.{ sysjs.createNumber(@intToFloat(f64, target)), buffer });
    }
    // pub extern fn bindFramebuffer(2) void;
    pub fn bindTexture(target: c_uint, texture_id: c_uint) void {
        var texture = sysjs.Value{ .tag = .object, .val = .{ .ref = texture_id } };
        _ = gl.ctx.call("bindTexture", &.{ sysjs.createNumber(@intToFloat(f64, target)), texture });
    }
    // pub extern fn clearDepth(1) void;
    // pub extern fn clearStencil(1) void;
    // pub extern fn colorMask(4) void;
    pub fn disableVertexAttribArray(attrib: c_uint) void {
        _ = gl.ctx.call("disableVertexAttribArray", &.{sysjs.createNumber(@intToFloat(f64, attrib))});
    }
    pub fn drawArrays(mode: c_uint, first: c_int, count: c_int) void {
        _ = gl.ctx.call("drawArrays", &.{ sysjs.createNumber(@intToFloat(f64, mode)), sysjs.createNumber(@intToFloat(f64, first)), sysjs.createNumber(@intToFloat(f64, count)) });
    }
    // pub extern fn drawElements(4) void;
    pub fn enableVertexAttribArray(attrib: c_uint) void {
        _ = gl.ctx.call("enableVertexAttribArray", &.{sysjs.createNumber(@intToFloat(f64, attrib))});
    }
    // pub extern fn scissor(4) void;
    pub fn uniform1f(location: c_int, value: f32) void {
        var location_js = sysjs.Value{ .tag = .object, .val = .{ .ref = @intCast(u64, location) } };
        _ = gl.ctx.call("uniform1f", &.{ location_js, sysjs.createNumber(@floatCast(f64, value)) });
    }
    // pub extern fn uniform1fv(2) void;
    pub fn uniform1i(location: c_int, value: c_int) void {
        var location_js = sysjs.Value{ .tag = .object, .val = .{ .ref = @intCast(u64, location) } };
        _ = gl.ctx.call("uniform1i", &.{ location_js, sysjs.createNumber(@intToFloat(f64, value)) });
    }
    // pub extern fn uniform1iv(2) void;
    // pub extern fn uniform2f(3) void;
    // pub extern fn uniform2fv(2) void;
    // pub extern fn uniform2i(3) void;
    // pub extern fn uniform2iv(2) void;
    // pub extern fn uniform3f(4) void;
    // pub extern fn uniform3fv(2) void;
    // pub extern fn uniform3i(4) void;
    // pub extern fn uniform3iv(2) void;
    // pub extern fn uniform4f(5) void;
    // pub extern fn uniform4fv(2) void;
    // pub extern fn uniform4i(5) void;
    // pub extern fn uniform4iv(2) void;
    // pub extern fn uniformMatrix2fv(3) void;
    // pub extern fn uniformMatrix3fv(3) void;
    // pub extern fn uniformMatrix4fv(3) void;
    // pub extern fn vertexAttrib1f(2) void;
    // pub extern fn vertexAttrib1fv(2) void;
    // pub extern fn vertexAttrib2f(3) void;
    // pub extern fn vertexAttrib2fv(2) void;
    // pub extern fn vertexAttrib3f(4) void;
    // pub extern fn vertexAttrib3fv(2) void;
    // pub extern fn vertexAttrib4f(5) void;
    // pub extern fn vertexAttrib4fv(2) void;
    pub fn vertexAttribPointer(index: c_uint, size: c_int, pointer_type: c_uint, normalized: u8, stride: c_int, pointer: *allowzero const anyopaque) void {
        _ = gl.ctx.call("vertexAttribPointer", &.{
            sysjs.createNumber(@intToFloat(f64, index)),
            sysjs.createNumber(@intToFloat(f64, size)),
            sysjs.createNumber(@intToFloat(f64, pointer_type)),
            sysjs.createNumber(@intToFloat(f64, normalized)),
            sysjs.createNumber(@intToFloat(f64, stride)),
            sysjs.createNumber(@intToFloat(f64, @ptrToInt(pointer))),
        });
    }
    pub fn viewport(x: c_int, y: c_int, w: c_int, h: c_int) void {
        _ = gl.ctx.call("viewport", &.{ sysjs.createNumber(@intToFloat(f64, x)), sysjs.createNumber(@intToFloat(f64, y)), sysjs.createNumber(@intToFloat(f64, w)), sysjs.createNumber(@intToFloat(f64, h)) });
    }
};
