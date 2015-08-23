ENT_RADIUS = 0.2

class Entity
	constructor: (@map) ->
		@loc = esVec2_create()
		@dir = esVec2_create()

	setPosition: (x, y) ->
		@loc[0] = x
		@loc[1] = y

	move: (dx, dy) ->
		@dir[0] = dx
		@dir[1] = dy
		@map.moveInWord(@loc, @dir, ENT_RADIUS)

	render: -> console.log('Unimplemented', @)
	frame: (ft) -> console.log('Unimplemented', @)
	resetStates: -> console.log('Unimplemented', @)

class Player extends Entity
	constructor: (map) ->
		super(map)
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

		@move(dx*ft, dy*ft)

	makeMvp: (w, h, radius) ->
		mat = esMat4_create()
		ratio = w / h

		x0 = @loc[0] - ratio*radius
		x1 = @loc[0] + ratio*radius
		y0 = @loc[1] + radius
		y1 = @loc[1] - radius
		esMat4_ortho(mat, x0, y0, x1 ,y1)
		return mat

	moveUp:		(p) -> @walkYN = p
	moveDown:	(p) -> @walkYP = p
	moveLeft:	(p) -> @walkXN = p
	moveRight:	(p) -> @walkXP = p

