# 《绿色清扫者》文案维护说明

> 当前文案不再依赖中文原句或源码行号进行匹配。  
> 人工精修主文件：[`GAME_COPY_CATALOG.xlsx`](GAME_COPY_CATALOG.xlsx)

## 一、稳定文案代号

游戏内每条文案现在使用永久内部代号：

```text
TXT_0001
TXT_0002
...
TXT_0460
```

程序、场景、中文翻译和英文翻译都通过同一个代号关联。例如：

```gdscript
tr("TXT_0002")
```

代号只用于程序内部，不会作为正常界面文案显示。实际显示内容来自：

- `localization/green_sweeper.zh_CN.po`
- `localization/green_sweeper.en.po`

因此，后续代码增加、删除或移动行号，都不会造成 Excel、中文和英文之间错位。

## 二、Excel 文案总表

文件：`docs/copy/GAME_COPY_CATALOG.xlsx`

当前共收录 **460 条**带永久代号的文案，主要列为：

|列|用途|
|---|---|
|代号|程序永久键，禁止修改|
|分类|主菜单、设置、地图、引导、海洋、天空、宇宙等|
|状态|运行、旧版、开发、非独立显示|
|中文|当前简体中文文案，可人工精修|
|English|当前英文文案，可人工精修|
|占位符|必须保留的 `%d`、`%s`、`%02d`、`%.1f` 等|
|使用位置|仅供定位参考，不参与同步|
|修改备注|记录修改原因|
|审核状态|待复核、修改中、已确认|

Excel 另含：

- `术语表`：用于统一“翻开、净化、标记、污染核心、快速展开”等核心术语；
- `使用说明`：记录人工编辑与同步流程；
- 隐藏元数据表：记录目录结构版本和条目数量。

## 三、人工精修方式

1. 打开 `docs/copy/GAME_COPY_CATALOG.xlsx`。
2. 按“分类”筛选需要复核的文案。
3. 只修改“中文”和“English”列。
4. 保持“代号”不变。
5. 原样保留“占位符”列列出的全部格式符，数量和顺序都不能变化。
6. 填写“修改备注”，将“审核状态”改为“修改中”或“已确认”。
7. 保存 Excel。

## 四、将 Excel 同步回游戏

在项目根目录执行：

```bash
python tools/copy_catalog.py import
```

该命令会先检查：

- 文案代号是否缺失、重复或被改动；
- 中文和英文占位符是否仍与程序参数一致；
- Excel 是否包含完整的 460 条记录。

验证通过后，自动同步：

- `localization/copy_catalog.json`
- `localization/green_sweeper.zh_CN.po`
- `localization/green_sweeper.en.po`

不会依据源码行号回写，也不会因为程序中间增加代码而产生错位。

## 五、维护命令

### Excel → 游戏翻译目录

```bash
python tools/copy_catalog.py import
```

### 游戏文案目录 → 重新生成 Excel

```bash
python tools/copy_catalog.py export
```

> 执行 export 前，应先确保尚未同步的 Excel 修改已经执行过 import，否则新导出的文件会覆盖未导入内容。

### 完整一致性检查

```bash
python tools/copy_catalog.py validate
```

检查内容包括：

- 永久代号格式和唯一性；
- JSON、中文 PO、英文 PO 的代号集合和顺序；
- 中英文占位符；
- 程序与场景引用的代号是否存在。

## 六、新增文案规则

新增文案时：

1. 分配一个从未使用过的新代号；
2. 即使旧文案被删除，也不要复用旧代号；
3. 在 `copy_catalog.json` 和 Excel 中新增对应记录；
4. 中文、英文和程序使用同一代号；
5. 执行 `import` 与 `validate`；
6. 打开真实游戏检查长度、换行与语气。

## 七、文件职责

|文件|职责|
|---|---|
|`docs/copy/GAME_COPY_CATALOG.xlsx`|人工精修与审核主表|
|`localization/copy_catalog.json`|适合版本控制和程序处理的文案清单|
|`localization/green_sweeper.zh_CN.po`|Godot 简体中文运行目录|
|`localization/green_sweeper.en.po`|Godot 英文运行目录|
|`tools/copy_catalog.py`|Excel、JSON、PO 同步与验证工具|
|程序和场景中的 `TXT_####`|稳定文案引用，不随中文修改|

源码位置现在仅作为定位参考，不再承担中文、英文或 Excel 的关联关系。
