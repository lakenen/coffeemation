# CoffeeMation

A Coffeescript animation library for easily creating complex, customizable animations.

[Demo](http://lakenen.com/coffeemation)


## How to use

You can use Animation.Transform if you just want to animate properties on an object:

```coffeescript
ball
	size: 1
	velocity:
		x: 0
		y: 0

animation = new CoffeeMation.Transform ball,
	to:
		size: 10
		velocity:
			x: 100
			y: 100
	duration: 2.0
	delay: 1.0
	transition: CoffeeMation.Transitions.Exponential.EaseIn
	onFinish: -> alert 'done!'

```

You can also extend Animation to animate anything you like! 
For example, the following code creates an animation that will rotate and move an HTML element on a page:

```coffeescript
# defining the new animation class
class RotateCoffeeMation extends CoffeeMation
	oldX = oldY = oldA = 0
	constructor: (elt, options) ->
		super options
		transform = getTransform elt
		oldX = transform[4]
		oldY = transform[5]
		oldA = getRotationDegrees transform
	render: (pos) ->
		newX = ((@options.x - oldX) * pos + oldX).toFixed 8
		newY = ((@options.y - oldY) * pos + oldY).toFixed 8
		newA = ((@options.a - oldA) * pos + oldA).toFixed 8
		setTransform elt, newX, newY, newA

# some helper functions
getRotationDegrees = (transform) ->
	a = transform[0]
	b = transform[1]
	rad = Math.atan2 b, a
	deg = 180 * rad / Math.PI
	if deg < 0
		deg += 360
	return deg

vendors = ['webkit', 'moz', 'ms', 'o']
setTransform = (element, x, y, a) ->
	for v in vendors
		element.style['-'+v+'-transform'] = 'translate('+x+'px, '+y+'px) rotate('+a+'deg)'

getTransform = (element) ->
	style = window.getComputedStyle element
	str = ''

	for(var x = 0; x < vendors.length && !str; ++x)
		str = style['-'+vendors[x]+'-transform'];
		if str?
			break

	if (!str || str == 'none')
		return [0,0,0,0,0,0];

	var splits = str.substr(7).split(',');
	for (x = 0; x < splits.length; ++x)
		splits[x] = parseFloat(splits[x]);
	return splits

// let's try it!
var animation = new MyAnimation(document.getElementById('square'), {
	x: 400,
	y: 200,
	a: 45, //degrees
	duration: 0.5
});

```

## API Docs

### Extending

When extending Animation, you need to pass in a constructor function. 
The constructor must call this._super(options), and must return an object with at least one property: update, 
which is a function that takes a position (ratio complete) parameter and applies that to animate whatever you want to animate.

Here's a very basic example.

```js
# defining the new animation class
class MoveCoffeeMation extends CoffeeMation
	constructor: (@element, options) ->
		super options

	render: (pos) ->
		@element.style.left = ((@options.to - @options.from) * pos + @options.from) + 'px';
```

### Animating

When you want to use this new animation, you can create new instances of it.

```js
var element = document.getElementById('example');
element.style.position = 'absolute';
var anim = new MoveX(element, {
	from: 0,
	to: 500,
	duration: 3,
	transition: Animation.Transitions.Elastic.EaseIn,
	onFinish: function () {
		alert('finished!');
	},
	onStop: function () {
		alert('stopped!');
	}
});

// stop the animation where it is (calls options.onStop if exists)
anim.cancel();

// complete the animation now--jump to the last frame (calls options.onFinish and options.onStop)
anim.finish();

// also available
Animation.cancelAll();
Animation.finishAll();
```

## Coming soon...

Tests and more examples!

## License 

(The MIT License)

Copyright 2012 Cameron Lakenen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
