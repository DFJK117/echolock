package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class SignalPoint extends Sprite {
	public var hitTime:Int;
	public var keyIndex:Int;
	public var lit:Bool;
	public var active:Bool;
	public var distFromCenter:Float;

	static final KEY_COLORS = [0x4fc3f7, 0x81c784, 0xffd54f, 0xe57373];
	static final KEY_LABELS = ["D", "F", "J", "K"];

	private var label:TextField;
	private var currentTime:Int;
	private var baseRadius:Float;

	public function new(x:Float, y:Float, keyIndex:Int, hitTime:Int, distFromCenter:Float) {
		super();
		this.x = x;
		this.y = y;
		this.keyIndex = keyIndex;
		this.hitTime = hitTime;
		this.distFromCenter = distFromCenter;
		this.lit = false;
		this.active = true;
		this.baseRadius = 22;
		this.currentTime = 0;

		label = new TextField();
		label.width = 44;
		label.height = 30;
		label.x = -22;
		label.y = -15;
		label.selectable = false;
		var fmt = new TextFormat("Consolas", 20, 0xffffff, true);
		fmt.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = fmt;
		label.text = KEY_LABELS[keyIndex];
		addChild(label);
	}

	public function update(currentTime:Int):Void {
		this.currentTime = currentTime;
		draw();
	}

	private function draw():Void {
		graphics.clear();
		var color = KEY_COLORS[keyIndex];

		if (!lit) {
			graphics.lineStyle(1.5, color, 0.18);
			graphics.drawCircle(0, 0, baseRadius);
			label.alpha = 0.12;
		} else {
			var pulse = 1 + 0.18 * Math.sin(currentTime * 0.025);
			var r = baseRadius * pulse;

			graphics.lineStyle(14, color, 0.12);
			graphics.drawCircle(0, 0, r + 8);
			graphics.lineStyle(7, color, 0.25);
			graphics.drawCircle(0, 0, r + 3);

			graphics.beginFill(color, 0.88);
			graphics.drawCircle(0, 0, r);
			graphics.endFill();

			graphics.lineStyle(2, 0xffffff, 0.55);
			graphics.drawCircle(0, 0, r * 0.58);

			label.alpha = 1;
		}
	}
}
