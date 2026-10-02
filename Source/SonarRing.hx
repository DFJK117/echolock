package;

import openfl.display.Sprite;

class SonarRing extends Sprite {
	public var spawnTime:Int;
	public var radius:Float;
	public var maxRadius:Float;
	public var ringSpeed:Float; // px per ms

	public function new(spawnTime:Int, maxRadius:Float, ringSpeed:Float) {
		super();
		this.spawnTime = spawnTime;
		this.maxRadius = maxRadius;
		this.ringSpeed = ringSpeed;
		this.radius = 0;
	}

	public function update(currentTime:Int):Void {
		var elapsed = currentTime - spawnTime;
		radius = ringSpeed * elapsed;
		draw();
	}

	public var alive(get, null):Bool;
	function get_alive():Bool {
		return radius < maxRadius + 60;
	}

	function draw():Void {
		graphics.clear();
		if (radius <= 0) return;

		var fade = 1 - radius / (maxRadius + 60);
		if (fade < 0) fade = 0;

		// 主环
		graphics.lineStyle(3, 0x4dd0e1, fade * 0.9);
		graphics.drawCircle(0, 0, radius);

		// 外环光晕
		graphics.lineStyle(8, 0x4dd0e1, fade * 0.15);
		graphics.drawCircle(0, 0, radius);

		// 内环拖尾
		if (radius > 15) {
			graphics.lineStyle(1.5, 0x80deea, fade * 0.4);
			graphics.drawCircle(0, 0, radius - 12);
		}
	}
}
