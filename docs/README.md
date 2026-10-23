# 项目文档目录

文档按维护对象分为三个固定入口：

|目录|内容|主要入口|
|---|---|---|
|[`art/`](art/README.md)|美术目录、AI提示词、规格、历史源图、审核图和预览图|`art/GAME_ART_CATALOG.xlsx`|
|[`copy/`](copy/README.md)|中英文文案目录及本地化维护记录|`copy/GAME_COPY_CATALOG.xlsx`|
|[`audio/`](audio/README.md)|背景音乐、音效源文件及接入记录|`audio/AUDIO_INTEGRATION_PROGRESS.md`|

根目录保留的是跨系统或具体玩法功能的设计与开发进度文档，例如陆地、海洋、天空、宇宙、扫描机制和UI改版记录。不要再将美术、文案或音频文件直接放在 `docs/` 根目录。

## 存放规则

- 正式运行资源仍放在 `assets/`、`shaders/` 等运行目录；`docs/` 只保存维护表、设计资料、来源文件和进度记录。
- 新美术维护资料进入 `docs/art/`。
- 新文案维护资料进入 `docs/copy/`。
- 新音乐或音效来源资料进入 `docs/audio/`。
- `docs/.gdignore` 阻止 Godot 将文档素材误当作运行资源重新导入。
