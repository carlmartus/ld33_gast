gl = null
window.blockRender = false

class Ld33
	constructor: ->
		gl = esInitGl('gastvas', { antialias: false })
		@w = 400
		@h = 300
		#@mat = @makeMvp()
		esFullFrame('gastvas', (@w, @h) =>
			gl.viewport(0, 0, @w, @h)
		)

		window.addEventListener('blur', -> window.blockRender = true)
		window.addEventListener('focus', -> window.blockRender = false)


		load = new esLoad()
		@tex0 = load.loadTexture(gl, 'tex.png', gl.NEAREST, gl.LINEAR);
		load.downloadWithGlScreen(gl, @downloaded);

	frame: (ft) =>
		return if window.blockRender || ft > 0.3

		gl.clearColor(0.0, 0.0, 0.0, 1.0)
		gl.clear(gl.COLOR_BUFFER_BIT);

	downloaded: =>
		esNextFrame(@frame);

	#makeMvp: -> esMat4_ortho(


main = ->
	console.log(LEVELS)
	new Ld33

document.ld33 = main

