TILE_NONE = 0
TILE_FLOOR0 = 1

UV_DIM = 4
UV_INC = (1/UV_DIM)

UVS = {}
UVS[TILE_FLOOR0] = { 'u': 1/UV_DIM, 'v': 0/UV_DIM } # Floor 0

GLSL_COLOR_VERT = """#version 100
precision mediump float;

attribute vec2 at_loc;
attribute vec2 at_uv;
varying vec2 va_uv;
uniform mat4 un_mvp;

void main() {
	va_uv = at_uv;
	gl_Position = un_mvp*vec4(at_loc, 0, 1);
}
"""

GLSL_COLOR_FRAG = """#version 100
precision mediump float;

varying vec2 va_uv;
uniform sampler2D un_tex0;

void main() {
	gl_FragColor = texture2D(un_tex0, va_uv);
}
"""

class Map
	constructor: (name) ->
		data = LEVELS[name]
		@w = data.w
		@h = data.h
		@grid = data.grid

		# Shaders
		@programColor = new esProgram(gl)
		@programColor.addShaderText(GLSL_COLOR_VERT, ES_VERTEX)
		@programColor.addShaderText(GLSL_COLOR_FRAG, ES_FRAGMENT)
		@programColor.bindAttribute(0, 'at_loc')
		@programColor.bindAttribute(1, 'at_uv')
		@programColor.link()

		@unifColorTexture = @programColor.getUniform('un_tex0')
		@unifColorMvp = @programColor.getUniform('un_mvp')

		@floors = []
		i = 0
		for id in @grid
			x = i % @w
			y = Math.floor(i / @w)

			if id is TILE_FLOOR0
				@floors.push(new Floor(id, x, y))

			i++

		# Color vertices
		@vbaColor = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaColor)
		vertsColor = []
		for floor in @floors
			floor.vertsColor(vertsColor)
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertsColor), gl.STATIC_DRAW)

	render: (mvp) ->
		@programColor.use()

		gl.uniformMatrix4fv(@unifColorMvp, false, mvp);
		gl.uniform1i(@unifColorTexture, 0)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaColor)
		gl.enableVertexAttribArray(0);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 4*4, 0);
		gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 4*4, 8);

		gl.drawArrays(gl.TRIANGLES, 0, @floors.length);
		gl.disableVertexAttribArray(1);
		gl.disableVertexAttribArray(0);

class Wall
	constructor: (@v0, @v1) ->

class Floor
	constructor: (@id, @x, @y) ->

	vertsColor: (arr) ->
		u0 = UVS[@id].u
		v0 = UVS[@id].v
		u1 = u0 + UV_INC
		v1 = v0 + UV_INC
		pushColorVert(arr, @x	, @y	, u0, v0)
		pushColorVert(arr, @x+1	, @y	, u1, v0)
		pushColorVert(arr, @x	, @y+1	, u0, v1)

		pushColorVert(arr, @x	, @y+1	, u0, v1)
		pushColorVert(arr, @x+1	, @y+1	, u1, v1)
		pushColorVert(arr, @x+1	, @y	, u1, v0)

pushColorVert = (arr, x, y, u, v) ->
	for field in [x, y, u, v]
		arr.push(field)
	return

