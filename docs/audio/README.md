# 音频资料

本目录集中保存背景音乐与音效的来源资料和接入记录。游戏实际运行文件仍位于 `assets/audio/`。

- [`AUDIO_INTEGRATION_PROGRESS.md`](AUDIO_INTEGRATION_PROGRESS.md)：音频接入与背景音乐问题处理记录。
- [`source/`](source/README.md)：原始WAV、生成器源码、压缩包和使用说明。

`source/` 只用于追溯和重新生成，不应被运行代码直接引用。将来源音频接入游戏时，应复制到 `assets/audio/`，再通过 Godot 导入资源使用。
