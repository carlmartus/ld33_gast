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
		@walkXP = false
		@walkXN = false
		@walkYP = false
		@walkYN = false

	frame: (ft) ->
		dx = 0.0
		dy = 0.0
		dx += 1.0 if @walkXP
		dx -= 1.0 if @walkXN
		dy += 1.0 if @walkYP
		dy -= 1.0 if @walkYN

		@x += dx*ft
		@y += dy*ft

	makeMvp: (w, h, radius) ->
		mat = esMat4_create()
		ratio = w / h

		x0 = @x - ratio*radius
		x1 = @x + ratio*radius
		y0 = @y + radius
		y1 = @y - radius
		esMat4_ortho(mat, x0, y0, x1 ,y1)
		return mat

	moveUp:		(p) -> @walkYN = p
	moveDown:	(p) -> @walkYP = p
	moveLeft:	(p) -> @walkXN = p
	moveRight:	(p) -> @walkXP = p

