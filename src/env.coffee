class Entity
	constructor: ->
		@x = 0.0
		@y = 0.0

	setPosition: (@x, @y) ->

	render: -> console.log('Unimplemented', @)
	frame: (ft) -> console.log('Unimplemented', @)

class Player:
	constructor: (@x, @y) ->
		;

