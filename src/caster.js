const c = require('./core.js');
const r = require('./render.js');

const v = require('./shaders/vertex.glsl');
const f = require('./shaders/sdFragment.glsl');

const tp = require('./transpile.js');

function resize(ctx) {
  const gl = ctx.gl;
  const width = gl.canvas.clientWidth;
  const height = gl.canvas.clientHeight;
  if (gl.canvas.width != width || gl.canvas.height != height) {
    gl.canvas.width = width;
    gl.canvas.height = height;
  }
}

function compileScene(ctx) {
  // const s = document.querySelector('.scene').value;
  // const sceneLights = tp.transpile(s);

  const t = [
    () => tp.scene([
      // tp.draw(tp.sphere([3, 1, 6], [1]), [0, 1, 1, 1]),
      // tp.draw(tp.sphere([-3, 1, 6], [1.3]), [1, .5, 0, 1]),
      () => {
        let buf = '';
        const cluster = [];

        cluster.push( tp.sphere([0, Math.random() * 2, 0], [.1]) );
        for (let z = 10; z < 20; z++) {
          for (let x = -4; x <= 4; x++) {
            cluster.push( tp.sphere([x, Math.random() * 2, z], [.1]) );
            cluster.push( tp.combine() );
          }
        }

        // cluster.push( tp.sphere([0, Math.random() * 2, 4], [.1]) );
        // cluster.push( tp.sphere([0, Math.random() * 2, 4], [.1]) );
        // cluster.push( tp.union() );

        // /////////////////////////////////
        const o = tp.join(cluster);
        // console.log(o('tmp0'));
        buf += tp.draw( o )();
        // console.log(buf);
        // /////////////////////////////////
        return buf;
      },
      // tp.draw(
      //     tp.join([
      //       tp.sphere([.5, 1, 6], [1]),
      //       tp.sphere([-.5, 1, 6], [1]),
      //       tp.smoothUnion([.2]),
      //     ]),
      // ),
      // tp.draw(tp.ground([0, -2, 0])),
    ]),
    () => tp.lights([
      tp.light([0, 0, 0], [1, 1, 1, 1]),
      // tp.light([0, 35, -4], [1, 1, 1, 1]),
    ]),
  ];
  const sceneLights = tp.run(t);

  let frag = f.toString().replace('// ##caster_scene##', sceneLights[0]);
  frag = frag.toString().replace('// ##caster_light##', sceneLights[1]);
  const prog = c.glProgram(ctx.gl, frag, v);

  return prog;
}

const onload = () => {
  console.log('%c caster', 'color:red; background-color: white;');

  const ctx = c.glContext('#caster');
  let prog = compileScene(ctx);

  const code = document.querySelector('.code');
  code.addEventListener('keypress', (e) => {
    if (e.keyCode === 13 && e.shiftKey) {
      e.preventDefault();
      prog = compileScene(ctx);
    }
  });

  const render = function() {
    resize(ctx);
    r.render(ctx, prog);
    requestAnimationFrame(render);
  };
  requestAnimationFrame(render);
};

window.addEventListener('load', onload);
