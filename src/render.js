((exports) => {
  const render = {};
  render.screenBufferID = null;

  render.render = function(gl, program) {
    if (render.screenBufferID == null) {
      render.screenBufferID = render.screenBuffer(gl);
    }

    gl.clearColor(0.8, 0.8, 0.8, 1.0);
    gl.clear(gl.DEPTH_BUFFER_BIT
      | gl.COLOR_BUFFER_BIT
      | gl.STENCIL_BUFFER_BIT);
    gl.viewport(0, 0, 800, 600);

    gl.useProgram(program);

    gl.bindBuffer(gl.ARRAY_BUFFER, render.screenBufferID);

    const resolutionID = gl.getUniformLocation(program, 'resolution');
    gl.uniform2fv(resolutionID, [800.0, 600.0]);

    const timeID = gl.getUniformLocation(program, 'time');
    gl.uniform1f(timeID, performance.now() * .002);

    const posLoc = gl.getAttribLocation(program, 'position');
    gl.vertexAttribPointer(posLoc, 3, gl.FLOAT, false, 0, 0);

    // Setting this to nil makes it write to the canvas
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    gl.enableVertexAttribArray(posLoc);

    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  };

  // Create a quad that we can use to render to the full screen.
  render.screenBuffer = function(gl) {
    const glid = gl.createBuffer();
    const screenQuad = new Float32Array([
      -1.0, 1.0, 0,
      -1.0, -1.0, 0,
      1.0, 1.0, 0,
      1.0, -1.0, 0,
    ]);
    gl.bindBuffer(gl.ARRAY_BUFFER, glid);
    gl.bufferData(gl.ARRAY_BUFFER, screenQuad, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    return glid;
  };

  exports.render = render.render;
})(exports);
