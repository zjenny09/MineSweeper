# 海洋篇实施进度

更新时间：2026-09-02

## 固定关卡结构

1. 第6关「潮池初醒」：5×5尖顶错行六边形，5个污染核心
2. 第7关「海草摇篮」：6×6，7个污染核心
3. 第8关「珊瑚花园」：7×7，10个污染核心
4. 第9关「海藻森林」：8×8，14个污染核心
5. 第10关「深海鲸落」：10×9，22个污染核心

## 固定美术规则

- 第6–10关统一使用 `海洋关卡棋盘概念图/棋盘和棋盘格/桌面背景.png`。
- 棋盘托改用 `棋盘托2.png`；删除暖珊瑚背景、水印和外部落地投影，保留深蓝结构、左右米白纸与结构自阴影；中央米白内芯挖为透明窗口。
- 状态映射不可调换：
  - `棋盘格 (1).png` = 默认/隐藏
  - `棋盘格 (2).png` = 翻开
  - `棋盘格 (3).png` = 污染
- 海洋普通插旗与胜利确认使用 `UI元素/标记珊瑚 (1).png`；失败后的正确旗和失败时的权威确认使用 `标记珊瑚 (2).png`；错误旗使用 `标记珊瑚3.png`（原怪兽抱小芽对应状态）。失败动画结束后，所有未标记格统一使用污染格3；任何已标记/权威确认格保留非污染底格与对应珊瑚。陆地小芽及陆地失败动画不变。
- 六边形仍为 `hex_pointy_odd_r`，最多6邻居；不修改关卡尺寸、雷数、命中多边形和扫描规则。
- 动态棋盘为暖米白纸，按六边形实际范围自适应，但必须保留空白纸边。
- 相邻格之间使用浅蓝色虚线凹痕；共享边只绘制一次。
- 鼠标悬停和键盘选中仍使用格子内部虚线，颜色改为海洋主题。
- 右侧暂停/重开按钮节点、逻辑、88px尺寸和位置不变，只替换海洋颜色/纸材质。
- 第1–5关陆地背景、角色、贴纸、按钮和扫描入口不受影响。

## 明确不做

- 不覆盖 `docs/ui_history` 中的源图。
- 不修改六边形邻接、首翻规则、难度和扫描能量规则。
- 不使用后台Agent；后续只执行前台、范围明确的步骤。
- 不把自动抠图边缘、临时阴影或未经用户观看的画面标记为最终通过。

## 实施里程碑

- [x] 六边形基础玩法原型
- [x] 固定素材映射与实施方案
- [x] 建立可恢复进度记录
- [x] 清理桌面背景水印
- [x] 提取透明棋盘托框
- [x] 提取默认/翻开/污染三种格子
- [x] 四色背景检查并获得用户确认
- [x] 搭建海洋桌面与托盘宏观舞台
- [ ] 1280×720/800宏观构图确认（实现与自动布局检查已完成，等待用户观看确认）
- [x] 动态米白纸张与浅蓝虚线凹痕（实现和自动测试已完成，等待用户观看确认）
- [x] 海洋格子纹理、数字和内部焦点（实现和自动测试已完成，等待用户实际操作确认）
- [x] 海洋暂停/重开按钮皮肤（普通态保持原纸材，海洋交互态和右上微调已实现，等待用户确认）
- [x] 海洋珊瑚标记：正常珊瑚1、正确失败珊瑚2、错误旗珊瑚3
- [x] 海洋失败污染规则：所有未标记格变为污染格，已标记格保持对应珊瑚与非污染底格
- [ ] 自动测试与回归测试
- [ ] 第6关和第10关实际视觉确认

## 已修改文件

- `docs/OCEAN_CHAPTER_PROGRESS.md`：本次迁移的恢复入口。
- `docs/ui_history/海洋关卡棋盘概念图/棋盘和棋盘格/processed_candidates/ocean_desktop_clean_candidate.png`：1600×900无水印候选。
- `.../ocean_board_tray_frame_candidate.png`：第一版浅蓝托盘候选，因与背景对比不足已停用。
- `.../ocean_board_tray_frame2_candidate.png`：从 `棋盘托2.png` 提取的1600×900深蓝透明托盘，中央动态纸张窗口已挖空。
- `.../ocean_board_tray_frame2_transparency_check.png`：深蓝托盘四色透明边缘检查。
- `.../ocean_cell_hidden_candidate.png`：棋盘格1，已旋转为尖顶并透明紧裁。
- `.../ocean_cell_revealed_candidate.png`：棋盘格2，已旋转为尖顶并透明紧裁。
- `.../ocean_cell_polluted_candidate.png`：棋盘格3，透明紧裁。
- `.../ocean_asset_transparency_check.png`：托盘合成与三种格子四色背景检查。
- `assets/art/ocean_levels/background/ocean_desktop_clean.png`：用户确认后的正式背景。
- `assets/art/ocean_levels/stage/ocean_board_tray_frame.png`：正式运行托盘已按用户反馈替换为 `棋盘托2.png` 的深蓝透明版本。
- `assets/art/ocean_levels/board/cells/ocean_cell_{hidden,revealed,polluted}.png`：正式三态格子。
- `scenes/main.tscn`：新增 `OceanStage`、共享海洋桌面背景、中央临时米白纸与透明托盘框。
- `scripts/main.gd`：第6–10关启用海洋舞台、停用旧 `EcoShowcase`，并让海洋舞台与 `PageMargin` 共用1280×720 aspect-cover变换。
- `tests/desktop_layout_test.gd`：覆盖第6关海洋节点切换及1280×720/800同构变换。
- `scripts/board.gd`：记录六边形实际包围框、绘制动态纸张与去重凹痕；海洋关卡失败时也启动全格污染动画。
- `scripts/cell.gd`：严格接入棋盘格1/2/3、海洋数字与格内焦点；普通旗/胜利确认绘制珊瑚1，失败正确旗绘制珊瑚2，错误旗绘制珊瑚3，并从污染底格切换中排除所有已标记格。
- `assets/art/ocean_levels/buttons/ocean_{pause,regenerate}_{normal,hover,focus,pressed}.png`：海洋快捷按钮四态；普通态保持原有米白纸材，交互态改为浅水蓝纸材并保留源纹理与源投影。
- `scripts/main.gd`：按陆地/海洋章节切换按钮纹理和文字色；海洋按钮行从 `(-10,458)` 微调至 `(2,446)`，即向右12、向上12设计像素。
- `docs/ui_history/海洋关卡棋盘概念图/UI元素/processed_candidates/ocean_flag_coral_{normal,failed}_candidate.png`：标记珊瑚1/2的透明候选。
- `.../ocean_flag_coral_transparency_check.png`：正常与失败珊瑚的四色透明边缘检查。
- `assets/art/ocean_levels/markers/ocean_flag_coral_{normal,failed}.png`：海洋普通与正确失败标记正式运行素材。
- `docs/ui_history/海洋关卡棋盘概念图/UI元素/processed_candidates/ocean_flag_coral_wrong_candidate.png`：从标记珊瑚3提取的错误旗透明候选。
- `.../ocean_flag_coral_wrong_transparency_check.png`：错误旗珊瑚3的四色透明边缘检查。
- `assets/art/ocean_levels/markers/ocean_flag_coral_wrong.png`：海洋错误旗正式运行素材。
- `scripts/art_catalog.gd`：登记海洋舞台、格子、按钮及珊瑚标记素材。
- `tests/ocean_levels_test.gd`：覆盖5种海洋棋盘纸张包围、空白纸边、安全窗口限制、共享边唯一性、三态纹理及珊瑚标记映射。
- `docs/ocean_cell_theme_level6.png`：第6关正式隐藏格与鼠标悬停实机截图，未自动代替玩家翻开格子。
- `docs/ocean_dynamic_paper_level6.png`：第6关动态纸张与凹痕实机截图，等待用户确认。
- `docs/ocean_stage_level6_1280x720.png`：第6关深蓝托盘宏观舞台实机截图。

## 测试记录

- 素材尺寸：背景/托盘1600×900；默认451×512；翻开450×512；污染437×512。
- 桌面水印仅在米白区域内修复，蓝色波浪边界未被覆盖。
- 托盘2删除暖珊瑚背景、外投影和水印；保留左右信息纸、深蓝结构与中央内框自阴影，并已生成四色透明背景检查图供用户判断边缘。
- 棋盘格1/2源图为平顶方向，已统一旋转90°匹配现有尖顶odd-r棋盘。
- Godot无界面编辑器导入通过；海洋背景、托盘、三态格子、按钮和珊瑚标记均已成功导入。
- 扩展后的 `ocean_levels_test.gd` 通过：5种棋盘的动态纸张、共享边、三态纹理均符合固定映射；普通旗使用珊瑚1，失败正确旗使用珊瑚2，错误旗使用珊瑚3；棋盘级失败回归确认所有未标记格污染量为1、所有已标记格污染量为0。
- `desktop_layout_test.gd` 通过：陆地按钮仍位于 `(-10,458)` 并使用陆地素材；海洋按钮位于 `(2,446)`、加载海洋四态纹理且两按钮不重叠；1280×720/800对齐保持不变。
- `board_smoke_test.gd` 与 `scan_ability_test.gd` 通过，珊瑚标记替换未改变旗计数、权威确认、命中多边形或扫描规则。
- 用户已确认珊瑚1/2/3素材无问题；三种素材均已安装到正式运行目录并由游戏实际加载。
- 第6关已用正式启动参数渲染并保存 `docs/ocean_cell_theme_level6.png`；预览未自动翻开安全格，翻开、数字和污染状态由用户在正式游戏中操作判断。

## 当前阻塞

- 第10关10×9最大棋盘已按用户要求直接打开，等待用户人工测试反馈。

## 下一步唯一入口

不主动运行最终回归测试；根据用户在第10关对纸张范围、格子密度、数字、标记、失败污染和扫描入口的人工测试结果继续调整。
