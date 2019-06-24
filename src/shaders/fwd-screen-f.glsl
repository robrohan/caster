precision mediump float;
precision mediump int;

varying vec2 v_texcoord;

// uniform sampler2D outputTexture;  // 0
// uniform sampler2D inputTexture;   // 1
// uniform sampler2D lutTexture;     // 2
uniform vec2 resolution;
uniform float time;

// uniform vec3      iResolution;           // viewport resolution (in pixels)
// uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

// const float crossWidth = .001;
// const float crossHeight = .001;
// const float crossSize = .504;

void main() {
  vec2 texcoord = v_texcoord;

  // vec4 texel = texture2D(inputTexture, texcoord);

  // vec4 lutColor = vec4(3., 3., 3., 1.);
  // if(
  //    ((texcoord.x >= .5 - crossWidth && texcoord.x <= .5 + crossWidth) && (texcoord.y < crossSize && texcoord.y > 1. - crossSize))      // line down X
  //    || ((texcoord.y >= .5 - crossHeight && texcoord.y <= .5 + crossHeight) && (texcoord.x < crossSize && texcoord.x > 1. - crossSize)) // line across Y
  //   ) {
  //   lutColor = vec4(9., 9., 9., 1.);
  // }

  gl_FragColor = vec4(texcoord, 1., 1.); // lutColor;
}