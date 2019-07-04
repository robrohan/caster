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

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
  vec3 ab = b-a;
  vec3 ap = p-a;
  
  float t = dot(ab, ap) / dot(ab, ab);
  t = clamp(t, 0., 1.);
  vec3 c = a + t * ab;
  
  return length(p - c) - r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
  vec3 ab = b-a;
  vec3 ap = p-a;
  
  float t = dot(ab, ap) / dot(ab, ab);
  vec3 c = a + t * ab;
  
  float x = length(p - c) - r;
  float y = (abs(t-.5)-.5)*length(ab);
  float e = length(max(vec2(x, y), 0.));
  float i = min(max(x, y), 0.);
  
  return e + i;
}

// c = center, r = radius (inner, thickness)
float sdTorus(vec3 p, vec3 c, vec2 r) {
  p = p - c;
  float x = length(p.xz)-r.x;
  return length(vec2(x, p.y))-r.y;
}

// s = center.xyz, radius.w
float sdSphere(vec3 p, vec4 s) {
  return length(p - s.xyz) - s.w;
}

// c = center, s = bounding size
float sdBox(vec3 p, vec3 c, vec3 s) {
  p = p - c;
  return length(max(abs(p) - s, 0.));
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

///////////////////////////////////////////////////////

// GetDist is kind of like the scene. It is a collection of
// distances that make up the image. This is how ray march can know
// about other objects in the scene
Pixel GetDist(vec3 p) {
  vec4 col = vec4(0.8, 0.8, 0.8, 1.);

  // The ground plane
  float planeDist = p.y;
  float d = planeDist;

  // Objects in the scene
  //                              pos             radius  thickness
  float td = sdTorus    (p, vec3(0., .5, 6.),     vec2(1., .5)           );
  //                              pos                bounds
  float bd = sdBox      (p, vec3(-3.5, 1., 6.),    vec3(.5, 1, 1)           );
  //                                  pos   radius
  float sd = sdSphere   (p, vec4(-3., 2., 6., 1.)                         );
  //                        center of end 1     cetner of end 2    radius
  float cd = sdCapsule  (p, vec3(3, .5, 6.),     vec3(3., 2.5, 6.),  .5   );
  //                        center of end 1     cetner of end 2    radius
  float cld = sdCylinder(p, vec3(0, .3, 3),      vec3(3, .3, 5),     .3   );

  // float bd = sdBox      (p, vec4(-3.5, 1, 6, .0),    vec4(.5, 1, 1, .0, .0)  vec4(0., 1., 0., 1.) );
  // float sd = sdSphere   (p, vec4(-2., 2., 9., 1.)    vec4(.0, .0, .0, .0)    vec4(0., 0., 1., 1.) );

  // float td = sdTorus    (p, vec4(0., .5, 6, .0),     vec4(1.25, .5, .0, .0)  vec4(1., 0., 0., 1.) );
  // float cd = sdCapsule  (p, vec4(3, .5, 6., .0),     vec4(3., 2.5, 6., .5)   vec4(1., 1., 0., 1.) ); 
  // float cld = sdCylinder(p, vec4(0, .3, 3, .0),      vec4(3, .3, 5, .3),     vec4(1., 0., 1., 1.) );

  // Combine the box and sphere
  float myop = opSmoothUnion(sd, bd, .9);
  
  // Calc the distance to a particular object
  d = min(cd, planeDist);
  if (d >= cd) { col = vec4(1., 0., 0., 1.); }
  
  d = min(d, td);
  if (d >= td) { col = vec4(0., 1., 0., 1.); }
  
  // d = min(d, bd);
  // if (d >= bd) { col = vec4(0., 0., 1., 1.); }

  // d = min(d, sd);
  // if (d >= sd) { col = vec4(1., 1., 0., 1.); }

  d = min(d, myop);
  if (d >= myop) { col = vec4(0., 0., 1., 1.); }

  d = min(d, cld);
  if (d >= cld) { col = vec4(1., 0., 1., 1.); }
  
  return Pixel(d, col);
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
float GetLight(vec3 p, Light lt) {
  vec3 lightPos = lt.p;
  vec3 l = normalize(lightPos - p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l), 0., 1.);

  // March towards the light to see if we are in
  // shadow or get to the light. We need to move up from
  // the point a small amount to "get off the ground"
  Pixel px = RayMarch(p + (n*SURF_DIST*2.), l);
  if(px.d < length(lightPos - p)) {
    dif *= .1;
  }

  return dif;
}

void main() {
  // center
  vec2 uv = (v_texcoord-.5) * resolution.xy / resolution.y;
  vec4 col = vec4(0.);

  // ray origin (camera), ray direction (forward)
  vec3 ro = vec3(0., 2., -4.);
  // ro.y += sin(time);
  vec3 rd = normalize(vec3(uv.xy, 1.));

  // Get the pixel distance and color
  Pixel px = RayMarch(ro, rd);
  vec3 p = ro + rd * px.d;

  // Find lights and add up those values too
  Light l = Light(vec3(0., 4.5, 7.), vec4(.9, .5, .5, 1.));
  l.p.xz += vec2(sin(time), cos(time)) * 3.2;
  float dif = GetLight(p, l);

  Light l2 = Light(vec3(2., 1.5, 2.), vec4(.2, .2, .2, 1.));
  float dif2 = GetLight(p, l2);

  Light l3 = Light(vec3(-3., .5, 10.), vec4(.1, .8, .1, .5));
  float dif3 = GetLight(p, l3);

  col = px.c * (
    (l.c * dif)
    + (l2.c * dif2)
    + (l3.c * dif3)
  );
  // col = vec4(GetNormal(p), 1.);

  gl_FragColor = col;
}