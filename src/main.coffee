gl = null
window.blockRender = false

frame = (ft) ->
	return if window.blockRender || ft > 0.3

	gl.clearColor(0.0, 0.0, 0.0, 1.0)
	gl.clear(gl.COLOR_BUFFER_BIT);

main = ->
	gl = esInitGl('gastvas', { antialias: false })
	esFullFrame('gastvas', (w, h) ->
		gl.viewport(0, 0, w, h)
	)

	window.addEventListener('blur', -> window.blockRender = true)
	window.addEventListener('focus', -> window.blockRender = false)

	esNextFrame(frame);

document.ld33 = main

