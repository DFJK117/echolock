# EchoLock — 声呐锁定

一款**全新玩法**的音游。不是下落式，不是 OSU 点按。你是声呐操作员——雷达中心发出声波环，环扫过隐藏信号点的瞬间它会被点亮，你必须在那一瞬把光标移过去并点击锁定。

## 玩法核心

- **声波环**从中心向外扩散，既是视觉节奏器也是玩法机制
- **信号点**平时几乎不可见，被声波环扫过时才点亮并显示对应按键
- **三重判定**：光标定位（在锁定半径内）+ 时机（判定窗口内）+ 点击（N/M）
- 光标带 OSU 式渐变拖尾

## 操作

### Windows / 桌面网页
| 按键 | 功能 |
|------|------|
| W A S D / 方向键 | 移动光标 |
| Shift | 加速移动（x2.6） |
| N / M | 点击锁定（两键等效，可交替高速连点） |
| Enter | 菜单：开始游戏 |
| E | 菜单：进入谱面编辑器 |
| Esc | 返回菜单 |

### Android / 移动网页
屏幕底部自动显示虚拟按键：左侧方向键 + Shift，右侧 N / M 大键。

## 谱面编辑器（内置）

在主菜单按 **E** 进入。

| 操作 | 功能 |
|------|------|
| 1 / 2 / 3 / 4 | 选择音符键位（D/F/J/K，对应蓝绿黄红） |
| N / M | 在光标位置放置音符（暂停状态下） |
| 空格 | 播放 / 暂停预览 |
| R | 清空当前谱面 |
| Esc | 保存并返回菜单（编辑的谱面自动加载到游戏） |

放置音符时，时间 = 当前编辑器时间 + 300ms（给玩家预留反应时间）。

## 项目结构

```
EchoLock/
├── project.xml              # OpenFL 项目配置
├── Source/
│   ├── Main.hx              # 入口
│   ├── Game.hx              # 主游戏（菜单/游戏/谱器三态）
│   ├── Chart.hx             # 谱面数据 + 内置演示谱
│   ├── Note.hx              # 音符数据类
│   ├── SonarRing.hx         # 声波环
│   ├── SignalPoint.hx       # 信号点（目标）
│   ├── Crosshair.hx         # 光标 + OSU 式拖尾
│   ├── Particle.hx          # 命中粒子特效
│   ├── KeyState.hx          # 按键状态
│   └── VirtualControls.hx   # 安卓/移动网页虚拟按键
├── assets/
│   └── (谱面 JSON 可放这里)
├── .github/workflows/
│   └── build.yml            # GitHub Actions 三平台编译
└── README.md
```

## 编译方式

### 方式一：GitHub Actions（推荐，不用本地装环境）

1. 把整个 `EchoLock/` 目录推到 GitHub 仓库
2. 推送后 Actions 自动触发，或在 Actions 页面手动点 "Run workflow"
3. 编译完成后在 Actions 运行详情页下载三个 artifact：
   - `EchoLock-Windows` — Windows 可执行文件
   - `EchoLock-HTML5` — 网页版（打开 index.html 即玩）
   - `EchoLock-Android` — Android Debug APK

### 方式二：本地编译

需要先装 [Haxe 4.3+](https://haxe.org/)，然后：

```bash
haxelib install openfl
haxelib install lime
haxelib run lime setup

# 编译网页版（最快验证）
lime build html5

# 编译 Windows
lime build windows

# 编译安卓（需 Android SDK + NDK）
lime build android
```

编译产物在 `Export/<平台>/bin/`。

## 技术栈

- **语言**：Haxe 4
- **引擎**：OpenFL + Lime（跨平台 2D 渲染）
- **目标平台**：Windows / HTML5 / Android（一套代码三端编译）
- **渲染**：纯矢量 Graphics API，无外部图片资源，体积极小

## 判定参数

| 判定 | 时间窗口 | 分数 |
|------|----------|------|
| PERFECT | ±70ms | 1000 × (1 + combo×0.05) |
| GOOD | ±130ms | 700 × (1 + combo×0.05) |
| OK | ±200ms | 400 × (1 + combo×0.05) |
| MISS | 超出窗口 | 断连击 |

锁定半径：55px（光标中心到信号点中心）。
