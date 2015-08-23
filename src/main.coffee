gl = null
window.blockRender = false

class Ld33
	constructor: ->
		gl = esInitGl('gastvas', { antialias: false, stencil: true })
		@w = 400
		@h = 300

		@state = new State()
		@state.setScreenSize(@w, @h)
		@state.loadMap('l0')

		esFullFrame('gastvas', (@w, @h) =>
			gl.viewport(0, 0, @w, @h)
			@state.setScreenSize(@w, @h)
		)

		window.addEventListener('blur', -> window.blockRender = true)
		window.addEventListener('focus', -> window.blockRender = false)

		document.addEventListener('keydown', (event) => @key(event, true))
		document.addEventListener('keyup', (event) => @key(event, false))

		load = new esLoad()
		@tex0 = load.loadTexture(gl, 'tex.png', gl.NEAREST, gl.NEAREST);
		gl.bindTexture(gl.TEXTURE_2D, @tex0)
		load.downloadWithGlScreen(gl, @downloaded);

	frame: (ft) =>
		return if window.blockRender or ft > 0.3

		@state.frame(ft)

		gl.stencilMask(0xff);
		gl.clearStencil(0)
		gl.clearColor(0.0, 0.0, 0.0, 1.0)
		gl.clear(gl.COLOR_BUFFER_BIT);

		@state.render()

	downloaded: =>
		esNextFrame(@frame);

	key: (event, p) ->
		switch (event.keyCode)
			when 37 then @state.inputLeft(p)
			when 38 then @state.inputUp(p)
			when 39 then @state.inputRight(p)
			when 40 then @state.inputDown(p)
			else console.log(event.keyCode)

main = -> new Ld33

document.ld33 = main

