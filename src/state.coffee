class State
	constructor: ->
		@player = new Player()

	frame: (ft) ->
		@mvp = @player.makeMvp(@screen_w, @screen_h, 2.0)

	loadMap: (name) ->
		@map = new Map(name)

	render: ->
		@map.render(@mvp)

	setScreenSize: (w, h) ->
		@screen_w = w
		@screen_h = h

