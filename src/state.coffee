class State
	constructor: ->
		@lights = [new Light(0, 1, 1, 4.5), new Light(0.7, 0, 0, 4.3)]
		@lights[0].setPosition(1.8, 1.4)
		@lights[1].setPosition(1.8, 3.5)

		@player = new Player()
		@player.setPosition(0.5, 3.0)

	frame: (ft) ->
		@mvp = @player.makeMvp(@screen_w, @screen_h, 4.0)
		@map.frame(ft)

		@player.frame(ft)

	loadMap: (name) ->
		@map = new Map(name)

	render: ->
		@map.setMvp(@mvp)

		gl.enable(gl.BLEND)
		gl.blendFunc(gl.ONE, gl.ONE)
		for light in @lights
			@map.renderLight(light)
		gl.disable(gl.BLEND)

	setScreenSize: (w, h) ->
		@screen_w = w
		@screen_h = h

	inputUp:	(p) -> @player.moveUp(p)
	inputDown:	(p) -> @player.moveDown(p)
	inputRight:	(p) -> @player.moveRight(p)
	inputLeft:	(p) -> @player.moveLeft(p)

