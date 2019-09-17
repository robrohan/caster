precision mediump float;
precision mediump int;

varying vec2 v_texcoord;

// uniform sampler2D outputTexture;  // 0
// uniform sampler2D inputTexture;   // 1
// uniform sampler2D lutTexture;     // 2
uniform vec2 resolution;
uniform float time;

uniform vec3 ro;
uniform vec3 rd;

#define MAX_STEPS 100
#define MAX_DIST 200.
#define SURF_DIST .01

struct Pixel {
  float d;
  vec4 c;
};

struct Light {
  vec3 p;
  vec4 c;
};

///////////////////////////////////////////////////////
// Primatives
// a = first end, b = send end and radius
float sdCapsule(vec3 p, vec3 a, vec4 b) {
  vec3 ab = b.xyz-a;
  vec3 ap = p-a;
  
  float t = dot(ab, ap) / dot(ab, ab);
  t = clamp(t, 0., 1.);
  vec3 c = a + t * ab;
  
  return length(p - c) - b.w;
}

// a = first end, b = send end and radius
float sdCylinder(vec3 p, vec3 a, vec4 b) {
  vec3 ab = b.xyz-a;
  vec3 ap = p-a;
  
  float t = dot(ab, ap) / dot(ab, ab);
  vec3 c = a + t * ab;
  
  float x = length(p - c) - b.w;
  float y = (abs(t-.5)-.5)*length(ab);
  float e = length(max(vec2(x, y), 0.));
  float i = min(max(x, y), 0.);
  
  return e + i;
}

// c = center, r = radius (inner, thickness)
float sdTorus(vec3 p, vec3 c, vec4 r) {
  p = p - c;
  float x = length(p.xz)-r.x;
  return length(vec2(x, p.y))-r.y;
}

// s = center.xyz, radius.w
float sdSphere(vec3 p, vec3 c, vec4 s) {
  return length(p - c) - s.x;
}

// c = center, s = bounding size
float sdBox(vec3 p, vec3 c, vec4 s) {
  p = p - c;
  return length(max(abs(p) - s.xyz, 0.));
}

// c = only Y matters
float sdGround(vec3 p, vec3 c, vec4 s) {
  return p.y - c.y;
}

///////////////////////////////////////////////////////
// Operators
float opCombine(float d1, float d2) {
  return min(d1, d2);
}

float opUnion(float d1, float d2) {
  return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
  return max(-d1, d2);
}

float opIntersection(float d1, float d2 ) {
  return max(d1, d2);
}

vec3 opRep(vec3 p, vec3 c) {
  vec3 q = mod(p, c) - (0.5 * c);
  return q;
}

///////////////////////////////////////////////////////
// Smooth Operators
float opSmoothUnion(float d1, float d2, float k) {
  float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0., 1.);
  return mix(d2, d1, h) - k * h * (1. - h);
}

float opSmoothSubtraction(float d1, float d2, float k) {
  float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0., 1.);
  return mix(d2, -d1, h) + k * h * (1. - h);
}

float opSmoothIntersection(float d1, float d2, float k) {
  float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0., 1.);
  return mix(d2, d1, h) + k * h * (1. - h);
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
Pixel scene(float d, vec3 ctx, vec4 col) {
  float tmp0 = d;
  float tmp1 = d;
  vec3 p = ctx;
  // ##caster_scene##
  return Pixel(d, col);
}
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

Pixel GetDist(vec3 p) {
  float d = MAX_DIST;
  vec4 col = vec4(1.0);

  return scene(d, p, col);
}

Pixel RayMarch(vec3 ro, vec3 rd) {
  Pixel dO = Pixel(0., vec4(0.));

  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dO.d;
    Pixel dS = GetDist(p);
    dO.d += dS.d;
    dO.c = dS.c;
    if(dO.d > MAX_DIST || dS.d < SURF_DIST) break;
  }
  return dO;
}

vec3 GetNormal(vec3 p) {
  Pixel px = GetDist(p);
  vec2 e = vec2(.001, 0.);

  vec3 n = px.d - vec3(
    GetDist(p-e.xyy).d,
    GetDist(p-e.yxy).d,
    GetDist(p-e.yyx).d);

  return normalize(n);
}

// Gets the light intensity for the given distance
float GetLight(vec3 p, vec3 n, Light lt) {
  vec3 lightPos = lt.p;
  vec3 l = normalize(lightPos - p);

  float dif = clamp(dot(n, l), 0., 1.);

  // March towards the light to see if we are in
  // shadow or get to the light. We need to move up from
  // the point a small amount to "get off the ground"
  Pixel px = RayMarch(p + (n*SURF_DIST*2.), l);
  if(px.d < .001) return 0.;

  float k = .03;
  if(px.d < length(lightPos - p)) {
    dif *= .5;
  }

  return dif;
}

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
vec4 luminance(Pixel px, vec3 p, vec3 n) {
  vec4 col = px.c;
  // ##caster_light##
  return col;
}
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

void main() {
  vec2 uv = (v_texcoord-.5) * resolution.xy / resolution.y;
  vec4 col = vec4(0.);

  // "Camera"
  vec3 rdir = normalize( vec3(uv.xy, 0.) + rd);

  // Get the pixel distance and color
  Pixel px = RayMarch(ro, rdir);
  vec3 p = ro + rdir * px.d;
  vec3 n = GetNormal(p);

  col = luminance(px, p, n);

  // fog
  float t = px.d;
  col *= exp(-0.0000005 * t * t * t);

  gl_FragColor = col;
}
