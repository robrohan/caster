/* eslint-disable max-len */
/* eslint-disable no-unused-vars */
((exports) => {
  const tp = {};

  // Called when running from text
  function caster(sl) {
    return sl;
  }

  function scene(st) {
    return function() {
      buffer = '';
      for (let x = 0; x < st.length; x++) {
        // console.log('a', st[x]);
        buffer += st[x]();
      }
      // console.log(buffer);
      return buffer;
    };
  }

  function sphere(pos, radius) {
    return function(register) {
      return `${register} = sdSphere(p, vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(${radius[0]}, 0., 0., 0.));`;
    };
  };

  function cube(pos, bounding) {
    return function(register) {
      return `${register} = sdBox(p, vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(${bounding[0]}, ${bounding[1]}, ${bounding[2]}, ${bounding[3]}));`;
    };
  };

  function ground(pos) {
    return function(register) {
      return `${register} = sdGround(p, vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(0.));`;
    };
  };

  function capsule(pos1, pos2) {
    return function(register) {
      return `${register} = sdCapsule(p, vec3(${pos1[0]}, ${pos1[1]}, ${pos1[2]}), vec4(${pos2[0]}, ${pos2[1]}, ${pos2[2]}, ${pos2[3]}));`;
    };
  };

  function cylinder(pos1, pos2) {
    return function(register) {
      return `${register} = sdCylinder(p, vec3(${pos1[0]}, ${pos1[1]}, ${pos1[2]}), vec4(${pos2[0]}, ${pos2[1]}, ${pos2[2]}, ${pos2[3]}));`;
    };
  };

  function torus(pos, radius) {
    return function(register) {
      return `${register} = sdTorus(p, vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(${radius[0]}, ${radius[1]}, 0., 0.));`;
    };
  };

  // ////////////////////////////////////////////////

  function draw(func, color, register = 'tmp0') {
    return function() {
      let b = '';
      const obj = func(register);

      b += obj;
      b += flush(color, register);
      return b;
    };
  };

  function join(o1, o2, func, color) {
    return function() {
      let b = '';
      const obj1 = o1('tmp0');
      const obj2 = o2('tmp1');

      b += obj1;
      b += obj2;
      b += func();
      b += flush(color);
      return b;
    };
  }

  // ////////////////////////////////////////////////

  function smoothUnion(param) {
    return function() {
      return `tmp0 = opSmoothUnion(tmp0, tmp1, ${param[0]});`;
    };
  }

  // ////////////////////////////////////////////////

  function flush(color, register = 'tmp0') {
    return `d = min(d, ${register});
    if (d >= ${register}) col = vec4(${color[0]}, ${color[1]}, ${color[2]}, ${color[3]});`;
  }

  // ////////////////////////////////////////////////

  function lights(lights) {
    return function() {
      lightBuffer = '';
      for (let x = 0; x < lights.length; x++) {
        lightBuffer += lights[x]('l'+x);
        lightBuffer += `float dif${x} = GetLight(p, n, l${x});`;
      }
      lightBuffer = flushLights(lights.length, lightBuffer);
      return lightBuffer;
    };
  }

  function light(pos, color) {
    return function(vari) {
      return `Light ${vari} = Light(vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(${color[0]}, ${color[1]}, ${color[2]}, ${color[3]}));`;
    };
  }

  function flushLights(lightLen, buffer) {
    buffer += `col = col * (`;
    for (let x = 0; x < lightLen; x++) {
      buffer += `+ (l${x}.c * dif${x})`;
    }
    buffer += ` );`;

    return buffer;
  }

  // //////////////////////////////////

  tp.run = function(pg) {
    return [pg[0](), pg[1]()];
  };

  tp.parse = function(pgr) {
    const c = eval(pgr);
    return tp.run(c);
  };

  // //////////////////////////////////

  exports.transpile = tp.parse;
  exports.run = tp.run;

  exports.scene = scene;
  exports.draw = draw;
  exports.join = join;

  exports.sphere = sphere;
  exports.cube = cube;
  exports.ground = ground;
  exports.capsule = capsule;
  exports.cylinder = cylinder;
  exports.torus = torus;

  exports.lights = lights;
  exports.light = light;

  exports.smoothUnion = smoothUnion;
})(exports);
