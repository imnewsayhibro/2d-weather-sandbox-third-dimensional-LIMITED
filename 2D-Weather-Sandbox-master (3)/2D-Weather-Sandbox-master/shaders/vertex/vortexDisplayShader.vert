#version 300 es
precision highp float;

#define MAX_VORTICES 8

layout(location = 0) in vec2 vortexPhase;  // [0] orbit angle  [1] height fraction along the funnel 0 to 1
layout(location = 1) in vec2 vortexJitter; // [0] radius jitter 0 to 1   [1] speed jitter 0 to 1

out vec2 phase_out;
out vec2 jitter_out;
out float depth_out;      // position on the orbit relative to the viewer, -1 to 1
out float type_out;       // 0 = tornado, 1 = dust devil
out float strength_out;
out float heightFrac_out;

uniform vec3 view;         // Xpos  Ypos    Zoom
uniform vec2 aspectRatios; // sim   canvas
uniform float numVortices;
uniform vec4 vortexData[MAX_VORTICES];   // x: posX  y: baseY  z: strength  w: coreRadius (all 0 to 1 sim units)
uniform vec4 vortexParams[MAX_VORTICES]; // x: topRadius  y: height  z: type  w: seed
uniform float vortexTilt[MAX_VORTICES];  // horizontal lean of the axis over the full height (tilted supercell)

void main()
{
  phase_out = vortexPhase;
  jitter_out = vortexJitter;
  depth_out = 0.0;
  type_out = 0.0;
  strength_out = 0.0;
  heightFrac_out = 0.0;

  gl_PointSize = 0.0;
  gl_Position = vec4(-10.0, -10.0, 0.0, 1.0); // hidden by default

  if (numVortices < 1.0)
    return;

  int slot = int(mod(float(gl_VertexID), numVortices)); // particles are divided over the active vortices
  if (slot >= MAX_VORTICES)
    return;

  float strength = vortexData[slot].z;
  if (strength <= 0.0)
    return;

  float angle = vortexPhase.x;
  float hFrac = vortexPhase.y;

  float coreRadius = vortexData[slot].w;
  float topRadius = vortexParams[slot].x;
  float height = vortexParams[slot].y;
  float seed = vortexParams[slot].w;
  float type = vortexParams[slot].z;

  // funnel shape. Tornado: a massive low wedge hugging the ground - extremely wide at the base
  // and fat all the way up, with a huge rotating wall cloud on top. Dust devil: simple column
  float radius;
  if (type < 0.5) {
    float neck = smoothstep(0.0, 0.35, hFrac);  // ground contact -> wedge body
    float flare = smoothstep(0.40, 1.0, hFrac); // wedge body -> wall cloud
    radius = mix(mix(coreRadius * 9.0, coreRadius * 6.0, neck), topRadius, flare);
  } else {
    radius = mix(coreRadius, topRadius, hFrac);
  }
  radius *= 0.7 + 0.6 * vortexJitter.x;
  radius *= 1.0 + 0.12 * sin(angle * 3.0 + seed * 11.0 + hFrac * 7.0) + 0.08 * sin(angle * 5.0 - seed * 5.0);

  // convert sim units (0 to 1) to clip space (-1 to 1). The axis leans downwind with height
  // (matching the forcing in the boundary shader) and the base sweeps downwind across the terrain
  vec2 axis = vec2(vortexData[slot].x + vortexTilt[slot] * (hFrac + 0.35 * (1.0 - hFrac) * (1.0 - hFrac)), vortexData[slot].y) * 2.0 - 1.0;
  radius *= 2.0;
  float h = hFrac * height * 2.0;

  // orbit around the vertical axis of the vortex. The orbit is an ellipse because of perspective,
  // this fakes the third dimension that the 2D simulation is missing
  float cosA = cos(angle);
  float sinA = sin(angle);

  vec2 outpos;
  // the orbit is flattened near the ground so the wedge sits ON the terrain (no hovering),
  // and flattened near the top so the wall cloud reads as a rotating cloud base
  float flatten = mix(0.35, 1.0, smoothstep(0.0, 0.25, hFrac)) * mix(1.0, 0.45, smoothstep(0.7, 1.0, hFrac) * (1.0 - type));
  outpos.x = axis.x + cosA * radius;
  outpos.y = axis.y + h + sinA * radius * 0.35 * flatten; // foreshortened vertical component of the orbit

  // camera transform, same as the precipitation display
  outpos.x += view.x;
  outpos.y += view.y * aspectRatios[0];
  outpos *= view[2]; // zoom
  outpos.y *= aspectRatios[1] / aspectRatios[0];

  gl_Position = vec4(outpos, 0.0, 1.0);

  depth_out = sinA; // larger than 0 means in front of the vortex axis
  type_out = type;
  strength_out = clamp(strength * 80.0, 0.0, 1.0);
  heightFrac_out = hFrac;

  float size = type < 0.5 ? 3.4 : 2.8;
  size *= mix(1.0, 2.8, smoothstep(0.6, 1.0, hFrac) * (1.0 - type)); // wall cloud particles are bigger
  gl_PointSize = max(view[2] * size * (0.75 + 0.4 * sinA) / aspectRatios[0], 1.0);
}
