package;

class Chart {
	public var bpm:Float;
	public var notes:Array<Note>;

	public function new() {
		bpm = 120;
		notes = [];
		loadDemoChart();
	}

	function loadDemoChart() {
		// 内置演示谱面：120 BPM，约 60 秒
		// 每个 beat = 500ms
		var beat:Float = 60000 / bpm;
		var t:Int = 1500; // 从 1.5s 开始，给玩家准备时间

		// 生成一段有规律的演示谱面
		var patterns = [
			// [angle_index, distance, keyIndex]
			[0, 0.6, 0], [2, 0.7, 1], [4, 0.5, 2], [6, 0.8, 3],
			[3, 0.4, 1], [1, 0.7, 2], [5, 0.6, 0], [7, 0.5, 3],
			[0, 0.8, 3], [4, 0.3, 0], [2, 0.6, 2], [6, 0.7, 1],
			[1, 0.5, 1], [3, 0.8, 3], [5, 0.4, 0], [7, 0.6, 2],
		];

		var pi = Math.PI;
		for (bar in 0...16) {
			for (step in 0...8) {
				var p = patterns[(bar * 8 + step) % patterns.length];
				var angle = p[0] * (pi / 4) + (bar % 2 == 0 ? 0 : pi / 8);
				var dist = p[1];
				var key = Std.int(p[2]);
				// 每半拍一个音
				notes.push(new Note(t, angle, dist, key));
				t += Std.int(beat / 2);
			}
			// 每小节末尾空半拍
			t += Std.int(beat / 2);
		}
	}
}
