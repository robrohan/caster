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

float sdTorus(vec3 p, vec2 r) {
  float x = length(p.xz)-r.x;
  return length(vec2(x, p.y))-r.y;
}

float sdSphere(vec3 p, vec4 s) {
  return length( p - s.xyz) - s.w;
}

float dBox(vec3 p, vec3 s) {
	return length(max(abs(p) - s, 0.));
}

///////////////////////////////////////////////////////

// GetDist is kind of like the scene. It is a collection of
// distances that make up the image. This is how ray march can know
// about other objects in the scene
float GetDist(vec3 p) {
  // The ground plane
  float planeDist = p.y;
  float d = planeDist;

  // Objects in the scene
  float td = sdTorus(p - vec3(0., .25, 6), vec2(1.5, .4));
  float sd = sdSphere(p, vec4(-2., 1., 9., 1.));
  float cd = sdCapsule(p, vec3(3, .5, 6.), vec3(3., 2.5, 6.), .5); 
  float bd = dBox(p - vec3(-3.5, 1, 6), vec3(1, 1, 1));
  float cld = sdCylinder(p, vec3(0, .3, 3), vec3(3, .3, 5), .3);
  
  // Calc the distance to a particular object
  d = min(cd, planeDist);
  d = min(d, td);
  d = min(d, bd);
  d = min(d, sd);
  d = min(d, cld);
  
  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
  float dO = 0.;
  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dO;
    float dS = GetDist(p);
    dO += dS;
    if(dO > MAX_DIST || dS < SURF_DIST) break;
  }
  return dO;
}

vec3 GetNormal(vec3 p) {
  float d = GetDist(p);
  vec2 e = vec2(.001, 0.);

  vec3 n = d - vec3(
    GetDist(p-e.xyy),
    GetDist(p-e.yxy),
    GetDist(p-e.yyx));

  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 lightPos = vec3(0., 3.5, 7.);
  lightPos.xz += vec2(sin(time), cos(time)) * 4.;

  vec3 l = normalize(lightPos - p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l), 0., 1.);

  // March towards the light to see if we are in
  // shadow or get to the light. We need to move up from
  // the point a small amount to "get off the ground"
  float d = RayMarch(p + (n*SURF_DIST*2.), l);
  if(d < length(lightPos - p)) {
    dif *= .1;
  }

  return dif;
}

void main() {
  // center
  vec2 uv = (v_texcoord-.5) * resolution.xy / resolution.y;
  vec3 col = vec3(0.);

  // ray origin (camera), ray direction (forward)
  vec3 ro = vec3(0., 2., -4.);
  ro.y += sin(time);
  vec3 rd = normalize(vec3(uv.xy, 1.));

  float d = RayMarch(ro, rd);
  vec3 p = ro + rd * d;

  float dif = GetLight(p);
  col = vec3(dif) * vec3(.9, .9, .9);
  // col = GetNormal(p);

  gl_FragColor = vec4(col, 1.);
}