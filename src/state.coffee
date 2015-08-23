class State
	constructor: ->
		@map = new Map()

	frame: (ft) =>
		@mvp = @player.makeMvp(@screen_w, @screen_h, 4.0)
		@map.frame(ft)

		@player.frame(ft)
		@playerLight.setPosition(@player.x, @player.y)

		if @map.isVisible(@player, @lights)
			@playerLight.setColor(1, 0, 0)
		else
			@playerLight.setColor(0, 1, 0)

	loadMap: (name) =>
		@map.loadMap(name)
		@player = new Player(@map)
		@player.setPosition(@map.playerStart[0], @map.playerStart[1])
		@lights = [new Light(0.3, 0.3, 0, 3.0)]
		#@lights = [new Light(0.3, 0.3, 0, 3.0), new Light(0.3, 0.3, 0, 3.0)]
		@lights[0].setPosition(1.8, 1.4)
		#@lights[1].setPosition(1.8, 3.5)

		@playerLight = new Light(0, 1.0, 0, 0.4)

	render: =>
		@map.setMvp(@mvp)

		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)
		for light in @lights
			@map.renderLight(light)
		@map.renderLight(@playerLight)
		gl.disable(gl.BLEND)

	setScreenSize: (w, h) ->
		@screen_w = w
		@screen_h = h

	inputUp:	(p) -> @player.moveUp(p)
	inputDown:	(p) -> @player.moveDown(p)
	inputRight:	(p) -> @player.moveRight(p)
	inputLeft:	(p) -> @player.moveLeft(p)

