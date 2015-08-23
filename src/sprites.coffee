SPRITE_VERTS = 6
SPRITE_ELEMS = 4
SPRITE_MAX = 200

class SpriteConst
	constructor: (idU, idV, @dim) ->
		@u0 = idU/UV_DIM
		@v0 = idV/UV_DIM
		@u1 = @u0 + @dim/UV_DIM
		@v1 = @v0 + @dim/UV_DIM


SPRITE_NONE = new SpriteConst(0, 0, 1)
SPRITE_FLOOR0 = new SpriteConst(1, 0, 1)

SPRITE_YOU = new SpriteConst(1, 2, 1)
SPRITE_YOU_AURA = new SpriteConst(0, 2, 1)
SPRITE_YOU_ARMS = new SpriteConst(2, 2, 1)

GLSL_SPRITE_VERT = """#version 100
precision mediump float;

attribute vec2 at_loc;
attribute vec2 at_uv;
uniform mat4 un_mvp;
varying vec2 va_uv;

void main() {
	va_uv = at_uv;
	gl_Position = un_mvp*vec4(at_loc, 0, 1);
}
"""

GLSL_SPRITE_FRAG = """#version 100
precision mediump float;

uniform sampler2D un_tex0;
varying vec2 va_uv;

void main() {
	vec4 col = texture2D(un_tex0, va_uv);
	if (col == vec4(0, 1, 0, 1)) discard;
	gl_FragColor = col;
}
"""

class SpriteLib
	constructor: ->
		@count = 0
		@vertCount = 0
		@holders = (new SpriteHolder() for i in [0..(SPRITE_MAX-1)])
		@arr = new Float32Array(SPRITE_MAX*SPRITE_ELEMS*SPRITE_VERTS)

	create: ->
		# VBA
		@vba = gl.createBuffer(gl.ARRAY_BUFFER)
		gl.bindBuffer(gl.ARRAY_BUFFER, @vba)
		gl.bufferData(gl.ARRAY_BUFFER,
			SPRITE_VERTS*SPRITE_ELEMS*SPRITE_MAX, gl.STREAM_DRAW)

		# Shaders
		@program = new esProgram(gl)
		@program.addShaderText(GLSL_SPRITE_VERT, ES_VERTEX)
		@program.addShaderText(GLSL_SPRITE_FRAG, ES_FRAGMENT)
		@program.bindAttribute(0, 'at_loc')
		@program.bindAttribute(1, 'at_uv')
		@program.link()
		@unifMvp = @program.getUniform('un_mvp')
		@unifTex0 = @program.getUniform('un_tex0')

	push: (x, y, v, dim, sprite) ->
		return if @count >= SPRITE_MAX

		@holders[@count].set(x, y, v, dim, sprite)
		@count += 1

	copy: ->
		if @count <= 0
			@vertCount = 0
			return

		offset = 0
		for i in [0..(@count-1)]
			@holders[i].writeToArray(@arr, offset)
			offset += SPRITE_VERTS*SPRITE_ELEMS

		gl.bindBuffer(gl.ARRAY_BUFFER, @vba)
		sub = @arr.subarray(0, offset)
		gl.bufferSubData(gl.ARRAY_BUFFER, 0, sub)
		@vertCount = @count*6
		@count = 0

	setMvp: (mvp) ->
		@program.use()
		gl.uniformMatrix4fv(@unifMvp, false, mvp);

	render: ->
		return if @vertCount <= 0

		@program.use()
		gl.enable(gl.TEXTURE_2D)
		gl.uniform1i(@unifTex0, 0)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vba)
		gl.enableVertexAttribArray(0);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 4*4, 0);
		gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 4*4, 8);

		gl.drawArrays(gl.TRIANGLES, 0, @vertCount);
		gl.disableVertexAttribArray(1);
		gl.disableVertexAttribArray(0);
		gl.disable(gl.TEXTURE_2D)

class SpriteHolder
	constructor: ->
		@loc = esVec2_create()
		@dim = 1.0
		@setAngle(0.0)

	setAngle: (@v) ->
		@cv = Math.cos(@v)
		@sv = Math.sin(@v)

	set: (x, y, v, @dim, @sprite) ->
		v += Math.PI * 0.25
		@loc[0] = x
		@loc[1] = y
		@setAngle(v)

	writeToArray: (arr, offset) ->
		px = @cv*@dim
		py = @sv*@dim

		@writeVerticeToArray(arr, offset+0*SPRITE_ELEMS, @loc[0]+px, @loc[1]+py, @sprite.u0, @sprite.v0)
		@writeVerticeToArray(arr, offset+1*SPRITE_ELEMS, @loc[0]+py, @loc[1]-px, @sprite.u1, @sprite.v0)
		@writeVerticeToArray(arr, offset+2*SPRITE_ELEMS, @loc[0]-px, @loc[1]-py, @sprite.u1, @sprite.v1)

		@writeVerticeToArray(arr, offset+3*SPRITE_ELEMS, @loc[0]-px, @loc[1]-py, @sprite.u1, @sprite.v1)
		@writeVerticeToArray(arr, offset+4*SPRITE_ELEMS, @loc[0]-py, @loc[1]+px, @sprite.u0, @sprite.v1)
		@writeVerticeToArray(arr, offset+5*SPRITE_ELEMS, @loc[0]+px, @loc[1]+py, @sprite.u0, @sprite.v0)

	writeVerticeToArray: (arr, offset, x, y, u, v) ->
		arr[offset+0] = x
		arr[offset+1] = y
		arr[offset+2] = u
		arr[offset+3] = v

