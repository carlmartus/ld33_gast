TILE_NONE = 0
TILE_FLOOR0 = 1

UV_DIM = 4
UV_INC = (1/UV_DIM)

UVS = {}
UVS[TILE_NONE] =	{ 'solid':true, 'u': 0/UV_DIM, 'v': 0/UV_DIM } # Nothing
UVS[TILE_FLOOR0] =	{ 'solid':false, 'u': 1/UV_DIM, 'v': 0/UV_DIM } # Floor 0

GLSL_COLOR_VERT = """#version 100
precision mediump float;

attribute vec2 at_loc;
attribute vec2 at_uv;
varying vec2 va_uv;
varying vec2 va_loc;
uniform mat4 un_mvp;

void main() {
	va_uv = at_uv;
	va_loc = at_loc;
	gl_Position = un_mvp*vec4(at_loc, 0, 1);
}
"""

GLSL_COLOR_FRAG = """#version 100
precision mediump float;

varying vec2 va_uv;
uniform sampler2D un_tex0;
uniform vec2 un_lightPos;
uniform vec3 un_lightCol;
uniform float un_lightRad;
varying vec2 va_loc;

void main() {
	vec4 col = texture2D(un_tex0, va_uv);
	float dist = 1.0 - clamp(distance(va_loc, un_lightPos)/un_lightRad, 0.0, 1.0);
	//if (col == vec4(0, 1, 0, 1)) discard;
	gl_FragColor = dist*col*vec4(un_lightCol, 1);
}
"""

GLSL_EDGE_VERT = """#version 100
precision mediump float;

attribute vec2 at_loc;
attribute vec2 at_nor;
uniform mat4 un_mvp;
uniform vec2 un_lightPos;

void main() {
	vec2 loc = at_loc;
	vec2 towards = at_loc - un_lightPos;
	if (dot(at_nor, towards) > 0.0) {
		loc += normalize(towards)*15.0;
	}
	gl_Position = un_mvp*vec4(loc, 0, 1);
}
"""

GLSL_EDGE_FRAG = """#version 100
precision mediump float;

void main() {
	gl_FragColor = vec4(1, 0, 0, 1);
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
		@unifColorLightCol = @programColor.getUniform('un_lightCol')
		@unifColorLightPos = @programColor.getUniform('un_lightPos')
		@unifColorLightRad = @programColor.getUniform('un_lightRad')

		@programEdge = new esProgram(gl)
		@programEdge.addShaderText(GLSL_EDGE_VERT, ES_VERTEX)
		@programEdge.addShaderText(GLSL_EDGE_FRAG, ES_FRAGMENT)
		@programEdge.bindAttribute(0, 'at_loc')
		@programEdge.bindAttribute(1, 'at_nor')
		@programEdge.link()
		@unifEdgeMvp = @programEdge.getUniform('un_mvp')
		@unifEdgeLightPos = @programEdge.getUniform('un_lightPos')

		# Geometry
		@floors = []
		i = 0
		for id in @grid
			x = i % @w
			y = Math.floor(i / @w)

			if id is TILE_FLOOR0
				@floors.push(new Floor(id, x, y))

			i++

		@walls = []
		goodCoord = (x, y) =>
			return false if (x < 0 or y < 0 or x >= @w or y >= @h)
			return not UVS[@grid[x + y*@w]].solid

		i = 0
		for id in @grid
			x = i % @w
			y = Math.floor(i / @w)

			if id is TILE_FLOOR0
				if not goodCoord(x-1, y)
					@pushWall(x, y, 0, 1)
				if not goodCoord(x+1, y)
					@pushWall(x+1, y, 0, 1)
				if not goodCoord(x, y-1)
					@pushWall(x, y, 1, 0)
				if not goodCoord(x, y+1)
					@pushWall(x, y+1, 1, 0)
			i++
		console.log(@walls)

		# Color vertices
		@vbaColor = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaColor)
		vertsColor = []
		for floor in @floors
			floor.vertsColor(vertsColor)
		@vbaColorCount = vertsColor.length / 4
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertsColor), gl.STATIC_DRAW)

		# Edge vertices
		@vbaEdge = gl.createBuffer()
		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaEdge)
		vertsEdge = []
		for wall in @walls
			wall.vertsEdge(vertsEdge)
		@vbaEdgeCount = vertsEdge.length / 4
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertsEdge), gl.STATIC_DRAW)

	setMvp: (mvp) ->
		@programColor.use()
		gl.uniformMatrix4fv(@unifColorMvp, false, mvp);
		@programEdge.use()
		gl.uniformMatrix4fv(@unifEdgeMvp, false, mvp);

	renderLight: (light) ->
		gl.enable(gl.STENCIL_TEST);

		gl.stencilMask(0xff);
		gl.clear(gl.STENCIL_BUFFER_BIT);

		gl.enable(gl.TEXTURE_2D)
		gl.colorMask(false, false, false, false);
		gl.stencilFunc(gl.ALWAYS, 1, 0xff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		@renderEdges(light)
		gl.disable(gl.TEXTURE_2D)

		gl.colorMask(true, true, true, true);
		gl.stencilMask(0);
		gl.stencilFunc(gl.EQUAL, 0, 0xff);
		@renderColors(light)

		gl.disable(gl.STENCIL_TEST);

	renderColors: (light) ->
		@programColor.use()

		#gl.uniformMatrix4fv(@unifColorMvp, false, mvp);
		gl.uniform1i(@unifColorTexture, 0)

		light.uniforms(@unifColorLightPos, @unifColorLightCol, @unifColorLightRad)
		#gl.uniform3f(@unifColorLightCol, 1.0, 0.0, 0.0)
		#gl.uniform2f(@unifColorLightPos, 0.5, 0.5)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaColor)
		gl.enableVertexAttribArray(0);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 4*4, 0);
		gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 4*4, 8);

		gl.drawArrays(gl.TRIANGLES, 0, @vbaColorCount);
		gl.disableVertexAttribArray(1);
		gl.disableVertexAttribArray(0);

	renderEdges: (light) ->
		@programEdge.use()

		#gl.uniformMatrix4fv(@unifEdgeMvp, false, mvp);
		#gl.uniform2f(@unifEdgeLightPos, 4.5, 4.5)
		light.uniforms(@unifEdgeLightPos, null)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaEdge)
		gl.enableVertexAttribArray(0);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 4*4, 0);
		gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 4*4, 8);

		gl.drawArrays(gl.TRIANGLES, 0, @vbaEdgeCount);
		gl.disableVertexAttribArray(1);
		gl.disableVertexAttribArray(0);

	pushWall: (x, y, dx, dy) ->
		v0 = esVec2_parse(x, y)
		v1 = esVec2_parse(x+dx, y+dy)
		@walls.push(new Wall(v0, v1))

class Wall
	constructor: (@v0, @v1) ->
		@dir = esVec2_create()
		esVec2_sub(@dir, @v1, @v0)

		normal = esVec2_create()
		esVec2_orthogonal(normal, @dir)

		@n0 = esVec2_create()
		esVec2_normalize(@n0, normal)

		@n1 = esVec2_create()
		esVec2_mulk(@n1, @n0, -1.0)

	vertsEdge: (arr) ->
		pushEdgeVert(arr, @v0[0], @v0[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v1[0], @v1[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v0[0], @v0[1], @n1[0], @n1[1])

		pushEdgeVert(arr, @v1[0], @v1[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v1[0], @v1[1], @n1[0], @n1[1])
		pushEdgeVert(arr, @v0[0], @v0[1], @n1[0], @n1[1])

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

class Light
	constructor: (@r, @g, @b, @radius) ->
		@x = 0.5
		@y = 0.5

	setPosition: (@x, @y) ->

	uniforms: (unifPos, unifCol, unifRad) ->
		gl.uniform2f(unifPos, @x, @y) if unifPos
		gl.uniform3f(unifCol, @r, @g, @b) if unifCol
		gl.uniform1f(unifRad, @radius) if unifRad

pushColorVert = (arr, x, y, u, v) -> pushVerts(arr, [x, y, u, v])
pushEdgeVert = (arr, x, y, nX, nY) -> pushVerts(arr, [x, y, nX, nY])

pushVerts = (arr, list) ->
	for field in list
		arr.push(field)
	return

