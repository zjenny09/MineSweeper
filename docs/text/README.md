# 文案与本地化资料

本目录集中保存中英文文案维护资料。游戏运行目录仍位于 `localization/`，程序和场景继续使用永久 `TXT_####` 代号。

- [`GAME_COPY_CATALOG.xlsx`](GAME_COPY_CATALOG.xlsx)：中文与英文人工精修主表。
- [`GAME_COPY_CATALOG.md`](GAME_COPY_CATALOG.md)：文案编号和同步说明。
- [`LOCALIZATION_PROGRESS.md`](LOCALIZATION_PROGRESS.md)：中英双语接入进度。

维护命令：

```bash
python tools/copy_catalog.py import
python tools/copy_catalog.py export
python tools/copy_catalog.py validate
```

新增文案继续追加从未使用过的 `TXT_####`，不得依赖源码行号，也不得复用旧代号。
