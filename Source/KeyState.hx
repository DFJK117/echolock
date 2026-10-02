package;

class KeyState {
	public var up:Bool;
	public var down:Bool;
	public var left:Bool;
	public var right:Bool;
	public var shift:Bool;

	public function new() {
		up = false;
		down = false;
		left = false;
		right = false;
		shift = false;
	}

	public function reset():Void {
		up = false;
		down = false;
		left = false;
		right = false;
		shift = false;
	}
}
