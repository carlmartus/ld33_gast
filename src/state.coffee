class State
	constructor: ->
		@map = new Map()
		@sprites = new SpriteLib()
		@sprites.create()

	frame: (ft) =>
		@mvp = @player.makeMvp(@screen_w, @screen_h, 4.0)
		@map.frame(ft)

		@player.frame(ft)
		@playerLight.setPosition(@player.loc[0], @player.loc[1])

		if @map.isVisible(@player, @map.getMapLights())
			@playerLight.setColor(1, 0, 0)
			@playerLight.setRadius(0.1)
		else
			@playerLight.setColor(0, 0.4, 0)
			@playerLight.setRadius(4.0)

	loadMap: (name) =>
		@map.loadMap(name)
		@player = new Player(@map, @sprites)
		@player.setPosition(@map.playerStart[0], @map.playerStart[1])

		@playerLight = new Light(0, 1.0, 0, 1.0)

	render: =>
		@map.setMvp(@mvp)

		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)
		for light in @map.getMapLights()
			@map.renderLight(light)
		@map.renderLight(@playerLight)
		gl.disable(gl.BLEND)

		@player.render()

		@sprites.setMvp(@mvp)
		@sprites.copy()
		@sprites.render()

	setScreenSize: (w, h) ->
		@screen_w = w
		@screen_h = h

	inputUp:	(p) -> @player.moveUp(p)
	inputDown:	(p) -> @player.moveDown(p)
	inputRight:	(p) -> @player.moveRight(p)
	inputLeft:	(p) -> @player.moveLeft(p)

