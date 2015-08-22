class Entity
	constructor: ->
		@x = 0.0
		@y = 0.0

	setPosition: (@x, @y) ->

	move: (@dx, @dy) ->

	render: -> console.log('Unimplemented', @)
	frame: (ft) -> console.log('Unimplemented', @)
	resetStates: -> console.log('Unimplemented', @)

class Player extends Entity
	constructor: ->
		super()
		@ent = new Entity()

	makeMvp: (w, h, radius) ->
		mat = esMat4_create()
		ratio = w / h

		x0 = @x - ratio*radius
		x1 = @x + ratio*radius
		y0 = @y + radius
		y1 = @y - radius
		esMat4_ortho(mat, x0, y0, x1 ,y1)
		return mat

