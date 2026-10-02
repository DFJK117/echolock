package;

import openfl.display.Sprite;

class Crosshair extends Sprite {
	public var vx:Float;
	public var vy:Float;
	public var baseSpeed:Float;
	public var boostMultiplier:Float;

	private var trail:Array<{x:Float, y:Float}>;
	private var maxTrail:Int;
	public var boundsMin:Float;
	public var boundsMax:Float;

	public function new() {
		super();
		vx = 0;
		vy = 0;
		baseSpeed = 10;
		boostMultiplier = 2.6;
		trail = [];
		maxTrail = 30;
		boundsMin = 40;
		boundsMax = 1880;
	}

	public function setBounds(min:Float, max:Float):Void {
		boundsMin = min;
		boundsMax = max;
	}

	public function update(keys:KeyState):Void {
		var mult = keys.shift ? boostMultiplier : 1.0;
		var spd = baseSpeed * mult;

		var dx = 0.0;
		var dy = 0.0;
		if (keys.left) dx -= 1;
		if (keys.right) dx += 1;
		if (keys.up) dy -= 1;
		if (keys.down) dy += 1;

		if (dx != 0 && dy != 0) {
			dx *= 0.7071;
			dy *= 0.7071;
		}

		vx = dx * spd;
		vy = dy * spd;
		x += vx;
		y += vy;

		if (x < boundsMin) x = boundsMin;
		if (x > boundsMax) x = boundsMax;
		if (y < boundsMin) y = boundsMin;
		if (y > boundsMax) y = boundsMax;

		trail.push({x: x, y: y});
		if (trail.length > maxTrail) {
			trail.shift();
		}

		draw();
	}

	public function getMoving():Bool {
		return vx != 0 || vy != 0;
	}

	private function draw():Void {
		graphics.clear();

		// 拖尾
		for (i in 0...trail.length) {
			var t = trail[i];
			var progress = (i + 1) / trail.length;
			var alpha = progress * 0.35;
			var size = 6 + progress * 22;
			var ox = t.x - x;
			var oy = t.y - y;
			graphics.beginFill(0x00e5ff, alpha);
			graphics.drawCircle(ox, oy, size);
			graphics.endFill();
		}

		// 光标本体 - 放大一倍
		// 外发光
		graphics.lineStyle(14, 0x00e5ff, 0.12);
		graphics.drawCircle(0, 0, 40);

		// 外环
		graphics.lineStyle(4, 0x00e5ff, 0.95);
		graphics.drawCircle(0, 0, 34);

		// 内环
		graphics.lineStyle(1.5, 0x80f7ff, 0.5);
		graphics.drawCircle(0, 0, 18);

		// 十字
		graphics.lineStyle(2.5, 0x00e5ff, 0.8);
		graphics.moveTo(-50, 0);
		graphics.lineTo(-24, 0);
		graphics.moveTo(24, 0);
		graphics.lineTo(50, 0);
		graphics.moveTo(0, -50);
		graphics.lineTo(0, -24);
		graphics.moveTo(0, 24);
		graphics.lineTo(0, 50);

		// 中心点
		graphics.beginFill(0xffffff, 1);
		graphics.drawCircle(0, 0, 5);
		graphics.endFill();
	}
}
