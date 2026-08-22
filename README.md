# Green Sweeper

使用 Godot 4.7.2 Standard 和 GDScript 制作的生态主题关卡制扫雷游戏。

## 当前版本：v0.3.2

## 正式游戏外壳

- 正常启动先进入主菜单，不再直接进入棋盘
- 支持开始游戏、继续上次关卡、动态关卡选择、设置和退出
- 默认只解锁第一关，完成当前关后自动解锁下一关
- 自动记录每关完成状态和最佳时间
- 游戏内支持计时、暂停、继续、重开和返回选关
- 设置包含主音量、窗口模式、最大化窗口和无边框全屏
- 进度保存在 `user://save_v1.json`；“继续游戏”会重新生成上次关卡，不恢复中途棋盘
- `--level=1` 至 `--level=6` 可绕过菜单直接测试，且不写入关卡进度

## 横屏桌面原型

- 默认分辨率基准为 `1280 × 720`，并适配Steam Deck的 `1280 × 800`
- 首次启动默认使用最大化窗口，在高分辨率显示器上自动利用可用空间
- 主菜单采用左侧操作、右侧程序化生态展示
- 游戏页面采用左侧环境目标、中间棋盘、右侧HUD三栏布局
- 方格棋盘扩大到约480像素目标范围，三角棋盘扩大到 `620 × 460`
- 当前横屏版本面向桌面展示，暂未制作复杂窄窗口响应式重排

### 第一关“萌芽”

- `5 × 5` 棋盘、每局随机生成5个污染核心
- 开局时立即生成完整随机棋盘，但所有格子保持关闭
- 第一关会从真实安全格中选择一个绿色箭头建议点，优先选择0格
- 跟随箭头必然安全；箭头只是建议，玩家可以点击任意格
- 点击其他格不受保护，可能直接触碰污染核心
- 第一次点击任意格后，箭头引导立即消失
- 非零数字格只打开自身；0格展开相连0格及外围数字边界
- 左键净化，右键标记或取消标记
- 打开全部20个安全格即可完成净化
- 允许少量猜测和二选一局面

### 第二关“灌木”

- `6 × 6` 棋盘、8个随机污染核心
- 开局完整随机并保持全部关闭
- 取消第一关的绿色安全箭头
- 首点不受保护，可能直接触碰污染核心
- 完成第一关后，主按钮切换为“进入下一关”
- 第二关完成后继续进入第三关

### 第三至第五关

- 第三关“湿地”：`8 × 8 / 14个污染核心`
- 第四关“草原”：`10 × 10 / 23个污染核心`
- 第五关“森林”：`12 × 12 / 35个污染核心`
- 三关均无安全箭头、无首点保护
- 继续使用方格8邻接、标记和数字双击展开

### 第六关“山脉”

- `24列 × 9排`，共216个真正的上下交替三角格
- 每局随机生成80个污染核心，无安全箭头、无首点保护
- 每个三角格只计算共享整条边的最多3个邻居
- 棋盘保持完整宽幅，以多个程序化山峰表现山脉环境
- 继续支持经典0区域展开、右键标记和严格数字双击展开

## 01—06 陆地主题

```text
萌芽 → 灌木 → 湿地 → 草原 → 森林 → 山脉
```

## 数字双击展开

- 双击已经打开的非零数字格，可以尝试快速展开周围安全格
- 只有当相邻污染核心全部被正确标记时才会生效
- 标记不足或存在错误标记时不会展开，也不会触发失败
- 展开遇到0格时继续按经典规则扩展到数字边界

## 玩法文档

- [`Green_Sweeper_陆地篇玩法蓝图_V1.0.docx`](docs/Green_Sweeper_陆地篇玩法蓝图_V1.0.docx)

## 打开项目

1. 启动 Godot 4.7.2。
2. 点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 点击 **Import & Edit**。
5. 按 `F5` 运行项目。

也可以从命令行启动：

```text
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe --editor --path D:\o!mygame\minesweeper
```

## 目录

```text
scenes/    Godot 场景
scripts/   关卡数据和游戏逻辑
tests/     无窗口规则测试
build/     导出产物（不提交到 Git）
```

## 运行测试

```text
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/board_smoke_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/triangle_board_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/save_store_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/shell_flow_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/desktop_layout_test.gd
```
