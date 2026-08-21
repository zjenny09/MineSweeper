# Green Sweeper

使用 Godot 4.7.2 Standard 和 GDScript 制作的生态主题关卡制扫雷游戏。

## 当前版本：v0.2.0 第一关“萌芽”

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

## Windows 导出

项目已经包含 `Windows Desktop` 导出预设。安装与 Godot 4.7.2 匹配的导出模板后，可以在编辑器的 **项目 → 导出** 中点击“导出项目”，也可以执行：

```text
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --export-release "Windows Desktop" D:\o!mygame\minesweeper\build\windows\GreenSweeper.exe
```

导出结果位于 `build/windows/`，该目录不会提交到 Git。

## 运行测试

```text
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\o!mygame\minesweeper --script res://tests/board_smoke_test.gd
```
