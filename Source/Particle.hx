package;

import openfl.display.Sprite;

class Particle extends Sprite {
	public var vx:Float;
	public var vy:Float;
	public var life:Int;
	public var maxLife:Int;
	public var color:Int;

	public function new(x:Float, y:Float, color:Int) {
		super();
		this.x = x;
		this.y = y;
		this.color = color;
		this.maxLife = 40 + Std.random(20);
		this.life = maxLife;

		var angle = Math.random() * Math.PI * 2;
		var speed = 2 + Math.random() * 5;
		vx = Math.cos(angle) * speed;
		vy = Math.sin(angle) * speed;
	}

	public function update():Void {
		x += vx;
		y += vy;
		vx *= 0.96;
		vy *= 0.96;
		life--;
		draw();
	}

	function draw():Void {
		graphics.clear();
		var alpha = life / maxLife;
		var size = 3 * alpha + 1;
		graphics.beginFill(color, alpha);
		graphics.drawCircle(0, 0, size);
		graphics.endFill();
	}
}
