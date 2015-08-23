class State
	constructor: ->
		@map = new Map(@)
		@sprites = new SpriteLib()
		@sprites.create()
		@extraLights = []

	frame: (ft) =>
		@mvp = @player.makeMvp(@screen_w, @screen_h, 2.0)
		@map.frame(ft)

		@player.frame(ft)
		for ai in @map.ais
			ai.frame(ft)

	loadMap: (name) =>
		@mapName = name
		@map.loadMap(name)
		@player = new Player(@)
		@player.setPosition(@map.playerStart[0], @map.playerStart[1])

	render: =>
		@map.setMvp(@mvp)

		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)

		for light in @map.getMapLights()
			@map.renderLight(light)
		for light in @extraLights
			@map.renderLight(light)

		gl.disable(gl.BLEND)

		for ai in @map.ais
			ai.render()
		@player.render()

		@sprites.setMvp(@mvp)
		@sprites.copy()
		@sprites.render()

		@extraLights.length = 0

	busted: ->
		@loadMap(@mapName)

	setScreenSize: (w, h) ->
		@screen_w = w
		@screen_h = h

	pushExtraLight: (light) ->
		@extraLights.push(light)

	inputUp:		(p) -> @player.moveUp(p)
	inputDown:		(p) -> @player.moveDown(p)
	inputRight:		(p) -> @player.moveRight(p)
	inputLeft:		(p) -> @player.moveLeft(p)
	inputAction:	(p) -> @player.doAction(p)

