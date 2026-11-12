#version 460 core
#include <flutter/runtime_effect.glsl>

// El agua bajo el hielo, en la pesca: el azul que se oscurece hacia el
// fondo, los rayos de luz que entran por el hielo y se mecen, y la luz que
// baila en el agua (causticas), mas fuerte cerca del hielo.

precision highp float;

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

const float TAU = 6.28318530718;

// La red de luz de las causticas: ondas que se deforman entre si.
float causticas(vec2 p, float t) {
  vec2 q = mod(p * TAU, TAU) - 250.0;
  vec2 i = q;
  float c = 1.0;
  const float fuerza = 0.005;
  for (int n = 0; n < 3; n++) {
    float tt = t * (1.0 - (3.5 / float(n + 1)));
    i = q + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
    c += 1.0 / length(vec2(q.x / (sin(i.x + tt) / fuerza),
                           q.y / (cos(i.y + tt) / fuerza)));
  }
  c /= 3.0;
  c = 1.17 - pow(c, 1.4);
  return pow(abs(c), 8.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float hondo = uv.y;
  float aspecto = uSize.x / uSize.y;

  vec3 color = mix(vec3(0.494, 0.765, 0.902), vec3(0.149, 0.459, 0.659),
                   smoothstep(0.0, 0.45, hondo));
  color = mix(color, vec3(0.031, 0.141, 0.243), smoothstep(0.45, 1.0, hondo));

  // Los rayos: bandas inclinadas que se cruzan y se apagan con lo hondo.
  float x = uv.x * aspecto * 2.2 + uv.y * 0.7;
  float rayo = (sin(x * 5.0 + uTime * 0.45) * 0.5 + 0.5) *
               (sin(x * 12.3 - uTime * 0.7) * 0.5 + 0.5);
  rayo += 0.35 * (sin(x * 2.1 + uTime * 0.25) * 0.5 + 0.5);
  rayo *= pow(1.0 - hondo, 1.5);
  color += vec3(0.75, 0.93, 1.0) * rayo * 0.2;

  float luz = causticas(vec2(uv.x * aspecto, uv.y) * 2.4, uTime * 0.55);
  color += vec3(0.8, 0.97, 1.0) * luz * 0.32 *
           (1.0 - smoothstep(0.05, 0.9, hondo));

  fragColor = vec4(color, 1.0);
}
