#!/usr/bin/env python3
"""Prepare user-selected Ocean v2 PNGs for Godot runtime use.

Source files remain untouched under docs/art/ver2bygpt. Transparent components
are cropped only to their existing alpha bounds and resized; no masks, shadows,
or replacement artwork are generated.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "art" / "ver2bygpt" / "海洋关卡"
OUTPUT = ROOT / "assets" / "art" / "ocean_v2"


def _resample() -> Image.Resampling:
    return Image.Resampling.LANCZOS


def _save_cover(relative: str, destination: str, size: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGB")
        prepared = ImageOps.fit(image, size, method=_resample(), centering=(0.5, 0.5))
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _visible_bounds(image: Image.Image, threshold: int = 32) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    visible = alpha.point(lambda value: 255 if value >= threshold else 0)
    bounds = visible.getbbox()
    if bounds is None:
        raise ValueError("Artwork contains no visible pixels")
    return bounds


def _save_trimmed(relative: str, destination: str, maximum: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        left, top, right, bottom = _visible_bounds(image)
        padding = max(4, round(max(right - left, bottom - top) * 0.025))
        prepared = image.crop((
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        ))
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
        bounds = _visible_bounds(image, 8)
        prepared = image.crop(bounds).resize(size, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_rotated_trimmed(
    relative: str,
    destination: str,
    maximum: tuple[int, int],
) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        bounds = _visible_bounds(image, 8)
        prepared = image.crop(bounds).rotate(90, expand=True, resample=_resample())
        prepared.thumbnail(maximum, _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def main() -> None:
    _save_cover("海洋背景.png", "background/ocean_background.png", (1280, 720))
    _save_trimmed_exact("三联棋盘2.png", "stage/ocean_triptych_stage.png", (1440, 720))

    components = [
        ("计时框附着条.png", "hud/top_attachment_strip.png", (720, 120)),
        ("剩余雷数显示框.png", "hud/counter_frame.png", (420, 200)),
        ("中间徽记_微笑.png", "hud/robot_emblem_smile.png", (192, 192)),
        ("标记图标.png", "hud/shell_counter_icon.png", (96, 96)),
        ("计时图标.png", "hud/timer_icon.png", (96, 96)),
        ("刷新按钮.png", "buttons/restart_button.png", (192, 192)),
        ("设置按钮.png", "buttons/settings_button.png", (192, 192)),
        ("水草素材左.png", "decorations/seaweed_left.png", (512, 512)),
        ("机制素材/水雷.png", "mechanics/mine.png", (512, 512)),
        ("机制素材/水雷漂浮格.png", "mechanics/mine_floating_cell.png", (512, 512)),
        ("机制素材/水雷停止线.png", "mechanics/mine_stop_line.png", (256, 1024)),
        ("机制素材/潮间带禁止格.png", "mechanics/tidal_locked_cell.png", (512, 512)),
        ("主角机器人/正面/主角机器人正面.png", "characters/ocean_robot_front.png", (512, 512)),
        ("主角机器人/左侧/主角机器人左前.png", "characters/ocean_robot_left_front.png", (512, 512)),
        ("主角机器人/右侧/主角机器人_右前.png", "characters/ocean_robot_right_front.png", (512, 512)),
        ("主角机器人/正面/主角机器人躯干.png", "characters/ocean_robot_front_torso.png", (512, 512)),
        ("主角机器人/正面/主角机器人手臂.png", "characters/ocean_robot_arm.png", (256, 512)),
        ("海洋标记.png", "markers/ocean_marker.png", (320, 320)),
        ("海洋标记_失败.png", "markers/ocean_marker_failed.png", (320, 320)),
        ("海洋标记_错误.png", "markers/ocean_marker_wrong.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼.png", "characters/octopus_alert.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_不服气.png", "characters/octopus_defiant.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_不服气左.png", "characters/octopus_defiant_left.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_不服气右.png", "characters/octopus_defiant_right.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_嘲笑.png", "characters/octopus_mock.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_嘲笑左.png", "characters/octopus_mock_left.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_嘲笑右.png", "characters/octopus_mock_right.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_海洋章鱼_失败.png", "characters/octopus_defeated.png", (640, 512)),
    ]
    for source, destination, maximum in components:
        _save_trimmed(source, destination, maximum)

    cells = [
        ("默认状态棋盘格.png", "cell_hidden.png"),
        ("翻开状态棋盘格.png", "cell_revealed.png"),
        ("污染状态棋盘格.png", "cell_polluted.png"),
    ]
    for source, destination in cells:
        _save_rotated_trimmed(source, f"cells/{destination}", (256, 256))

    for digit in range(1, 7):
        _save_trimmed(
            f"数字显示/{digit}.png",
            f"digits/digit_{digit}.png",
            (192, 192),
        )

    ecology_names = [
        ("第八关_海葵.png", "level_08_anemone.png"),
        ("第九关_海草.png", "level_09_seagrass.png"),
        ("第十关_珊瑚.png", "level_10_coral.png"),
        ("第十一关_水母.png", "level_11_jellyfish.png"),
        ("第十二关_鱼群.png", "level_12_fish_school.png"),
        ("第十三关_海沟.png", "level_13_trench.png"),
        ("第十四关_鲸落.png", "level_14_whale_fall.png"),
    ]
    for source, destination in ecology_names:
        _save_trimmed(
            f"关卡生态元素/{source}",
            f"ecology/{destination}",
            (1024, 512),
        )
        polluted_source = source.removesuffix(".png") + "_污染.png"
        _save_trimmed(
            f"关卡生态元素/{polluted_source}",
            f"ecology/polluted/{destination}",
            (1024, 512),
        )

    badge_names = [
        ("第八关_海葵", "level_08_anemone"),
        ("第九关_海草", "level_09_seagrass"),
        ("第十关_珊瑚", "level_10_coral"),
        ("第十一关_水母", "level_11_jellyfish"),
        ("第十二关_鱼群", "level_12_fish_school"),
        ("第十三关_海沟", "level_13_trench"),
        ("第十四关_鲸落", "level_14_whale_fall"),
    ]
    for source_stem, destination_stem in badge_names:
        _save_trimmed(
            f"关卡生态元素/{source_stem}_徽章.png",
            f"badges/zh/{destination_stem}.png",
            (512, 640),
        )
        _save_trimmed(
            f"关卡生态元素/{source_stem}_英文徽章.png",
            f"badges/en/{destination_stem}.png",
            (512, 640),
        )

    print(f"Prepared Ocean v2 runtime artwork in {OUTPUT}")


if __name__ == "__main__":
    main()
