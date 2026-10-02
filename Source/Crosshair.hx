package;

import openfl.display.Sprite;

class Crosshair extends Sprite {
	public var vx:Float;
	public var vy:Float;
	public var baseSpeed:Float;
	public var boostMultiplier:Float;

	private var trail:Array<{x:Float, y:Float}>;
	private var maxTrail:Int;
	private var boundsMin:Float;
	private var boundsMax:Float;

	public function new() {
		super();
		vx = 0;
		vy = 0;
		baseSpeed = 7;
		boostMultiplier = 2.6;
		trail = [];
		maxTrail = 24;
		boundsMin = 24;
		boundsMax = 936;
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

		// 对角线归一化
		if (dx != 0 && dy != 0) {
			dx *= 0.7071;
			dy *= 0.7071;
		}

		vx = dx * spd;
		vy = dy * spd;
		x += vx;
		y += vy;

		// 边界
		if (x < boundsMin) x = boundsMin;
		if (x > boundsMax) x = boundsMax;
		if (y < boundsMin) y = boundsMin;
		if (y > boundsMax) y = boundsMax;

		// 记录拖尾
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

		// === 拖尾（OSU 式渐变尾巴）===
		for (i in 0...trail.length) {
			var t = trail[i];
			var progress = (i + 1) / trail.length; // 0(旧) -> 1(新)
			var alpha = progress * 0.32;
			var size = 3 + progress * 11;
			// 拖尾点相对当前光标的偏移
			var ox = t.x - x;
			var oy = t.y - y;
			graphics.beginFill(0x00e5ff, alpha);
			graphics.drawCircle(ox, oy, size);
			graphics.endFill();
		}

		// === 光标本体 ===
		// 外发光
		graphics.lineStyle(10, 0x00e5ff, 0.12);
		graphics.drawCircle(0, 0, 20);

		// 外环
		graphics.lineStyle(2.5, 0x00e5ff, 0.95);
		graphics.drawCircle(0, 0, 17);

		// 内环
		graphics.lineStyle(1, 0x80f7ff, 0.5);
		graphics.drawCircle(0, 0, 9);

		// 十字
		graphics.lineStyle(1.5, 0x00e5ff, 0.8);
		graphics.moveTo(-26, 0);
		graphics.lineTo(-12, 0);
		graphics.moveTo(12, 0);
		graphics.lineTo(26, 0);
		graphics.moveTo(0, -26);
		graphics.lineTo(0, -12);
		graphics.moveTo(0, 12);
		graphics.lineTo(0, 26);

		// 中心点
		graphics.beginFill(0xffffff, 1);
		graphics.drawCircle(0, 0, 2.5);
		graphics.endFill();
	}
}
