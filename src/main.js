const c = require('./core.js');
const r = require('./render.js');

const v = require('./shaders/fwd-screen-v.glsl');
const f = require('./shaders/fwd-screen-f.glsl');

const onload = () => {
  console.log('%c caster', 'color:red; background-color: white;');

  const ctx = c.glContext('#caster');
  const prog = c.glProgram(ctx.gl, f, v);

  const render = function() {
    r.render(ctx.gl, prog);
    requestAnimationFrame(render);
  };
  requestAnimationFrame(render);
};

window.addEventListener('load', onload);
