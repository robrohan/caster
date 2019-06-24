((exports) => {
  const core = {};
  let currentDocument;

  core.setupCanvas = function(canvas) {
    const options = {
      alpha: false,
      antialias: false,
      depth: true,
      stencil: true,
      premultipliedAlpha: true,
      preserveDrawingBuffer: false,
      powerPreference: 'default',
    };

    let gl;

    if (canvas) {
      gl = canvas.getContext('webgl', options);

      if (!gl) {
        gl = canvas.getContext('experimental-webgl', options);
      }

      if (!gl) {
        throw Error('Your browser does not support WebGL');
      }

      // gl.getSupportedExtensions();
      casterGl = gl;
      casterCanvas = canvas;
    } else {
      throw Error('Canvas is undefined');
    }

    // gl.enable(gl.DEPTH_TEST);

    // gl.enable(gl.CULL_FACE);
    // gl.frontFace(gl.CCW);
    // gl.cullFace(gl.BACK);

    // gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    // gl.enable(gl.BLEND);

    return {canvas, gl};
  };

  core.setupDocument = function(doc) {
    currentDocument = doc;
  };

  core.getDocument = function() {
    return currentDocument || document;
  };

  core.glContext = function(canvasSelector = '#caster') {
    const canvas = core.getDocument().querySelector(canvasSelector);
    return core.setupCanvas(canvas);
  };

  core.glProgram = function(gl, fragmentShaderText, vertexShaderText) {
    let program;
    if (gl) {
      // Shaders
      const vertexShader = gl.createShader(gl.VERTEX_SHADER);
      const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);

      gl.shaderSource(vertexShader, vertexShaderText);
      gl.shaderSource(fragmentShader, fragmentShaderText);

      gl.compileShader(vertexShader);
      if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
        throw Error('ERROR compiling vertex shader! '
          + gl.getShaderInfoLog(vertexShader));
      }

      gl.compileShader(fragmentShader);
      if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
        throw Error('ERROR compiling fragment shader! '
          + gl.getShaderInfoLog(fragmentShader));
      }
      // Program
      program = gl.createProgram();
      gl.attachShader(program, vertexShader);
      gl.attachShader(program, fragmentShader);
      gl.linkProgram(program);
      if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        throw Error('ERROR linking program! ' + gl.getProgramInfoLog(program));
      }
      gl.validateProgram(program);
      if (!gl.getProgramParameter(program, gl.VALIDATE_STATUS)) {
        throw Error('ERROR validating program! '
          + gl.getProgramInfoLog(program));
      }

      gl.deleteShader(vertexShader);
      gl.deleteShader(fragmentShader);
    }

    return program;
  };

  exports.glContext = core.glContext;
  exports.setupDocument = core.setupDocument;
  exports.glProgram = core.glProgram;
})(exports);
