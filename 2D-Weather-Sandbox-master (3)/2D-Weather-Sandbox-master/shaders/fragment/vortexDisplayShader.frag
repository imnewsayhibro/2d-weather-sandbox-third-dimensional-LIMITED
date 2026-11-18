#version 300 es
precision highp float;

in vec2 phase_out;
in vec2 jitter_out;
in float depth_out;   // position on the orbit relative to the viewer, -1 to 1
in float type_out;    // 0 = tornado, 1 = dust devil
in float strength_out;
in float heightFrac_out;

out vec4 fragmentColor;

void main()
{
  if (strength_out <= 0.0)
    discard;

  vec2 centerOffset = gl_PointCoord - 0.5;
  float dist = length(centerOffset) * 2.0;
  if (dist > 1.0)
    discard;

  float alpha = (1.0 - dist) * (1.0 - dist); // soft round particle

  // particles in front of the vortex axis are brighter than those behind it (fake 3D)
  alpha *= 0.55 + 0.45 * depth_out;
  alpha *= 0.25 + 0.75 * strength_out;

  vec3 color;
  if (type_out < 0.5) { // tornado: brown dust skirt at the base, white-grey vapour condensation funnel above, dark wall cloud on top
    vec3 dustCol = vec3(0.42, 0.33, 0.24);
    vec3 funnelCol = vec3(0.72, 0.72, 0.76);
    vec3 wallCloudCol = vec3(0.30, 0.30, 0.35);
    color = mix(dustCol, funnelCol, smoothstep(0.0, 0.12, heightFrac_out));
    color = mix(color, wallCloudCol, smoothstep(0.55, 0.95, heightFrac_out));
    alpha *= mix(1.35, 1.0, smoothstep(0.0, 0.35, heightFrac_out)); // the dust cloud near the ground is thick
    alpha *= mix(1.0, 1.3, smoothstep(0.55, 1.0, heightFrac_out));  // wall cloud is dense
  } else { // dust devil: sandy dust that thins out with height
    color = vec3(0.78, 0.62, 0.40);
    alpha *= mix(1.0, 0.45, smoothstep(0.1, 1.0, heightFrac_out));
  }

  fragmentColor = vec4(color, alpha * 0.55);
}
