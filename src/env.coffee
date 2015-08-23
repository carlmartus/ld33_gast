ENT_RADIUS = 0.2
PLAYER_HUNGE_MIN = 0.2
PLAYER_HUNGE_MAX = 0.3
PLAYER_ACTION_CD = 0.8

class Entity
	constructor: (@state) ->
		@loc = esVec2_create()
		@dir = esVec2_create()

	setPosition: (x, y) ->
		@loc[0] = x
		@loc[1] = y

	move: (dx, dy) ->
		@dir[0] = dx
		@dir[1] = dy
		@state.map.moveInWord(@loc, @dir, ENT_RADIUS)

	render: -> console.log('Unimplemented', @)
	frame: (ft) -> console.log('Unimplemented', @)
	resetStates: -> console.log('Unimplemented', @)

class Player extends Entity
	constructor: (state) ->
		super(state)
		@ent = new Entity()
		@walkXP = false
		@walkXN = false
		@walkYP = false
		@walkYN = false
		@action = false
		@look = esVec2_parse(1, 0)

		@actionCd = 0.0

		@hunge = PLAYER_HUNGE_MIN
		@visible = false
		@spin = 0.0

		@light = new Light(0, 1.0, 0, 1.0)
		@light.setColor(0, 0.25, 0)
		@light.setRadius(4.0)

	frame: (ft) ->
		@spin += ft

		dx = 0.0
		dy = 0.0
		dx += 1.0 if @walkXP
		dx -= 1.0 if @walkXN
		dy += 1.0 if @walkYP
		dy -= 1.0 if @walkYN

		if @actionCd > 0.0
			@actionCd -= ft
		if @action and @actionCd <= 0.0
			console.log('Action')
			@actionCd = PLAYER_ACTION_CD


		if dx != 0.0 or dy != 0.0
			if @look[0]*dx + @look[1]*dy < -0.5
				@look[0] = dx
				@look[1] = dy
			else
				look = esVec2_parse(
					@look[0] + dx*ft*4.0,
					@look[1] + dy*ft*4.0)
				esVec2_normalize(@look, look)

		@move(dx*ft, dy*ft)

		@visible = @state.map.isVisible(@, @state.map.getMapLights())

		if not @visible
			@light.setPosition(@loc[0], @loc[1])
			@state.pushExtraLight(@light)

		if not @visible and @hunge < PLAYER_HUNGE_MAX
			@hunge += ft*0.1
			if @hunge > PLAYER_HUNGE_MAX then @hunge = PLAYER_HUNGE_MAX
		else if @visible and @hunge > PLAYER_HUNGE_MIN
			@hunge -= ft*0.2
			if @hunge < PLAYER_HUNGE_MIN then @hunge = PLAYER_HUNGE_MIN

	render: ->
		if not @visible
			@state.sprites.push(@loc[0], @loc[1], @spin, @hunge, SPRITE_YOU_AURA)
			@state.sprites.push(@loc[0], @loc[1], -@spin, @hunge, SPRITE_YOU_AURA)
		@state.sprites.push(@loc[0], @loc[1], Math.atan2(@look[0], -@look[1]), @hunge, SPRITE_YOU)

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
	doAction:	(p) -> @action = p

