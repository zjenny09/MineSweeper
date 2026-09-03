# 扫描能力实施进度

更新时间：2026-09-01

## 固定产品规则

- 保留随机棋盘；不引入运行时求解器、预制无猜棋盘或动态移动雷。
- 每局最多使用一次扫描。
- 第1–2关免费获得一次扫描，但必须完成第一次普通翻开后才能使用。
- 第3–10关首次直接进入时从零充能；通过“下一关”连续推进时，继承上一关未使用的原始能量值，并按新关卡阈值重新截断。第一次普通翻开及其完整连锁展开仍不计能量。
- 后续普通翻开和快速展开按新增安全格数量充能；插旗、无效操作、扫描展开不充能。
- 充能阈值为本关安全格总数的25%，向上取整。
- 第3–5关在首翻锁定或充能期间，机器人纸签显示 `扫描 当前值/本关阈值 · C`；达到就绪后才显示 `点机器人扫描 · C`。
- 玩家点击机器人/海洋备用按钮或按 `C` 进入目标模式，自行选择隐藏且未标记的格子。
- 安全结果按正常规则翻开（零格可以连锁展开）；雷区结果成为不可取消的权威标记且不失败。
- 有效选择才消耗扫描；取消或无效格不消耗。
- 扫描在第一次普通翻开前锁定，避免方格开局辅助或六边形首点重排使结果失效。
- 第1–10关统一使用自适应开局规则：同一关连续2次首点踩雷后，仅该关下一局启用一次首点安全；同一关连续3次在5步内失败后，仅该关下一局启用一次安全区域开局。“下一局”只指重开同一关，不指进入下一关，辅助资格不跨关继承。
- 扫描状态不写入存档；暂停/设置页往返保留。重开当前关卡或从选关页直接进入时重置；只有胜利后点击“下一关”的连续推进继承未使用能量。

## 明确不做

- 不保证整局完全无猜。
- 不自动替玩家选择扫描目标。
- 不在扫描时重新生成、交换或移动雷。
- 不新增生成式角色素材。
- 未经用户实际观看确认，不把动画节奏和视觉效果标记为最终完成。

## 状态机

`LOCKED_FIRST_REVEAL → CHARGING/READY → TARGETING → RESOLVING → USED`

胜利或失败进入 `FINISHED`；取消从 `TARGETING` 返回 `READY`。

## 里程碑

- [x] 设计规则确认
- [x] 创建可恢复进度文件
- [x] 棋盘原子扫描事务与权威标记
- [x] 格子扫描输入、目标描边与结果反馈
- [x] 主界面能量状态机和快捷键
- [x] 陆地机器人/小苗/小怪兽扫描动画
- [x] 海洋关卡备用扫描入口
- [ ] 自动测试与回归测试（扫描及游戏主流程通过；欢迎页旧测试仍有37项失败）
- [ ] 实际游戏视觉确认

## 已修改文件

- `docs/SCAN_ABILITY_PROGRESS.md`：本进度文件。
- `scripts/board.gd`：扫描模式、原子安全/雷区事务、权威标记、键盘/鼠标请求路由。
- `scripts/cell.gd`：青蓝目标框、安全/雷区脉冲、权威确认徽记及扫描输入抑制。
- `scripts/main.gd`：每局状态机、25%阈值、首翻零充能、`C`/Esc输入、棋盘扫描事务接线，以及胜利后“下一关”的未使用能量继承。
- `scenes/land_tabletop_actors.tscn`：机器人透明热点、独立扫描MotionRoot、程序化扫描束及桌面角色反应节点。
- `scripts/land_tabletop_actors.gd`：光点能量表、锁定/充能数值纸签、就绪/目标/结果动画及胜负动画处理仲裁。
- `scenes/main.tscn`：海洋关卡紧凑扫描行、三个能量点、状态文字和按钮。
- `tests/scan_ability_test.gd`：正式扫描规则、能量、取消、旗上限和海洋入口测试。
- `tests/desktop_layout_test.gd`：更新84%桌面界面断言并覆盖机器人热点/海洋入口布局。
- `README.md`：登记扫描测试命令。
- `scripts/quick_action_button.gd`：移除Container子控件的位置Tween，改为围绕中心缩放，避免旧基准坐标把按钮拉到左侧。

## 测试记录

- Godot无界面编辑器导入：通过；`MinesweeperBoard`与`MineCell`脚本可解析。
- 临时棋盘定向测试：`SCAN_BOARD_CHECK_PASS`；覆盖安全扫描、雷区确认、不失败、不可取消及模式退出。
- 临时主流程定向测试：`SCAN_MAIN_CHECK_PASS`；覆盖第1关免费但首翻锁定、取消不消费、雷区扫描使用、第3关阈值和首翻零充能。
- 临时海洋定向测试：`SCAN_OCEAN_CHECK_PASS`；覆盖六边形首翻零充能、备用行显示和充满后按钮启用。
- 正式 `scan_ability_test.gd`：通过。
- 回归通过：`board_smoke_test.gd`、`level_one_board_surface_test.gd`、`adaptive_opening_assist_test.gd`、`ocean_levels_test.gd`、`desktop_layout_test.gd`、`shell_flow_test.gd`、`save_store_test.gd`。
- `welcome_showcase_test.gd`：仍有37项欢迎页舞台/光点旧断言失败；扫描实现未修改欢迎页代码，作为独立既有问题保留。
- 快捷按钮位置定向测试：`QUICK_BUTTON_POSITION_CHECK_PASS`；确认悬停动画不再修改Container分配的x/y位置。
- 修复后复跑：`desktop_layout_test.gd`、`scan_ability_test.gd` 均通过。
- 自适应规则修正及按钮左移后复跑：`adaptive_opening_assist_test.gd`、`desktop_layout_test.gd`、`scan_ability_test.gd` 均通过。
- 临时脚本 `tests/.scan_board_check.gd`、`tests/.scan_main_check.gd`、`tests/.scan_ocean_check.gd`、`tests/.quick_button_position_check.gd` 已删除。

- 本次能量继承与纸签调整已通过Godot资源/脚本解析检查；按用户要求未主动运行回归测试。

## 当前阻塞

- 等待用户人工测试第2关免费扫描、第3–5关充能数值纸签，以及胜利后进入下一关时的未使用能量继承。

## 下一步

根据人工测试反馈调整继承范围或纸签文案；不主动运行回归测试，也不通过预览脚本代替玩家翻开第一格。
