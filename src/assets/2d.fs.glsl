varying highp vec2 texcoords;
uniform sampler2D texsampler;

void main() {
    gl_FragColor = texture2D(texsampler, texcoords);
}