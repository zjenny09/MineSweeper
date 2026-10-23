# 《绿色扫雷》美术素材维护说明

> 美术图案本身保存在资源文件中；Excel 通过永久代号、当前路径和 SHA-256 精确维护每一项素材。  
> 人工维护主文件：[`GAME_ART_CATALOG.xlsx`](GAME_ART_CATALOG.xlsx)  
> AI 重制提示词：[`AI_ART_PROMPT_SYSTEM.md`](AI_ART_PROMPT_SYSTEM.md)

## 一、永久美术代号

每项正式视觉资源使用一个永久内部代号：

```text
ART_0001
ART_0002
...
```

代号不因以下变化而改变：

- 文件移动或改名；
- 图片内容重制；
- 程序引用位置变化；
- 素材暂时停用或文件缺失。

旧代号禁止回收复用。新增素材只从历史最大编号继续追加，避免 Excel、程序和美术文件错位。

## 二、中文素材名与短名规则

### 中文素材名

Excel 的“素材名称（中文）”必须让人不看路径就能直接理解具体内容和状态，例如：

```text
主菜单主按钮（悬停）
陆地暂停按钮（按下）
海洋珊瑚标记（错误）
天空第20关雷眼生态（失败）
```

不能只写“按钮”“背景”“角色”这类大类。该列可人工精修，并通过永久 `ART_####` 与文件保持关联。

### 规范短名

每项素材另有一个便于程序和文件维护的规范短名：

```text
<范围>_<内容>_<状态>
```

例如：

```text
wel_landscape_base
land_pause_normal
ocean_l10_whale_fall_healthy
sky_hexagon_hidden_surface
space_universe_nebula
```

规则：

- 使用小写英文和数字，以 `_` 分隔；
- 最长 36 个字符；
- 在整个项目中唯一；
- 表达大致内容、使用章节和状态，不承担永久身份；
- 短名可以精修，永久 `ART_####` 代号不能修改。

范围前缀包括：`cmn`、`play`、`tut`、`wel`、`land`、`map`、`ocean`、`sky`、`space`、`font`。

## 三、Excel 美术总表

文件：`docs/art/GAME_ART_CATALOG.xlsx`

主表列包括：

|列|用途|
|---|---|
|代号|永久 `ART_####` 键，禁止修改或复用|
|规范短名|唯一的英文简短语义名，可人工精修|
|素材名称（中文）|直接写清章节、具体对象和状态，例如“海洋暂停按钮（悬停）”|
|内容说明|素材内容和用途补充说明|
|章节/范围、类别、状态/变体|筛选和分组|
|当前路径|实际 `res://` 资源路径；移动时在原代号上更新|
|文件格式、尺寸、透明通道、大小、SHA-256|工具自动读取的文件元数据|
|运行状态|运行中、已登记、未引用或文件缺失|
|程序别名、使用位置|自动扫描结果，仅供定位，不参与身份关联|
|提示词代号|关联 AI 提示词体系中的 `PRM_*` 条目|
|重制状态|待评估、保留、待重制、重制中、已确认|
|权利状态|待复核、已确认商用、需替换|
|来源/生成工具、商用凭证|记录生成平台、日期、订单、条款截图等证据|
|修改备注、审核状态|维护过程和人工确认|

附加工作表：

- `命名规则`：永久代号、短名和文件名规则；
- `提示词索引`：`PRM_*` 代号、用途及提示词文档入口；
- `枚举与状态`：各维护状态的含义；
- `使用说明`：人工编辑和同步步骤；
- 隐藏 `元数据`：表结构版本与条目数量。

## 四、提示词关联

每一项素材在“提示词代号”列关联一个最接近的任务模板，例如：

- `PRM_ROBOT`：小芽机器人及章节变体；
- `PRM_MONSTER`：污染怪；
- `PRM_BG_LAND` / `PRM_BG_OCEAN` / `PRM_BG_SKY` / `PRM_BG_SPACE`：章节背景；
- `PRM_CELL_LAND` / `PRM_CELL_OCEAN` / `PRM_CELL_SKY`：棋盘格；
- `PRM_ECOLOGY`：健康与失败生态主体；
- `PRM_MAP` / `PRM_MAP_NODE`：章节地图和节点。

重制时先使用 `PRM_STYLE` 全局母提示词，再追加该素材对应的任务模板。Excel 只维护关联关系，完整提示词仍以 `docs/art/AI_ART_PROMPT_SYSTEM.md` 为准。

## 五、同步命令

在项目根目录执行：

```bash
python tools/art_catalog.py initialize
python tools/art_catalog.py discover
python tools/art_catalog.py export
python tools/art_catalog.py import
python tools/art_catalog.py validate
```

- `initialize`：仅用于首次建立目录；已有 JSON 时拒绝再次编号。
- `discover`：扫描正式资源树，保留旧代号，只为新文件追加代号；若移动前后 SHA-256 唯一一致，会保留原代号。
- `export`：根据 JSON 和当前文件重新生成 Excel 与 Godot 查询表。执行前先导入尚未同步的 Excel 修改。
- `import`：按永久代号将 Excel 可编辑字段同步到 JSON，再重建 Excel 和 Godot 查询表。
- `validate`：检查代号、短名、路径、文件元数据、Excel、提示词、程序查询表和引用一致性。

## 六、新增、移动与替换

### 新增素材

1. 将正式文件放入 `assets/art/`、`assets/fonts/` 或 `shaders/` 的对应目录；
2. 执行 `discover`；
3. 在 Excel 填写来源、权利、凭证、重制和审核信息；
4. 执行 `import` 和 `validate`；
5. 如需运行引用，增加或更新 `ArtCatalog` 语义常量。

### 移动或改名

保留原 `ART_####`，只修改该行“当前路径”。不要删除旧行后重新发现。`discover` 也会对唯一 SHA-256 匹配的移动自动保留代号。

### 原位重制

在同一路径替换图片后继续使用原代号；工具会更新尺寸、大小和 SHA-256。必须同步填写生成来源、商用凭证与审核结果。

### 停用或缺失

条目仍保留，运行状态标为“文件缺失”或“未引用”。禁止把该代号分配给另一张图。

## 七、程序接口

`scripts/art_ids.gd` 由工具生成，不手工编辑。`scripts/art_catalog.gd` 保留原有语义常量，并提供：

```gdscript
ArtCatalog.path_for(&"ART_0001")
ArtCatalog.short_name_for(&"ART_0001")
ArtCatalog.id_for_path("res://assets/art/...")
```

程序引用与 Excel 同步都以永久代号或当前路径为准，不依赖源码行号。

## 八、审核边界

结构校验只能确认数据一致，不代表：

- 画风、布局或缩放效果已经通过；
- 自动抠图边缘或生成阴影可直接用于正式版本；
- AI 平台生成内容一定具备商用权；
- 素材来源和第三方元素已经完成法律审核。

最终视觉效果必须在真实游戏中展示并由用户人工确认；权利状态必须由可保存的条款、订单和生成记录支持。
