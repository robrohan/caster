precision mediump float;
precision mediump int;

varying vec2 v_texcoord;

// uniform sampler2D outputTexture;  // 0
// uniform sampler2D inputTexture;   // 1
// uniform sampler2D lutTexture;     // 2
uniform vec2 resolution;
uniform float time;

#define MAX_STEPS 100
#define MAX_DIST 100.
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
  return p.y;
}

///////////////////////////////////////////////////////
// Operators
float opUnion(float d1, float d2) {
  return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
  return max(-d1, d2);
}

float opIntersection(float d1, float d2 ) {
  return max(d1, d2);
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

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
Pixel scene(float d, vec3 p, vec4 col) {
  float tmp0 = d;
  float tmp1 = d;

  // ###########
  tmp0 = sdSphere(p, vec3(3., 1., 6.), vec4(1., 0., 0., 0.));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(0., 1., 1., 1.);

  tmp0 = sdSphere(p, vec3(-3., 1.5, 6.), vec4(1.5, 0., 0., 0.));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(0., 1., 0., 1.);

  tmp0 = sdGround(p, vec3(0., 0., 0.), vec4(0., 0., 0., 0.));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(.4, .4, .4, 1.);

  tmp0 = sdBox(p, vec3(0., .5, 6.), vec4(.5, .5, .5, 0.));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(1., 1., 0., 1.);

  tmp0 = sdCapsule(p, vec3(1., .5, 8.), vec4(1., 2.5, 8., .5));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(1., 0., 1., 1.);

  tmp0 = sdCylinder(p, vec3(-1., .5, 8.), vec4(-1, 2.5, 8., .5));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(.0, .0, 1., 1.);

  tmp0 = sdBox(p, vec3(0., .5, 2.), vec4(.5, .75, .5, 0.));
  tmp1 = sdTorus(p, vec3(0., .5, 2.),  vec4(1.25, .5, .0, .0));
  tmp0 = opSmoothUnion(tmp0, tmp1, 1.);
  tmp1 = sdSphere(p, vec3(-2.25, .5, 2.),  vec4(.25, .0, .0, .0));
  tmp0 = opSmoothUnion(tmp0, tmp1, 1.);
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(1., 0., 0., 1.);
  // ###########
  
  //////////////////////////////////////////////////////////
  // pretend light source
  vec3 lgt = vec3(0., 4., 7.);
  lgt.xz += vec2(sin(time), cos(time)) * 3.2;
  lgt.y += cos(time) * sin(time);
  tmp0 = sdSphere(p, lgt, vec4(.08, 0., 0., 0.));
  d = min(d, tmp0);
  if (d >= tmp0) col = vec4(1., 1., 1., 1.);
  //////////////////////////////////////////////////////////

  return Pixel(d, col);
}
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

// GetDist is kind of like the scene. It is a collection of
// distances that make up the image. This is how ray march can know
// about other objects in the scene
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
  if(px.d < length(lightPos - p)) {
    dif *= .05;
  }

  return dif;
}


////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
vec4 luminance(Pixel px, vec3 p, vec3 n) {
  vec4 col = px.c;
  
  // ###########
  Light l = Light(vec3(0., 3.5, 7.), vec4(.5, .5, .2, 1.));
  l.p.xz += vec2(sin(time), cos(time)) * 3.2; // ignore
  l.p.y += cos(time) * sin(time);             // ignore
  float dif = GetLight(p, n, l);

  Light l2 = Light(vec3(0., 45., 6.), vec4(1.));
  float dif2 = GetLight(p, n, l2);

  col = col * (
    + (l.c * dif)
    + (l2.c * dif2)
  );
  // ###########
  
  return col;
}
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////


void main() {
  // center
  vec2 uv = (v_texcoord-.5) * resolution.xy / resolution.y;
  vec4 col = vec4(0.);

  // Camera
  // ray origin (camera), ray direction (forward)
  vec3 ro = vec3(0., 2., -4.);
  vec3 rd = normalize(vec3(uv.xy, 1.));

  // Get the pixel distance and color
  Pixel px = RayMarch(ro, rd);
  vec3 p = ro + rd * px.d;
  vec3 n = GetNormal(p);

  col = luminance(px, p, n);
  // col = vec4(GetNormal(p), 1.);

  gl_FragColor = col;
}
