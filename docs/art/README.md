# 美术资料

本目录集中保存美术维护与历史资料，正式运行素材仍位于 `assets/art/`、`assets/fonts/` 和 `shaders/`。

## 核心维护文件

- [`GAME_ART_CATALOG.xlsx`](GAME_ART_CATALOG.xlsx)：人工维护主表；“素材名称（中文）”列直接说明具体对象与状态。
- [`GAME_ART_CATALOG.json`](GAME_ART_CATALOG.json)：机器清单。
- [`GAME_ART_CATALOG.md`](GAME_ART_CATALOG.md)：编号、命名和同步说明。
- [`AI_ART_PROMPT_SYSTEM.md`](AI_ART_PROMPT_SYSTEM.md)：统一AI美术提示词体系。
- [`ART_CATALOG_PROGRESS.md`](ART_CATALOG_PROGRESS.md)：目录建设进度。

## 资料分区

- `ui_history/`：原始概念、旧版候选和来源参考，不得直接作为运行素材。
- `asset_reviews/`：抠图、边缘和构图审核图。
- `previews/`：游戏内视觉预览与阶段截图。
- `Green_Sweeper_美术素材规格表_V1.0.xlsx`：早期美术规格表。
- `配色方案讨论.docx`：配色讨论资料。

新增正式素材后仍使用：

```bash
python tools/art_catalog.py discover
python tools/art_catalog.py import
python tools/art_catalog.py validate
```
