package;

class Note {
	public var time:Int;       // 判定时刻 (ms)
	public var angle:Float;    // 角度 (弧度)
	public var distance:Float; // 距中心比例 0~1
	public var keyIndex:Int;   // 0=D 1=F 2=J 3=K

	public function new(time:Int, angle:Float, distance:Float, keyIndex:Int) {
		this.time = time;
		this.angle = angle;
		this.distance = distance;
		this.keyIndex = keyIndex;
	}
}
