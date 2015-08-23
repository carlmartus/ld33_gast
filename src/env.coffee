ENT_RADIUS = 0.1
PLAYER_HUNGE_MIN = 0.2
PLAYER_HUNGE_MAX = 0.3
PLAYER_ACTION_CD = 0.4
AI_RANGE = 2.7

class Entity
	constructor: (@state) ->
		@loc = esVec2_create()
		@dir = esVec2_create()
		@resetStates()

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

class Ai extends Entity
	constructor: (state) ->
		@walkLoc = esVec2_create()
		@moveDir = esVec2_create()
		@actionZone = esVec2_create()
		super(state)

	frame: (ft) ->
		@consider -= ft
		if @consider <= 0.0
			return @state.busted() if @scared

			# Idle or path
			if @moving
				@moving = false
				@consider = 2.0 * (1 + Math.random())
			else
				if @pathName and false
					loc = @state.map.paths[@pathName].iterate()
					@walk(@loc[0], @loc[1])
				else
					@walk(
						@actionZone[0] + 0.6*Math.random() - 0.3,
						@actionZone[1] + 0.6*Math.random() - 0.3)

		if @scanning
			if @scanCd <= 0.0
				@scanCd = 0.2

				lookDir = esVec2_parse(
					@loc[0] - @state.player.loc[0],
					@loc[1] - @state.player.loc[1])
				dot = lookDir[0]*@moveDir[0] + lookDir[1]*@moveDir[1]
				range = esVec2_length(lookDir)
				if (
					@state.player.visible and
					dot < 0.0 and
					range < AI_RANGE and
					@state.map.canSee(@loc, @state.player.loc))
					return @panic(@state.player.loc[0], @state.player.loc[1])
			else
				@scanCd -= ft

		if @moving
			@lookV = Math.atan2(@moveDir[0], -@moveDir[1])
			@move(@moveDir[0]*ft*@moveSpeed, @moveDir[1]*ft*@moveSpeed)

	#walkPath: (path) ->
	setPathPurpose: (@pathName) ->

	render: ->
		@state.sprites.push(@loc[0], @loc[1], @lookV, ENT_RADIUS, SPRITE_MAN_IDLE)

	walk: (x, y) ->
		@walkLoc[0] = x
		@walkLoc[1] = y

		vec = esVec2_parse(@walkLoc[0] - @loc[0], @walkLoc[1] - @loc[1])
		@consider = esVec2_length(vec)
		esVec2_normalize(@moveDir, vec)
		@moving = true

	panic: (x, y) ->
		@walk(
			@loc[0] + (@loc[0] - x),
			@loc[1] + (@loc[1] - y))

		@lookV = 0.0
		@consider = 1.0
		@scared = true
		@scanning = false

		@moving = true
		@moveSpeed = 2.0

	settle: ->
		@actionZone[0] = @loc[0]
		@actionZone[1] = @loc[1]

	resetStates: ->
		@consider = 0.0
		@scanning = true
		@scanCd = 0.0
		@moving = false
		@moveSpeed = 0.2
		@scared = false
		@settle()

	setPosition: (x, y) ->
		super(x, y)
		@settle()

class Player extends Entity
	constructor: (state) ->
		super(state)
		@look = esVec2_parse(1, 0)

		@light = new Light(0, 1.0, 0, 1.0)
		@light.setColor(0, 0.25, 0)
		@light.setRadius(4.0)

	resetStates: ->
		@walkXP = false
		@walkXN = false
		@walkYP = false
		@walkYN = false
		@action = false

		@actionCd = 0.0

		@hunge = PLAYER_HUNGE_MIN
		@visible = false
		@spin = 0.0

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
		if @action and not @visible and @actionCd <= 0.0
			@actionCd = PLAYER_ACTION_CD

		if dx != 0.0 or dy != 0.0
			if @look[0]*dx + @look[1]*dy < -0.8
				@look[0] = dx
				@look[1] = dy
			else
				look = esVec2_parse(
					@look[0] + dx*ft*8.0,
					@look[1] + dy*ft*8.0)
				esVec2_normalize(@look, look)

		@move(dx*ft, dy*ft)

		@visible = @state.map.isVisible(@, @state.map.getMapLights())

		if @hunge > PLAYER_HUNGE_MIN
			@light.setPosition(@loc[0], @loc[1])
			@state.pushExtraLight(@light)

		if not @visible and @hunge < PLAYER_HUNGE_MAX
			@hunge += ft*0.1
			if @hunge > PLAYER_HUNGE_MAX then @hunge = PLAYER_HUNGE_MAX
			@updateLightColor()
		else if @visible and @hunge > PLAYER_HUNGE_MIN
			@hunge -= ft*0.2
			if @hunge < PLAYER_HUNGE_MIN then @hunge = PLAYER_HUNGE_MIN
			@updateLightColor()

	updateLightColor: ->
		@light.setColor(0.0, (@hunge-PLAYER_HUNGE_MIN)*1.5, 0.0)

	render: ->
		if not @visible
			@state.sprites.push(@loc[0], @loc[1], @spin, @hunge, SPRITE_YOU_AURA)
			@state.sprites.push(@loc[0], @loc[1], -@spin, @hunge, SPRITE_YOU_AURA)

		v = Math.atan2(@look[0], -@look[1])

		if @actionCd > 0.0 and not @visible
			scale = 0.8*(PLAYER_ACTION_CD - Math.abs(0.5*PLAYER_ACTION_CD - @actionCd))
			@state.sprites.push(
				@loc[0] + scale*@look[0],
				@loc[1] + scale*@look[1], v, scale, SPRITE_YOU_ARMS)

		@state.sprites.push(@loc[0], @loc[1], v, @hunge, SPRITE_YOU)

	makeMvp: (w, h) ->
		radius = 4.0 - @hunge * 8.0
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
	doAction:	(p) -> #@action = p

