attribute vec4 pos;
varying highp vec2 texcoords;

void main() {
    gl_Position = vec4(pos.x, pos.y, 0.0, 1.0);
    texcoords = vec2(pos.z, pos.w);
}