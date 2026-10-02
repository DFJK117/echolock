package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.Lib;
import openfl.system.System;

enum GameState {
	MENU;
	PLAY;
	EDITOR;
}

class Game extends Sprite {
	// ===== 常量 =====
	static final CENTER_X = 480;
	static final CENTER_Y = 480;
	static final RADAR_RADIUS = 380;
	static final LOCK_RADIUS = 55;
	static final JUDGE_WINDOW = 200;
	static final PERFECT_WINDOW = 70;
	static final GOOD_WINDOW = 130;
	static final RING_SPEED = 0.65; // px / ms
	static final SIGNAL_WARN = 700; // ms 提前出现

	static final KEY_COLORS = [0x4fc3f7, 0x81c784, 0xffd54f, 0xe57373];
	static final KEY_LABELS = ["D", "F", "J", "K"];

	// ===== 状态 =====
	var state:GameState;
	var gameTime:Int;
	var score:Float;
	var combo:Int;
	var maxCombo:Int;
	var bpm:Float;
	var beatInterval:Float;

	// ===== 游戏对象 =====
	var rings:Array<SonarRing>;
	var signals:Array<SignalPoint>;
	var particles:Array<Particle>;
	var crosshair:Crosshair;
	var keys:KeyState;
	var chart:Chart;
	var nextNoteIndex:Int;

	// ===== 输入边沿检测 =====
	var prevN:Bool;
	var prevM:Bool;
	var prevEnter:Bool;
	var prevSpace:Bool;
	var prevE:Bool;
	var prevEsc:Bool;
	var prevR:Bool;
	var prev1:Bool;
	var prev2:Bool;
	var prev3:Bool;
	var prev4:Bool;

	// ===== 编辑器 =====
	var editorNotes:Array<Note>;
	var editorSelectedKey:Int;
	var editorPlaying:Bool;
	var editorTime:Int;
	var editorNextNote:Int;

	// ===== UI =====
	var scoreText:TextField;
	var comboText:TextField;
	var judgeText:TextField;
	var menuTitle:TextField;
	var menuHint:TextField;
	var editorInfo:TextField;
	var judgeTimer:Int;
	var radarBg:Sprite;

	// ===== 虚拟按键 =====
	var vControls:VirtualControls;
	var isMobile:Bool;

	public function new() {
		super();
		state = MENU;
		gameTime = 0;
		score = 0;
		combo = 0;
		maxCombo = 0;
		bpm = 120;
		beatInterval = 60000 / bpm;
		rings = [];
		signals = [];
		particles = [];
		nextNoteIndex = 0;
		judgeTimer = 0;

		prevN = false; prevM = false; prevEnter = false;
		prevSpace = false; prevE = false; prevEsc = false; prevR = false;
		prev1 = false; prev2 = false; prev3 = false; prev4 = false;

		keys = new KeyState();
		effKeys = new KeyState();
		crosshair = new Crosshair();
		crosshair.x = CENTER_X;
		crosshair.y = CENTER_Y;

		chart = new Chart();
		editorNotes = [];
		editorSelectedKey = 0;
		editorPlaying = false;
		editorTime = 0;
		editorNextNote = 0;

		isMobile = detectMobile();

		setupUI();
		drawRadarBackground();

		addChild(crosshair);
		if (isMobile) {
			vControls = new VirtualControls();
			addChild(vControls);
		}

		// 键盘监听必须等上舞台后拿 stage，否则构造函数里 stage 为 null 会崩溃
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.ENTER_FRAME, update);
	}

	function onAddedToStage(e:Event):Void {
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	// ==================== 初始化 ====================

	function detectMobile():Bool {
		var os = System.osName.toLowerCase();
		var mobileOS = os.indexOf("android") >= 0 || os.indexOf("ios") >= 0
			|| os.indexOf("iphone") >= 0 || os.indexOf("ipad") >= 0
			|| os.indexOf("harmony") >= 0;
		#if html5
		return mobileOS || Lib.current.stage.stageWidth < 640;
		#else
		return mobileOS;
		#end
	}

	function setupUI():Void {
		var fmt = new TextFormat("Consolas", 22, 0xe0f7fa, true);

		scoreText = new TextField();
		scoreText.x = 20; scoreText.y = 16;
		scoreText.width = 300; scoreText.height = 32;
		scoreText.defaultTextFormat = fmt;
		scoreText.text = "SCORE 0";
		scoreText.visible = false;
		addChild(scoreText);

		comboText = new TextField();
		comboText.x = 20; comboText.y = 50;
		comboText.width = 300; comboText.height = 32;
		comboText.defaultTextFormat = fmt;
		comboText.text = "COMBO 0";
		comboText.visible = false;
		addChild(comboText);

		var jFmt = new TextFormat("Consolas", 38, 0xffffff, true);
		jFmt.align = TextFormatAlign.CENTER;
		judgeText = new TextField();
		judgeText.x = CENTER_X - 160; judgeText.y = CENTER_Y + RADAR_RADIUS + 10;
		judgeText.width = 320; judgeText.height = 50;
		judgeText.defaultTextFormat = jFmt;
		judgeText.text = "";
		judgeText.selectable = false;
		addChild(judgeText);

		var titleFmt = new TextFormat("Consolas", 56, 0x00e5ff, true);
		titleFmt.align = TextFormatAlign.CENTER;
		menuTitle = new TextField();
		menuTitle.x = 0; menuTitle.y = 200;
		menuTitle.width = 960; menuTitle.height = 80;
		menuTitle.defaultTextFormat = titleFmt;
		menuTitle.text = "ECHOLOCK";
		menuTitle.selectable = false;
		addChild(menuTitle);

		var hintFmt = new TextFormat("Consolas", 20, 0xb0bec5, false);
		hintFmt.align = TextFormatAlign.CENTER;
		menuHint = new TextField();
		menuHint.x = 0; menuHint.y = 340;
		menuHint.width = 960; menuHint.height = 200;
		menuHint.defaultTextFormat = hintFmt;
		menuHint.text = "ENTER  - 开始游戏\nE      - 谱面编辑器\n\nWASD / 方向键  移动光标\nSHIFT          加速\nN / M          点击锁定";
		menuHint.selectable = false;
		addChild(menuHint);

		var eFmt = new TextFormat("Consolas", 16, 0xb0bec5, false);
		editorInfo = new TextField();
		editorInfo.x = 20; editorInfo.y = 880;
		editorInfo.width = 920; editorInfo.height = 60;
		editorInfo.defaultTextFormat = eFmt;
		editorInfo.text = "";
		editorInfo.visible = false;
		addChild(editorInfo);
	}

	function drawRadarBackground():Void {
		radarBg = new Sprite();
		var g = radarBg.graphics;

		// 外圆
		g.lineStyle(2, 0x006064, 0.8);
		g.drawCircle(CENTER_X, CENTER_Y, RADAR_RADIUS);

		// 同心圆
		for (r in [95, 190, 285]) {
			g.lineStyle(1, 0x004d40, 0.4);
			g.drawCircle(CENTER_X, CENTER_Y, r);
		}

		// 十字线
		g.lineStyle(1, 0x004d40, 0.35);
		g.moveTo(CENTER_X - RADAR_RADIUS, CENTER_Y);
		g.lineTo(CENTER_X + RADAR_RADIUS, CENTER_Y);
		g.moveTo(CENTER_X, CENTER_Y - RADAR_RADIUS);
		g.lineTo(CENTER_X, CENTER_Y + RADAR_RADIUS);

		// 对角线
		g.lineStyle(1, 0x004d40, 0.2);
		var d45 = RADAR_RADIUS * 0.7071;
		g.moveTo(CENTER_X - d45, CENTER_Y - d45);
		g.lineTo(CENTER_X + d45, CENTER_Y + d45);
		g.moveTo(CENTER_X + d45, CENTER_Y - d45);
		g.lineTo(CENTER_X - d45, CENTER_Y + d45);

		// 中心点
		g.beginFill(0x006064, 0.6);
		g.drawCircle(CENTER_X, CENTER_Y, 4);
		g.endFill();

		addChildAt(radarBg, 0);
	}

	// ==================== 输入 ====================
	// keys   = 物理键盘状态（事件驱动，持久）
	// effKeys = 每帧重算的有效输入（键盘 || 虚拟按键，防粘键）

	var effKeys:KeyState;

	var nHeld:Bool = false;
	var mHeld:Bool = false;
	var enterHeld:Bool = false;
	var spaceHeld:Bool = false;
	var eHeld:Bool = false;
	var escHeld:Bool = false;
	var rHeld:Bool = false;
	var oneHeld:Bool = false;
	var twoHeld:Bool = false;
	var threeHeld:Bool = false;
	var fourHeld:Bool = false;
	var cleared:Bool = false;

	function onKeyDown(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case Keyboard.W, Keyboard.UP: keys.up = true;
			case Keyboard.S, Keyboard.DOWN: keys.down = true;
			case Keyboard.A, Keyboard.LEFT: keys.left = true;
			case Keyboard.D, Keyboard.RIGHT: keys.right = true;
			case Keyboard.SHIFT: keys.shift = true;
			case Keyboard.N: nHeld = true;
			case Keyboard.M: mHeld = true;
			case Keyboard.ENTER: enterHeld = true;
			case Keyboard.SPACE: spaceHeld = true;
			case Keyboard.E: eHeld = true;
			case Keyboard.ESCAPE: escHeld = true;
			case Keyboard.R: rHeld = true;
			case Keyboard.NUMBER_1: oneHeld = true;
			case Keyboard.NUMBER_2: twoHeld = true;
			case Keyboard.NUMBER_3: threeHeld = true;
			case Keyboard.NUMBER_4: fourHeld = true;
			default:
		}
	}

	function onKeyUp(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case Keyboard.W, Keyboard.UP: keys.up = false;
			case Keyboard.S, Keyboard.DOWN: keys.down = false;
			case Keyboard.A, Keyboard.LEFT: keys.left = false;
			case Keyboard.D, Keyboard.RIGHT: keys.right = false;
			case Keyboard.SHIFT: keys.shift = false;
			case Keyboard.N: nHeld = false;
			case Keyboard.M: mHeld = false;
			case Keyboard.ENTER: enterHeld = false;
			case Keyboard.SPACE: spaceHeld = false;
			case Keyboard.E: eHeld = false;
			case Keyboard.ESCAPE: escHeld = false;
			case Keyboard.R: rHeld = false;
			case Keyboard.NUMBER_1: oneHeld = false;
			case Keyboard.NUMBER_2: twoHeld = false;
			case Keyboard.NUMBER_3: threeHeld = false;
			case Keyboard.NUMBER_4: fourHeld = false;
			default:
		}
	}

	private function isNDown():Bool {
		return nHeld || (vControls != null && vControls.nDown);
	}

	private function isMDown():Bool {
		return mHeld || (vControls != null && vControls.mDown);
	}

	private function computeEffKeys():Void {
		effKeys.up = keys.up;
		effKeys.down = keys.down;
		effKeys.left = keys.left;
		effKeys.right = keys.right;
		effKeys.shift = keys.shift;
		if (vControls != null) {
			effKeys.up = effKeys.up || vControls.keys.up;
			effKeys.down = effKeys.down || vControls.keys.down;
			effKeys.left = effKeys.left || vControls.keys.left;
			effKeys.right = effKeys.right || vControls.keys.right;
			effKeys.shift = effKeys.shift || vControls.keys.shift;
		}
	}

	// ==================== 游戏循环 ====================

	function update(e:Event):Void {
		var dt = 1000.0 / stage.frameRate;
		if (dt <= 0 || dt > 100) dt = 16.67;

		// 计算有效按键（物理键盘 || 虚拟按键，每帧重算防粘键）
		computeEffKeys();
		crosshair.update(effKeys);

		// 边沿检测
		var nNow = isNDown();
		var mNow = isMDown();
		var nPress = nNow && !prevN;
		var mPress = mNow && !prevM;
		prevN = nNow;
		prevM = mNow;

		var enterPress = enterHeld && !prevEnter;
		var spacePress = spaceHeld && !prevSpace;
		var ePress = eHeld && !prevE;
		var escPress = escHeld && !prevEsc;
		var rPress = rHeld && !prevR;
		var onePress = oneHeld && !prev1;
		var twoPress = twoHeld && !prev2;
		var threePress = threeHeld && !prev3;
		var fourPress = fourHeld && !prev4;
		prevEnter = enterHeld; prevSpace = spaceHeld; prevE = eHeld;
		prevEsc = escHeld; prevR = rHeld;
		prev1 = oneHeld; prev2 = twoHeld; prev3 = threeHeld; prev4 = fourHeld;

		switch (state) {
			case MENU:
				menuTitle.visible = true;
				menuHint.visible = true;
				scoreText.visible = false;
				comboText.visible = false;
				editorInfo.visible = false;
				judgeText.text = "";

				if (enterPress) startPlay();
				if (ePress) startEditor();

			case PLAY:
				menuTitle.visible = false;
				menuHint.visible = false;
				scoreText.visible = true;
				comboText.visible = true;
				editorInfo.visible = false;

				gameTime += Std.int(dt);
				updatePlay(dt, nPress || mPress);
				if (escPress) backToMenu();

			case EDITOR:
				menuTitle.visible = false;
				menuHint.visible = false;
				scoreText.visible = false;
				comboText.visible = false;
				editorInfo.visible = true;

				updateEditor(dt, nPress || mPress, spacePress, rPress, escPress,
					onePress, twoPress, threePress, fourPress);
		}

		// 更新粒子（所有状态通用）
		updateParticles(dt);

		// 判定文字淡出
		if (judgeTimer > 0) {
			judgeTimer--;
			if (judgeTimer == 0) judgeText.text = "";
		}
	}

	// ==================== 游戏模式 ====================

	function startPlay():Void {
		state = PLAY;
		gameTime = 0;
		score = 0;
		combo = 0;
		maxCombo = 0;
		nextNoteIndex = 0;
		cleared = false;
		clearRingsAndSignals();
		crosshair.x = CENTER_X;
		crosshair.y = CENTER_Y;
		updateScoreUI();
	}

	function updatePlay(dt:Float, clicked:Bool):Void {
		// 生成信号点和对应声波环
		while (nextNoteIndex < chart.notes.length) {
			var note = chart.notes[nextNoteIndex];
			var signalSpawn = note.time - SIGNAL_WARN;
			if (gameTime >= signalSpawn) {
				spawnNote(note);
				nextNoteIndex++;
			} else {
				break;
			}
		}

		// 更新声波环
		var i = rings.length;
		while (i-- > 0) {
			var ring = rings[i];
			ring.update(gameTime);
			if (!ring.alive) {
				removeChild(ring);
				rings.splice(i, 1);
			}
		}

		// 更新信号点 + 检测点亮 + Miss
		i = signals.length;
		while (i-- > 0) {
			var sig = signals[i];
			if (!sig.active) { signals.splice(i, 1); continue; }

			// 检测是否被环扫过
			if (!sig.lit) {
				for (ring in rings) {
					if (Math.abs(ring.radius - sig.distFromCenter) < 28) {
						sig.lit = true;
						break;
					}
				}
			}

			sig.update(gameTime);

			// Miss 检测
			if (sig.lit && gameTime - sig.hitTime > JUDGE_WINDOW) {
				missSignal(sig);
				signals.splice(i, 1);
			}
		}

		// 点击判定
		if (clicked) {
			handleClick();
		}

		// 谱面结束检测（只触发一次）
		if (!cleared && nextNoteIndex >= chart.notes.length && signals.length == 0 && gameTime > 2000) {
			cleared = true;
			judgeText.text = "CLEAR! MAX COMBO " + maxCombo;
			judgeText.textColor = 0x4fc3f7;
			judgeTimer = 180;
		}
	}

	function spawnNote(note:Note):Void {
		var dist = note.distance * RADAR_RADIUS;
		var sx = CENTER_X + Math.cos(note.angle) * dist;
		var sy = CENTER_Y + Math.sin(note.angle) * dist;

		var sig = new SignalPoint(sx, sy, note.keyIndex, note.time, dist);
		signals.push(sig);
		addChild(sig);

		// 环在信号点之前生成，确保能扫到
		var ringSpawn = note.time - dist / RING_SPEED;
		var ring = new SonarRing(ringSpawn, RADAR_RADIUS, RING_SPEED);
		ring.x = CENTER_X;
		ring.y = CENTER_Y;
		ring.update(gameTime); // 立即更新到当前半径
		rings.push(ring);
		addChildAt(ring, getChildIndex(radarBg) + 1);
	}

	function handleClick():Void {
		for (sig in signals) {
			if (!sig.active || !sig.lit) continue;

			var dx = crosshair.x - sig.x;
			var dy = crosshair.y - sig.y;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist > LOCK_RADIUS) continue;

			var timeDiff = Math.abs(gameTime - sig.hitTime);
			if (timeDiff > JUDGE_WINDOW) continue;

			var judgment = if (timeDiff <= PERFECT_WINDOW) "PERFECT"
				else if (timeDiff <= GOOD_WINDOW) "GOOD"
				else "OK";
			hitSignal(sig, judgment);
			return;
		}
	}

	function hitSignal(sig:SignalPoint, judgment:String):Void {
		sig.active = false;
		removeChild(sig);

		var points = switch (judgment) {
			case "PERFECT": 1000;
			case "GOOD": 700;
			case "OK": 400;
			default: 100;
		};
		score += points * (1 + combo * 0.05);
		combo++;
		if (combo > maxCombo) maxCombo = combo;

		showJudgment(judgment, KEY_COLORS[sig.keyIndex]);
		spawnParticles(sig.x, sig.y, KEY_COLORS[sig.keyIndex]);
		updateScoreUI();
	}

	function missSignal(sig:SignalPoint):Void {
		sig.active = false;
		removeChild(sig);
		combo = 0;
		showJudgment("MISS", 0xef5350);
		updateScoreUI();
	}

	function showJudgment(text:String, color:Int):Void {
		judgeText.text = text;
		judgeText.textColor = color;
		judgeTimer = 45;
	}

	function updateScoreUI():Void {
		scoreText.text = "SCORE " + Std.string(Math.round(score));
		comboText.text = "COMBO " + combo;
	}

	// ==================== 谱器模式 ====================

	function startEditor():Void {
		state = EDITOR;
		editorTime = 0;
		editorPlaying = false;
		editorNextNote = 0;
		if (editorNotes.length == 0) {
			// 从当前谱面复制一份作为基础
			for (n in chart.notes) editorNotes.push(n);
		}
		clearRingsAndSignals();
		crosshair.x = CENTER_X;
		crosshair.y = CENTER_Y;
		updateEditorInfo();
	}

	function updateEditor(dt:Float, clicked:Bool, spacePress:Bool, rPress:Bool,
		escPress:Bool, onePress:Bool, twoPress:Bool, threePress:Bool, fourPress:Bool):Void {

		// 选键
		if (onePress) editorSelectedKey = 0;
		if (twoPress) editorSelectedKey = 1;
		if (threePress) editorSelectedKey = 2;
		if (fourPress) editorSelectedKey = 3;

		// 播放/暂停
		if (spacePress) {
			editorPlaying = !editorPlaying;
			if (!editorPlaying) {
				clearRingsAndSignals();
				editorNextNote = 0;
				editorTime = 0;
			}
		}

		// 清空
		if (rPress) {
			editorNotes = [];
			clearRingsAndSignals();
			editorTime = 0;
			editorNextNote = 0;
		}

		// 放置音符（仅在暂停时）
		if (clicked && !editorPlaying) {
			placeEditorNote();
		}

		// 播放预览
		if (editorPlaying) {
			editorTime += Std.int(dt);

			while (editorNextNote < editorNotes.length) {
				var note = editorNotes[editorNextNote];
				if (editorTime >= note.time - SIGNAL_WARN) {
					spawnNote(note);
					editorNextNote++;
				} else break;
			}

			// 更新环
			var i = rings.length;
			while (i-- > 0) {
				rings[i].update(editorTime);
				if (!rings[i].alive) { removeChild(rings[i]); rings.splice(i, 1); }
			}

			// 更新信号
			i = signals.length;
			while (i-- > 0) {
				var sig = signals[i];
				if (!sig.active) { signals.splice(i, 1); continue; }
				if (!sig.lit) {
					for (ring in rings) {
						if (Math.abs(ring.radius - sig.distFromCenter) < 28) {
							sig.lit = true; break;
						}
					}
				}
				sig.update(editorTime);
				if (sig.lit && editorTime - sig.hitTime > JUDGE_WINDOW) {
					sig.active = false;
					removeChild(sig);
					signals.splice(i, 1);
				}
			}

			// 预览中点击也可以判定（测试手感）
			if (clicked) handleEditorClick();

			if (editorNextNote >= editorNotes.length && signals.length == 0) {
				editorPlaying = false;
				editorTime = 0;
				editorNextNote = 0;
				clearRingsAndSignals();
			}
		}

		// 返回菜单（自动加载谱面）
		if (escPress) {
			if (editorNotes.length > 0) {
				chart.notes = editorNotes.copy();
			}
			backToMenu();
		}

		updateEditorInfo();
	}

	function placeEditorNote():Void {
		var dx = crosshair.x - CENTER_X;
		var dy = crosshair.y - CENTER_Y;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (dist < 30) return; // 太靠近中心不放

		var angle = Math.atan2(dy, dx);
		var normDist = dist / RADAR_RADIUS;
		if (normDist > 0.95) normDist = 0.95;
		if (normDist < 0.15) normDist = 0.15;

		var note = new Note(editorTime + 300, angle, normDist, editorSelectedKey);
		editorNotes.push(note);
		// 按时间排序
		editorNotes.sort(function(a, b) return a.time - b.time);

		spawnParticles(crosshair.x, crosshair.y, KEY_COLORS[editorSelectedKey]);
	}

	function handleEditorClick():Void {
		for (sig in signals) {
			if (!sig.active || !sig.lit) continue;
			var dx = crosshair.x - sig.x;
			var dy = crosshair.y - sig.y;
			if (Math.sqrt(dx*dx + dy*dy) > LOCK_RADIUS) continue;
			var td = Math.abs(editorTime - sig.hitTime);
			if (td > JUDGE_WINDOW) continue;
			sig.active = false;
			removeChild(sig);
			spawnParticles(sig.x, sig.y, KEY_COLORS[sig.keyIndex]);
			return;
		}
	}

	function updateEditorInfo():Void {
		var status = if (editorPlaying) "PLAYING" else "PAUSED";
		editorInfo.text = "[EDITOR] " + status + "  |  T:" + editorTime
			+ "ms  |  Key:" + KEY_LABELS[editorSelectedKey]
			+ "  |  Notes:" + editorNotes.length
			+ "  |  1-4选键 N/M放置 空格播放 R清空 ESC保存返回";
	}

	// ==================== 通用 ====================

	function backToMenu():Void {
		state = MENU;
		clearRingsAndSignals();
		gameTime = 0;
		score = 0;
		combo = 0;
	}

	function clearRingsAndSignals():Void {
		for (r in rings) removeChild(r);
		for (s in signals) removeChild(s);
		rings = [];
		signals = [];
	}

	function spawnParticles(x:Float, y:Float, color:Int):Void {
		for (i in 0...14) {
			var p = new Particle(x, y, color);
			particles.push(p);
			addChild(p);
		}
	}

	function updateParticles(dt:Float):Void {
		var i = particles.length;
		while (i-- > 0) {
			particles[i].update();
			if (particles[i].life <= 0) {
				removeChild(particles[i]);
				particles.splice(i, 1);
			}
		}
	}
}
