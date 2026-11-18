#version 300 es
precision highp float;

#define MAX_VORTICES 8

in vec2 vortexPhase;  // [0] orbit angle  [1] height fraction along the funnel 0 to 1
in vec2 vortexJitter; // [0] radius jitter 0 to 1   [1] speed jitter 0 to 1

// transform feedback varyings:
out vec2 phase_out;
out vec2 jitter_out;

uniform float numVortices;
uniform vec4 vortexData[MAX_VORTICES];   // x: posX  y: baseY  z: strength  w: coreRadius (all 0 to 1 sim units)
uniform vec4 vortexParams[MAX_VORTICES]; // x: topRadius  y: height  z: type (0 = tornado, 1 = dust devil)  w: seed
uniform float dt;                        // number of iterations simulated since the last update
uniform float iterNum;

float vortRand(float n) { return fract(sin(n) * 43758.5453123); }

void main()
{
  phase_out = vortexPhase;
  jitter_out = vortexJitter;

  gl_PointSize = 1.0;
  gl_Position = vec4(-10.0, -10.0, 0.0, 1.0); // park off screen (hidden)

  if (numVortices < 1.0 || dt <= 0.0)
    return;

  int slot = int(mod(float(gl_VertexID), numVortices)); // particles are divided over the active vortices
  if (slot >= MAX_VORTICES)
    return;

  float strength = vortexData[slot].z;
  float height = vortexParams[slot].y;

  if (strength <= 0.0 || height <= 0.0)
    return;

  float type = vortexParams[slot].z;

  float angle = vortexPhase.x;
  float hFrac = vortexPhase.y;

  // orbital angular speed: faster near the narrow base, like conservation of angular momentum
  float spinMult = type < 0.5 ? mix(2.4, 0.7, hFrac) : mix(1.7, 0.9, hFrac);
  angle += (0.14 + 0.16 * vortexJitter.y) * spinMult * dt;

  // particles slowly travel upward through the vortex, from the ground up to the wall cloud
  hFrac += (0.0032 + 0.0040 * vortexJitter.y) * dt;

  if (hFrac > 1.0) { // respawn at the base of the funnel with new random properties
    hFrac = fract(hFrac);
    float seed = float(gl_VertexID) * 0.618 + iterNum * 0.001;
    jitter_out = vec2(vortRand(seed + 1.7), vortRand(seed + 5.3));
    angle = vortRand(seed + 9.1) * 6.2831853;
  }

  phase_out = vec2(angle, hFrac);
}
