TILE_NONE = 0
TILE_FLOOR0 = 1
TILE_FLOOR1 = 2

TILE_SIGN0 = 4
TILE_SIGN1 = 5
TILE_SIGN2 = 6
TILE_SIGN3 = 7

UV_DIM = 4
UV_INC = (1/UV_DIM)

UVS = {}
UVS[TILE_NONE] =	{ 'solid':true, 'u': 0/UV_DIM, 'v': 0/UV_DIM } # Nothing
UVS[TILE_FLOOR0] =	{ 'solid':false, 'u': 1/UV_DIM, 'v': 0/UV_DIM } # Tiles
UVS[TILE_FLOOR1] =	{ 'solid':false, 'u': 2/UV_DIM, 'v': 0/UV_DIM } # Concreet
UVS[TILE_SIGN0] =	{ 'solid':false, 'u': 0/UV_DIM, 'v': 1/UV_DIM } # Sign
UVS[TILE_SIGN1] =	{ 'solid':false, 'u': 1/UV_DIM, 'v': 1/UV_DIM }
UVS[TILE_SIGN2] =	{ 'solid':false, 'u': 2/UV_DIM, 'v': 1/UV_DIM }
UVS[TILE_SIGN3] =	{ 'solid':false, 'u': 3/UV_DIM, 'v': 1/UV_DIM }

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
	constructor: (@state) ->
		@timeOffset = esVec2_parse(0, 0)
		@playerStart = esVec2_parse(0, 0)

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

	loadMap: (name) ->
		data = LEVELS[name]
		@w = data.w
		@h = data.h
		@grid = data.grid
		@objects = data.objects
		@time = 0.0

		# Geometry
		@floors = []
		i = 0
		for id in @grid
			x = i % @w
			y = Math.floor(i / @w)

			if not UVS[id].solid
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

			if not UVS[id].solid
				if not goodCoord(x-1, y)
					@pushGridWall(x, y, 0, 1)
				if not goodCoord(x+1, y)
					@pushGridWall(x+1, y+1, 0, -1)
				if not goodCoord(x, y-1)
					@pushGridWall(x+1, y, -1, 0)
				if not goodCoord(x, y+1)
					@pushGridWall(x, y+1, 1, 0)
			i++

		# Objects
		@lights = []
		@ais = []
		@paths = {}
		@nextLevel = 'l0'
		@nextArea0 = esVec2_parse(900, 900)
		@nextArea1 = esVec2_parse(909, 909)
		for obj in @objects
			switch obj.type
				when 'pillar'
					p = new Pillar(obj.cx, obj.cy, obj.w, obj.h)
					p.pushWalls(@walls)
				when 'player'
					@playerStart[0] = obj.cx
					@playerStart[1] = obj.cy
				when 'light'
					[r, g, b, radius] = [0.0, 0.0, 0.0, 0.0]
					r = if obj.r then obj.r else 0.4
					g = if obj.g then obj.g else 0.4
					b = if obj.b then obj.b else 0.0
					radius = if obj.radius then obj.radius else 3.0

					light = new Light(r, g, b, radius)
					light.setPosition(obj.cx, obj.cy)
					@lights.push(light)
				when 'path'
					@paths[obj.name] = new Path(obj.path)
				when 'man'
					man = new Ai(@state)
					man.setPosition(obj.cx, obj.cy)
					man.setPathPurpose(obj.path) if obj.path
					@ais.push(man)
				when 'level'
					@nextLevel = obj.name
					@nextArea0[0] = obj.tx
					@nextArea0[1] = obj.ty
					@nextArea1[0] = obj.tx + obj.w
					@nextArea1[1] = obj.ty + obj.h

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

	getNextArea: (ve) ->
		#console.log(ve, @nextArea0, @nextArea1)
		if (
			ve[0] > @nextArea0[0] and ve[1] > @nextArea0[1] and
			ve[0] < @nextArea1[0] and ve[1] < @nextArea1[1])
			return @nextLevel
		else
			return null

	frame: (ft) ->
		@time += ft*0.2
		#@timeOffsetX = Math.cos(@time)*0.1
		#@timeOffsetY = Math.sin(@time)*0.1

	setMvp: (mvp) ->
		@programColor.use()
		gl.uniformMatrix4fv(@unifColorMvp, false, mvp);
		@programEdge.use()
		gl.uniformMatrix4fv(@unifEdgeMvp, false, mvp);

	renderLight: (light) ->
		gl.enable(gl.STENCIL_TEST);

		gl.stencilMask(0xff);
		gl.clear(gl.STENCIL_BUFFER_BIT);

		gl.colorMask(false, false, false, false);
		gl.stencilFunc(gl.ALWAYS, 1, 0xff);
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		@renderEdges(light)

		gl.enable(gl.TEXTURE_2D)
		gl.colorMask(true, true, true, true);
		gl.stencilMask(0);
		gl.stencilFunc(gl.EQUAL, 0, 0xff);
		@renderColors(light)
		gl.disable(gl.TEXTURE_2D)

		gl.disable(gl.STENCIL_TEST);

	renderColors: (light) ->
		@programColor.use()

		gl.uniform1i(@unifColorTexture, 0)
		light.uniforms(
			@timeOffset[0], @timeOffset[1],
			@unifColorLightPos, @unifColorLightCol, @unifColorLightRad)

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

		light.uniforms(
			@timeOffset[0], @timeOffset[1],
			@unifEdgeLightPos, null)

		gl.bindBuffer(gl.ARRAY_BUFFER, @vbaEdge)
		gl.enableVertexAttribArray(0);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 4*4, 0);
		gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 4*4, 8);

		gl.drawArrays(gl.TRIANGLES, 0, @vbaEdgeCount);
		gl.disableVertexAttribArray(1);
		gl.disableVertexAttribArray(0);

	getMapLights: -> @lights

	isVisible: (ent, lights) ->
		#veEnt = esVec2_parse(ent.loc[0], ent.loc[1])

		for light in lights
			continue if (
				Math.abs(ent.loc[0] - light.loc[0]) > light.radius or
				Math.abs(ent.loc[1] - light.loc[1]) > light.radius)
			dx = ent.loc[0] - light.loc[0]
			dy = ent.loc[1] - light.loc[1]
			dist = Math.sqrt(dx*dx + dy*dy)

			continue if dist > light.radius

			shaded = false
			for wall in @walls
				shaded = true if wall.shadows(ent.loc, light.loc)

			return true if not shaded
		return false

	moveInWord: (veLoc, veDir, radius) ->
		veDst = esVec2_parse(
			veLoc[0] + veDir[0],
			veLoc[1] + veDir[1])

		hit = true
		for wall in @walls
			if wall.grind(veLoc, veDir, veDst, radius)
				veDir[0] = veDst[0] - veLoc[0]
				veDir[1] = veDst[1] - veLoc[1]

		veLoc[0] += veDir[0]
		veLoc[1] += veDir[1]

	canSee: (v0, v1) ->
		for wall in @walls
			return false if wall.intesects(v0, v1, 0.0)
		return true

	pushGridWall: (x, y, dx, dy) ->
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

		@plane = esVec3_parse(@n0[0], @n0[1], -(@n0[0]*@v0[0] + @n0[1]*@v0[1]))

		nS0 = esVec2_parse(-@n0[1], @n0[0])
		nS1 = esVec2_parse(-nS0[0], -nS0[1])
		@planeE0 = esVec3_parse(nS0[0], nS0[1], -(nS0[0]*@v0[0] + nS0[1]*@v0[1]))
		@planeE1 = esVec3_parse(nS1[0], nS1[1], -(nS1[0]*@v1[0] + nS1[1]*@v1[1]))

		@e0 = esVec2_create()
		@e1 = esVec2_create()
		@ne0 = esVec3_create()
		@ne1 = esVec3_create()

	vertsEdge: (arr) ->
		pushEdgeVert(arr, @v0[0], @v0[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v1[0], @v1[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v0[0], @v0[1], @n1[0], @n1[1])

		pushEdgeVert(arr, @v1[0], @v1[1], @n0[0], @n0[1])
		pushEdgeVert(arr, @v1[0], @v1[1], @n1[0], @n1[1])
		pushEdgeVert(arr, @v0[0], @v0[1], @n1[0], @n1[1])

	shadows: (veEnt, veLight) ->
		dotEnt = @plane[0]*veEnt[0] + @plane[1]*veEnt[1] + @plane[2]
		dotLight = @plane[0]*veLight[0] + @plane[1]*veLight[1] + @plane[2]

		return false if dotEnt*dotLight > 0.0

		esVec2_sub(@e0, @v0, veLight)
		esVec2_sub(@e1, @v1, veLight)

		@ne0[0] = @e0[1]
		@ne0[1] = -@e0[0]
		@ne0[2] = -(@ne0[0]*@v0[0] + @ne0[1]*@v0[1])

		@ne1[0] = @e1[1]
		@ne1[1] = -@e1[0]
		@ne1[2] = -(@ne1[0]*@v1[0] + @ne1[1]*@v1[1])

		dotE0 = @ne0[0]*veEnt[0] + @ne0[1]*veEnt[1] + @ne0[2]
		dotE1 = @ne1[0]*veEnt[0] + @ne1[1]*veEnt[1] + @ne1[2]

		if dotE0*dotE1 < 0.0
			return true

		return false

	grind: (veLoc, veDir, veDst, radius) ->
		dotDir = @plane[0]*veDir[0] + @plane[1]*veDir[1]
		return false if dotDir > 0.0

		dotLoc = @plane[0]*veLoc[0] + @plane[1]*veLoc[1] + @plane[2]
		return false if dotLoc < 0.0 or dotLoc > radius

		dotDst = @plane[0]*veDst[0] + @plane[1]*veDst[1] + @plane[2]
		return false if dotDst < 0.0 or dotDst > radius

		dotE0 = @planeE0[0]*veDst[0] + @planeE0[1]*veDst[1] + @planeE0[2]
		dotE1 = @planeE1[0]*veDst[0] + @planeE1[1]*veDst[1] + @planeE1[2]

		return false if dotE0 < -radius or dotE1 < -radius

		veDst[0] = veDst[0] + (radius - dotDst)*@plane[0]
		veDst[1] = veDst[1] + (radius - dotDst)*@plane[1]

		return true

	intesects: (v0, v1) ->
		dotV0 = @plane[0]*v0[0] + @plane[1]*v0[1] + @plane[2]
		dotV1 = @plane[0]*v1[0] + @plane[1]*v1[1] + @plane[2]

		return false if dotV0*dotV1 >= 0.0

		p = Math.abs(dotV0) / (Math.abs(dotV0) + Math.abs(dotV1))
		hit = esVec2_parse(
			p*(v1[0] - v0[0]) + v0[0],
			p*(v1[1] - v0[1]) + v0[1])

		dotE0 = @planeE0[0]*hit[0] + @planeE0[1]*hit[1] + @planeE0[2]
		dotE1 = @planeE1[0]*hit[0] + @planeE1[1]*hit[1] + @planeE1[2]
		return false if dotE0 < 0.0 or dotE1 < 0.0

		return true

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

class Pillar
	constructor: (@cx, @cy, @w, @h) ->

	vertsColor: (arr) ->
		u0 = UVS[TILE_NONE].u
		v0 = UVS[TILE_NONE].v
		u1 = u0 + UV_INC
		v1 = v0 + UV_INC
		pushColorVert(arr, @cx-@w	, @cy-@h	, u0, v0)
		pushColorVert(arr, @cx+@w	, @cy-@h	, u1, v0)
		pushColorVert(arr, @cx-@w	, @cy+@h	, u0, v1)

		pushColorVert(arr, @cx-@w	, @cy+@h	, u0, v1)
		pushColorVert(arr, @cx+@w	, @cy+@h	, u1, v1)
		pushColorVert(arr, @cx+@w	, @cy-@h	, u1, v0)

	pushWalls: (arr) ->
		v0 = esVec2_parse(@cx-@w, @cy-@h)
		v1 = esVec2_parse(@cx+@w, @cy-@h)
		v2 = esVec2_parse(@cx+@w, @cy+@h)
		v3 = esVec2_parse(@cx-@w, @cy+@h)
		arr.push(new Wall(v0, v1))
		arr.push(new Wall(v1, v2))
		arr.push(new Wall(v2, v3))
		arr.push(new Wall(v3, v0))

class Path
	constructor: (@path) ->
		console.log(@path)
		@index = 0

	iterate: ->
		ret = esVec2_parse(@path[@index][0], @path[@index][1])
		@index += 1
		@index = 0 if @index >= @path.length
		return ret

class Light
	constructor: (@r, @g, @b, @radius) ->
		@loc = esVec2_create()

	setPosition: (x, y) ->
		@loc[0] = x
		@loc[1] = y

	setColor: (@r, @g, @b) ->
	setRadius: (@radius) ->

	uniforms: (offsetX, offsetY, unifPos, unifCol, unifRad) ->
		x = @loc[0] + offsetX
		y = @loc[1] + offsetY
		gl.uniform2f(unifPos, x, y) if unifPos
		gl.uniform3f(unifCol, @r, @g, @b) if unifCol
		gl.uniform1f(unifRad, @radius) if unifRad

pushColorVert = (arr, x, y, u, v) -> pushVerts(arr, [x, y, u, v])
pushEdgeVert = (arr, x, y, nX, nY) -> pushVerts(arr, [x, y, nX, nY])

pushVerts = (arr, list) ->
	for field in list
		arr.push(field)
	return

