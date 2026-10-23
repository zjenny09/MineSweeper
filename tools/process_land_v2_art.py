#!/usr/bin/env python3
"""Prepare approved-for-preview Land v2 source PNGs for Godot runtime use.

The source files remain untouched under docs/art/ver2bygpt. Standalone RGBA
components are only trimmed to their existing alpha bounds and resized; this
script does not create masks, cutouts, shadows, or synthetic artwork.
"""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "art" / "ver2bygpt"
OUTPUT = ROOT / "assets" / "art" / "land_v2"


def _resample() -> Image.Resampling:
    return Image.Resampling.LANCZOS


def _save_cover(relative: str, destination: str, size: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGB")
        prepared = ImageOps.fit(image, size, method=_resample(), centering=(0.5, 0.5))
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_scaled(relative: str, destination: str, maximum: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        image.thumbnail(maximum, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, optimize=True)


def _save_trimmed(relative: str, destination: str, maximum: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        visible = alpha.point(lambda value: 255 if value >= 32 else 0)
        bounds = visible.getbbox()
        if bounds is None:
            raise ValueError(f"No visible pixels in {relative}")
        left, top, right, bottom = bounds
        padding = max(4, round(max(right - left, bottom - top) * 0.025))
        crop_box = (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
        prepared = image.crop(crop_box)
        prepared.thumbnail(maximum, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_trimmed_exact(
    relative: str,
    destination: str,
    size: tuple[int, int],
) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        visible = alpha.point(lambda value: 255 if value >= 8 else 0)
        bounds = visible.getbbox()
        if bounds is None:
            raise ValueError(f"No visible pixels in {relative}")
        prepared = image.crop(bounds).resize(size, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_inset_exact(
    relative: str,
    destination: str,
    size: tuple[int, int],
    inset_ratio: float,
) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        inset_x = round(image.width * inset_ratio)
        inset_y = round(image.height * inset_ratio)
        prepared = image.crop((
            inset_x,
            inset_y,
            image.width - inset_x,
            image.height - inset_y,
        )).resize(size, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _copy_document() -> None:
    source = SOURCE / "陆地关卡" / "UI_LAYOUT_SPEC_v1.1_完整组件尺寸.md.md"
    target = OUTPUT / "SOURCE_LAYOUT_SPEC.md"
    target.parent.mkdir(parents=True, exist_ok=True)
    copy2(source, target)


def main() -> None:
    _save_cover("陆地关卡/关卡背景.png", "background/land_valley_background.png", (1280, 720))
    _save_trimmed_exact(
        "陆地关卡/三联棋盘2.png",
        "stage/land_triptych_stage.png",
        (1440, 720),
    )

    components = [
        ("陆地关卡/计时框附着条.png", "hud/top_attachment_strip.png", (720, 120)),
        ("陆地关卡/剩余雷数显示框.png", "hud/counter_frame.png", (420, 200)),
        ("陆地关卡/中间徽记_微笑.png", "hud/robot_emblem_smile.png", (192, 192)),
        ("陆地关卡/标记图标.png", "hud/sprout_counter_icon.png", (96, 96)),
        ("陆地关卡/计时图标.png", "hud/timer_icon.png", (96, 96)),
        ("陆地关卡/开始暂停按钮.png", "buttons/pause_button.png", (256, 192)),
        ("陆地关卡/刷新按钮.png", "buttons/restart_button.png", (192, 192)),
        ("陆地关卡/面板设置按钮.png", "buttons/settings_button.png", (192, 192)),
        ("陆地关卡/藤曼素材左.png", "decorations/vine_left.png", (512, 512)),
        ("陆地关卡/藤曼素材右.png", "decorations/vine_right.png", (512, 512)),
        ("陆地关卡/机制素材/障碍格.png", "mechanics/obstacle.png", (256, 256)),
        ("陆地关卡/机制素材/根瘤根系_直线.png", "mechanics/root_active_straight.png", (512, 512)),
        ("陆地关卡/机制素材/根瘤根系_拐弯.png", "mechanics/root_active_corner.png", (512, 512)),
        ("陆地关卡/机制素材/净化根系_直线.png", "mechanics/root_cleansed_straight.png", (512, 512)),
        ("陆地关卡/机制素材/净化根系_拐弯.png", "mechanics/root_cleansed_corner.png", (512, 512)),
        ("陆地关卡/机制素材/污染核心主树.png", "mechanics/boss_tree_active.png", (1024, 1024)),
        ("陆地关卡/机制素材/污染主树净化.png", "mechanics/boss_tree_cleansed.png", (1024, 1024)),
        ("陆地关卡/陆地标记.png", "markers/sprout_healthy.png", (320, 320)),
        ("陆地关卡/陆地标记_枯萎.png", "markers/sprout_wilted.png", (320, 320)),
        ("陆地关卡/陆地标记_cuowu .png", "markers/wrong_flag_feedback.png", (512, 512)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆.png", "characters/pollution_slime_alert.png", (512, 512)),
        ("陆地关卡/主角机器人/正面/主角机器人正面.png", "characters/sprout_robot_front.png", (512, 512)),
        ("陆地关卡/主角机器人/左侧/主角机器人左前.png", "characters/sprout_robot_left_front.png", (512, 512)),
        ("陆地关卡/主角机器人/右侧/主角机器人_右前.png", "characters/sprout_robot_right_front.png", (512, 512)),
        ("陆地关卡/主角机器人/右侧/主角机器人_躯干.png", "characters/sprout_robot_right_front_torso.png", (512, 512)),
        ("陆地关卡/主角机器人/正面/主角机器人手臂.png", "characters/sprout_robot_arm.png", (256, 512)),
        ("陆地关卡/主角机器人/正面/主角机器人爪子.png", "characters/sprout_robot_claw.png", (256, 256)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气.png", "characters/pollution_slime_defiant_a.png", (512, 512)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气2.png", "characters/pollution_slime_defiant_b.png", (512, 512)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气3.png", "characters/pollution_slime_defiant_c.png", (512, 512)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_嘲笑.png", "characters/pollution_slime_mock.png", (512, 512)),
        ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_被打倒.png", "characters/pollution_slime_defeated.png", (512, 512)),
    ]
    for source, destination, maximum in components:
        _save_trimmed(source, destination, maximum)

    _save_inset_exact(
        "陆地关卡/机制素材/根瘤节点.png",
        "mechanics/pollution_node_active.png",
        (256, 256),
        0.045,
    )
    _save_inset_exact(
        "陆地关卡/机制素材/根瘤节点_净化.png",
        "mechanics/pollution_node_cleansed.png",
        (256, 256),
        0.045,
    )

    cells = [
        ("默认状态棋盘纸.png", "cell_hidden.png"),
        ("翻开状态棋盘纸.png", "cell_revealed.png"),
        ("污染状态棋盘纸.png", "cell_polluted.png"),
    ]
    for source_name, destination in cells:
        _save_scaled(
            f"陆地关卡/{source_name}",
            f"cells/{destination}",
            (256, 256),
        )

    for digit in range(1, 9):
        _save_trimmed(
            f"陆地关卡/数字显示/number_{digit}.png",
            f"digits/digit_{digit}.png",
            (192, 192),
        )

    ecology_names = [
        ("第一关_萌芽", "level_01_sprout"),
        ("第二关_灌木", "level_02_shrub"),
        ("第三关_湿地", "level_03_wetland"),
        ("第四关_草原", "level_04_grassland"),
        ("第五关_林缘", "level_05_forest_edge"),
        ("第六关_密林", "level_06_dense_forest"),
        ("第七关_古林", "level_07_ancient_forest"),
    ]
    for source_stem, destination_stem in ecology_names:
        _save_trimmed(
            f"陆地关卡/关卡生态元素/{source_stem}.png",
            f"ecology/{destination_stem}_healthy.png",
            (768, 512),
        )
        _save_trimmed(
            f"陆地关卡/关卡生态元素/{source_stem}_污染.png",
            f"ecology/{destination_stem}_polluted.png",
            (768, 512),
        )

    victory_ecology = [
        ("第一关_萌芽_胜利展示生态世界.png", "level_01_sprout_victory.png"),
        ("第二关_灌木_胜利展示生态世界..png", "level_02_shrub_victory.png"),
        ("第三关_湿地_胜利展示生态世界.png", "level_03_wetland_victory.png"),
        ("第四关_草原_胜利展示生态世界.png", "level_04_grassland_victory.png"),
        ("第五关_林缘_胜利展示生态世界.png", "level_05_forest_edge_victory.png"),
        ("第六关_密林_胜利展示生态世界.png", "level_06_dense_forest_victory.png"),
        ("第七关_古林_胜利展示生态世界.png", "level_07_ancient_forest_victory.png"),
    ]
    for source_name, destination in victory_ecology:
        _save_trimmed(
            f"陆地关卡/关卡生态元素/{source_name}",
            f"ecology/victory/{destination}",
            (1024, 768),
        )

    _save_scaled("勋章本.png", "badges/badge_book.png", (1152, 864))
    _save_trimmed("勋章本翻页按钮.png", "badges/page_turn.png", (256, 256))
    badge_names = [
        ("第一关_萌芽", "level_01_sprout"),
        ("第二关_灌木", "level_02_shrub"),
        ("第三关_湿地", "level_03_wetland"),
        ("第四关_草原", "level_04_grassland"),
        ("第五关_林缘", "level_05_forest_edge"),
        ("第六关_密林", "level_06_dense_forest"),
        ("第七关_古林", "level_07_ancient_forest"),
    ]
    for source_stem, destination_stem in badge_names:
        _save_trimmed(
            f"陆地关卡/关卡生态元素/{source_stem}_勋章.png",
            f"badges/zh/{destination_stem}.png",
            (512, 640),
        )
        _save_trimmed(
            f"陆地关卡/关卡生态元素/{source_stem}_英文勋章.png",
            f"badges/en/{destination_stem}.png",
            (512, 640),
        )

    _copy_document()
    print(f"Prepared Land v2 runtime artwork in {OUTPUT}")


if __name__ == "__main__":
    main()
