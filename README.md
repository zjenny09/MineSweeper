# Minesweeper（扫雷）

这是一个使用 Godot 4.7.2 Standard 和 GDScript 制作的入门项目，目标是熟悉游戏项目结构、基础脚本、测试和 Windows 导出流程。

## 当前目标

- 9 × 9 棋盘
- 10 颗地雷
- 左键翻开格子
- 右键插旗或取消旗帜
- 首次点击安全
- 点击数字格时只翻开该格并显示数字
- 点击0格时展开相连的0格，直到外围数字边界
- 0格保持空白，边界数字显示1～8
- 胜利、失败和重新开始

## 打开项目

1. 启动 Godot 4.7.2。
2. 点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 点击 **Import & Edit**。
5. 按 `F6` 运行当前场景，或按 `F5` 运行整个项目。

也可以从命令行启动：

```text
D:\GameDev\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe --editor --path D:\o!mygame\minesweeper
```

## 操作

- 左键：翻开格子
- 右键：插旗或取消旗帜
- 重新开始：生成一局新游戏

## 目录

```text
scenes/    Godot 场景
scripts/   GDScript 脚本
tests/     无窗口冒烟测试
build/     导出产物（不提交到 Git）
```

## 后续导出

玩法验证通过后，在 Godot 中安装与 4.7.2 匹配的导出模板，再添加 **Windows Desktop** 导出预设。Windows 构建输出到 `build/windows/`。
