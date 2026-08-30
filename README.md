# Green Sweeper

使用 Godot 4.7.2 Standard 和 GDScript 制作的生态主题关卡制扫雷游戏。

## 当前版本：v0.3.5

### v0.3.5 更新

- 棋盘托、动态米白底板、绿色压痕格和第1–5关贴纸完成统一视觉升级
- 新增机器人守护者、游戏内阴影及胜利/失败反馈动画
- 第1–5关全部支持按关卡记录的自适应开局辅助
- 新增第6–10关海洋篇玩法原型，采用尖顶六边形棋盘与六邻接规则
- 海洋篇现阶段通过 `--level=6` 至 `--level=10` 进入，正式海洋UI和美术将在后续版本继续制作

### v0.3.4 更新

- 第一关引导改为仅首次游玩显示
- 第1–5关统一手绘桌面与棋盘表现，并加入各关独立装饰、贴纸和失败状态
- 新增地图式“陆地探险”关卡选择页面与关卡状态信息
- 移除原第6关和三角棋盘
- 优化运行素材尺寸与纹理缓存，减少界面切换卡顿

## 正式游戏外壳

- 正常启动先进入主菜单，不再直接进入棋盘
- 支持开始游戏、继续上次关卡、动态关卡选择、设置和退出
- 默认只解锁第一关，完成当前关后自动解锁下一关
- 自动记录每关完成状态和最佳时间
- 游戏内支持计时、暂停、继续、重开和返回选关
- 设置包含主音量、窗口模式、最大化窗口和无边框全屏
- 进度保存在 `user://save_v1.json`；“继续游戏”会重新生成上次关卡，不恢复中途棋盘
- `--level=1` 至 `--level=10` 可绕过菜单直接测试，且不写入关卡进度

## 横屏桌面原型

- 默认分辨率基准为 `1280 × 720`，并适配Steam Deck的 `1280 × 800`
- 首次启动默认使用最大化窗口，在高分辨率显示器上自动利用可用空间
- 主菜单采用左侧操作、右侧程序化生态展示
- 游戏页面采用左侧环境目标、中间棋盘、右侧HUD三栏布局
- 方格棋盘根据关卡尺寸自动缩放到桌面纸托范围
- 当前横屏版本面向桌面展示，暂未制作复杂窄窗口响应式重排

### 第一关“萌芽”

- `5 × 5` 棋盘、每局随机生成5个污染核心
- 开局时立即生成完整随机棋盘，但所有格子保持关闭
- 仅首次游玩会显示安全格引导；后台已有游玩记录时不再显示
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

- 第三关“湿地”：`8 × 8 / 9个污染核心`
- 第四关“草原”：`10 × 10 / 17个污染核心`
- 第五关“森林”：`12 × 12 / 28个污染核心`
- 第2–5关复用第一关的桌面、纸托、装饰、格子美术和反馈动画
- 每关只按自身尺寸重绘棋盘格，并保留各自的污染核心数量
- 第二关仍无安全箭头和首点保护
- 第1–5关默认仍可能首点踩雷；连续3局首点踩雷后，下一局首点必定安全
- 第1–5关连续3局在第2–5步内失败后，下一局首点必定展开一片0格区域
- 自适应保护只作用于触发后的下一局，并按关卡分别记录
- 继续使用方格8邻接、标记和数字双击展开

## 01—05 陆地主题

```text
萌芽 → 灌木 → 湿地 → 草原 → 森林
```

## 06—10 海洋篇原型

```text
潮池初醒 → 海草摇篮 → 珊瑚花园 → 海藻森林 → 深海鲸落
```

- 关卡6：`5 × 5 / 5个污染核心`
- 关卡7：`6 × 6 / 7个污染核心`
- 关卡8：`7 × 7 / 10个污染核心`
- 关卡9：`8 × 8 / 14个污染核心`
- 关卡10：`10 × 9 / 22个污染核心`
- 使用尖顶六边形错行布局，每格最多连接六个邻格
- 当前复用通用游戏外壳，正式海洋场景、地图和专属素材尚在制作

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
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/save_store_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/shell_flow_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/desktop_layout_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/adaptive_opening_assist_test.gd
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/ocean_levels_test.gd
```
