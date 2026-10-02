package;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.events.TouchEvent;

private class VirtualButton extends Sprite {
	public var action:String;
	public var pressed:Bool;
	public var radius:Float;
	private var label:TextField;

	public function new(x:Float, y:Float, radius:Float, text:String, action:String) {
		super();
		this.x = x;
		this.y = y;
		this.radius = radius;
		this.action = action;
		this.pressed = false;

		label = new TextField();
		label.width = radius * 2;
		label.height = radius;
		label.x = -radius;
		label.y = -radius / 2 - 10;
		label.selectable = false;
		var fmt = new TextFormat("Consolas", 32, 0xffffff, true);
		fmt.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = fmt;
		label.text = text;
		addChild(label);
		draw();
	}

	public function draw():Void {
		graphics.clear();
		var alpha = pressed ? 0.55 : 0.22;
		graphics.beginFill(0x00e5ff, alpha);
		graphics.drawCircle(0, 0, radius);
		graphics.endFill();
		graphics.lineStyle(3, 0x00e5ff, pressed ? 0.9 : 0.5);
		graphics.drawCircle(0, 0, radius);
	}
}

class VirtualControls extends Sprite {
	public var keys:KeyState;
	public var nDown:Bool;
	public var mDown:Bool;
	private var buttons:Array<VirtualButton>;
	private var activeTouches:Map<Int, VirtualButton>;

	public function new() {
		super();
		keys = new KeyState();
		nDown = false;
		mDown = false;
		buttons = [];
		activeTouches = new Map();
		createControls();
		addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
		addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
	}

	private function createControls():Void {
		// 左侧方向键 - 放大
		var cx = 180;
		var cy = 820;
		var r = 80;
		buttons.push(new VirtualButton(cx, cy - r - 20, r, "↑", "up"));
		buttons.push(new VirtualButton(cx, cy + r + 20, r, "↓", "down"));
		buttons.push(new VirtualButton(cx - r - 20, cy, r, "←", "left"));
		buttons.push(new VirtualButton(cx + r + 20, cy, r, "→", "right"));

		// 右侧 N / M 大键
		buttons.push(new VirtualButton(1550, 850, 100, "N", "n"));
		buttons.push(new VirtualButton(1750, 850, 100, "M", "m"));

		// Shift 加速键
		buttons.push(new VirtualButton(1400, 650, 65, "SHIFT", "shift"));

		for (b in buttons) addChild(b);
	}

	private function findButton(x:Float, y:Float):VirtualButton {
		for (b in buttons) {
			var dx = x - b.x;
			var dy = y - b.y;
			if (dx * dx + dy * dy <= b.radius * b.radius) return b;
		}
		return null;
	}

	private function setButton(b:VirtualButton, pressed:Bool):Void {
		if (b == null) return;
		b.pressed = pressed;
		b.draw();
		switch (b.action) {
			case "up": keys.up = pressed;
			case "down": keys.down = pressed;
			case "left": keys.left = pressed;
			case "right": keys.right = pressed;
			case "shift": keys.shift = pressed;
			case "n": nDown = pressed;
			case "m": mDown = pressed;
		}
	}

	private function onTouchBegin(e:TouchEvent):Void {
		var b = findButton(e.localX, e.localY);
		if (b != null) {
			activeTouches.set(e.touchPointID, b);
			setButton(b, true);
		}
	}

	private function onTouchMove(e:TouchEvent):Void {
		var prev = activeTouches.get(e.touchPointID);
		var curr = findButton(e.localX, e.localY);
		if (prev != curr) {
			setButton(prev, false);
			if (curr != null) {
				activeTouches.set(e.touchPointID, curr);
				setButton(curr, true);
			} else {
				activeTouches.remove(e.touchPointID);
			}
		}
	}

	private function onTouchEnd(e:TouchEvent):Void {
		var b = activeTouches.get(e.touchPointID);
		if (b != null) {
			setButton(b, false);
			activeTouches.remove(e.touchPointID);
		}
	}
}
