# some helpers 
extend = (object, properties) ->
	for key, val of properties
		object[key] = val
	object

merge = (options, overrides) ->
	extend (extend {}, options), overrides

delay = (ms, fn) -> setTimeout fn, ms
defer = (fn) -> delay 10, fn

# (request|cancel)AnimationFrame shim
do () ->
	lastTime = 0
	vendors = ['ms', 'moz', 'webkit', 'o']

	@cancelAnimationFrame or= @cancelRequestAnimationFrame

	unless @requestAnimationFrame
		for vendor in vendors
			@requestAnimationFrame or= @[vendor+'RequestAnimationFrame']
			@cancelAnimationFrame = @cancelRequestAnimationFrame or= @[vendor+'CancelRequestAnimationFrame']
	  
	unless @requestAnimationFrame
		@requestAnimationFrame = (callback, element) ->
			currTime = new Date().getTime()
			timeToCall = Math.max 0, 16 - (currTime - lastTime)
			id = @setTimeout (-> callback currTime + timeToCall), timeToCall
			lastTime = currTime + timeToCall
			id

	unless @cancelAnimationFrame
		@cancelAnimationFrame = @cancelRequestAnimationFrame = (id) -> clearTimeout id

animations = []
frameId = null

buildTransition = (easeOut, name) ->
	easeIn = (p) -> 1 - easeOut 1 - p
	easeOut.Name = name + '.EaseOut'
	easeIn.Name = name + '.EaseIn'
	transition = extend easeOut,
					EaseOut: easeOut
					EaseIn: easeIn

add = (animation) ->
	animations.push animation
	start()

remove = (animation) ->
	for anim, i in animations
		if anim == animation
			animations.splice i, 1
			break
	if animations.length == 0
		stop()

start = () ->
	if not frameId
		runLoop()

stop = () ->
	cancelAnimationFrame frameId
	frameId = null

runLoop = () ->
	frameId = requestAnimationFrame runLoop
	for animation in animations
		animation?._update? new Date().getTime()

CoffeeMation = 
	# statics
	defaults:
		duration: 1.0
		delay: 0
		fps: 100

	Transitions:
		_all: []
		random: () -> 
			all = CoffeeMation.Transitions._all
			transition = all[Math.floor(Math.random() * all.length)]
			return transition

		add: (transitions) ->
			for own name, transition of transitions
				do (transition, name) ->
					CoffeeMation.Transitions[name] = buildTransition transition, name
					CoffeeMation.Transitions._all.push CoffeeMation.Transitions[name]

	animations: () -> animations

	cancelAll: () ->
		for animation in animations
			animation?.cancel?()
		animations = []
		stop()

	finishAll: () ->
		for animation in animations
			animation?.finish?()

CoffeeMation.Transitions.add
	#each of these are the easeOut (default) versions of the transition
	Back: (p) ->
		s = 1.70158
		return (p -= 1) * p * ((s + 1) * p + s) + 1

	Bounce: (p) ->
		a = 7.5625
		d = 2.75
		if p < 1 / d
			return a * p * p
		else if p < 2 / d
			return a * (p -= 1.5 / d) * p + 0.75
		else if p < 2.5 / d
			return a * (p -= 2.25 / d) * p + 0.9375
		else
			return a * (p -= 2.625 / d) * p + 0.984375

	Elastic: (p) -> 1 - Math.cos(p * 4.5 * Math.PI) * Math.exp(-p * 6)

	Exponential: (p) -> if p == 1 then p else 1 - Math.pow 2, -10 * p
	
	Linear: (p) -> p

	Sine: (p) -> Math.sin(p * Math.PI / 2)

CoffeeMation.defaults.transition = CoffeeMation.Transitions.Exponential

class CoffeeMation.Base
	starts = duration = ends = currentFrame = totalFrames = position = onstartCalled = undefined

	# publics
	constructor: (options) ->
		@options		= merge CoffeeMation.defaults, options
		starts			= new Date().getTime()
		duration		= @options.duration * 1000
		ends			= starts + duration
		currentFrame	= 0
		totalFrames		= @options.duration * @options.fps
		position		= 0

		defer => add @

	_update: (time) ->
		if time >= starts
			if not onstartCalled
				@options.onStart?()
			if time >= ends
				@_render 1
				@cancel()
				@options.onFinish?()
				return
			pos = (time - starts) / duration
			frame = Math.round pos * totalFrames
			if frame > currentFrame
				@_render pos
				currentFrame = frame

	_render: (pos) ->
		position = @options.transition?(pos) or 0
		if @render?
			@options.onBeforeUpdate?()
			@render position 
			@options.onAfterUpdate?()
			@options.onUpdate?()
		else
			@cancel?()

	render: () -> throw 'CoffeeMation.Base must be extended, and ::render() must be defined!'

	cancel: () ->
		@options.onStop?()
		remove(@)

	finish: () -> @_update?(ends)

	finished: () -> currentFrame >= totalFrames

class CoffeeMation.Transform extends CoffeeMation.Base
	doRender = (obj, from, to, pos) ->
		for own attr of to
			if typeof to[attr] == 'object' and typeof from[attr] == 'object'
				doRender obj[attr], from[attr], to[attr], pos
			else if typeof to[attr] == 'number'
				obj[attr] = (to[attr] - from[attr]) * pos + from[attr]

	constructor: (object, options) ->
		super options
		@object = object
		@options.from = @options.from and merge(object, @options.from) or extend {}, object
		@options.to = @options.to or {}

	render: (pos) -> doRender @object, @options.from, @options.to, pos


@CoffeeMation = extend CoffeeMation.Base, CoffeeMation