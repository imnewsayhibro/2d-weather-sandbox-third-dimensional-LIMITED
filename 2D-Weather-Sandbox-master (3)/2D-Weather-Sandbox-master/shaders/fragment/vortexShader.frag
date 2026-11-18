#version 300 es
precision highp float;

out vec4 fragmentColor;

void main() // the vortex particle update pass only uses transform feedback, nothing is rasterized
{
  fragmentColor = vec4(0.0);
}
