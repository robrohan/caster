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
        buffer += st[x]();
      }
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
      return `${register} = sdBox(p, vec3(${pos[0]}, ${pos[1]}, ${pos[2]}), vec4(${bounding[0]}, ${bounding[1]}, ${bounding[2]}, 0));`;
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

  function single() {
    return function() {
      return `p = ctx;`;
    };
  }

  function repeat(blocks = [1, 1, 1]) {
    return function() {
      return `p = opRep(ctx, vec3(${blocks[0]}, ${blocks[1]}, ${blocks[2]}));`;
    };
  }

  function draw(func, color = [.5, .5, .5, 1], register = 'tmp0') {
    return function() {
      let b = '';
      const obj = func(register);

      b += obj;
      b += flush(color, register);
      return b;
    };
  };

  function join(funcs) {
    return function(r) {
      let b = '';
      const fLen = funcs.length;
      if (fLen % 2 === 0) {
        throw new Error('Join can not have an even number of statements');
      }

      b += funcs[0](r);
      for (let x = 1; x < fLen; x++) {
        b += funcs[x](x % 2 == 0 ? r : 'tmp1');
      }

      return b;
    };
  }

  // ////////////////////////////////////////////////

  function combine(r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opCombine(${r1}, ${r2});`;
    };
  }

  function union(r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opUnion(${r1}, ${r2});`;
    };
  }

  function subtract(r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opSubtraction(${r1}, ${r2});`;
    };
  }

  function intersect(r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opIntersection(${r1}, ${r2});`;
    };
  }

  // ////////////////////////////////////////////////

  function smoothUnion(param, r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opSmoothUnion(${r1}, ${r2}, ${param[0]});`;
    };
  }

  function smoothSubtract(param, r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opSmoothSubtraction(${r1}, ${r2}, ${param[0]});`;
    };
  }

  function smoothIntersect(param, r1 = 'tmp0', r2 = 'tmp1') {
    return function() {
      return `${r1} = opSmoothIntersection(${r1}, ${r2}, ${param[0]});`;
    };
  }

  // ////////////////////////////////////////////////

  function flush(color, register = 'tmp0') {
    return `
d = min(d, ${register});
if (d >= ${register}) col = vec4(${color[0]}, ${color[1]}, ${color[2]}, ${color[3]});
`;
  }

  // ////////////////////////////////////////////////

  function lights(lights) {
    return function() {
      lightBuffer = '';
      if (lights.length) {
        for (let x = 0; x < lights.length; x++) {
          lightBuffer += lights[x]('l'+x);
          lightBuffer += `float dif${x} = GetLight(p, n, l${x});`;
        }
        lightBuffer = flushLights(lights.length, lightBuffer);
      }
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
    const scene = pg[0]();
    const lights = pg[1]();
    return [scene, lights];
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

  exports.combine = combine;
  exports.union = union;
  exports.subtract = subtract;
  exports.intersect = intersect;

  exports.smoothUnion = smoothUnion;
  exports.smoothSubtract = smoothSubtract;
  exports.smoothIntersect = smoothIntersect;
})(exports);
