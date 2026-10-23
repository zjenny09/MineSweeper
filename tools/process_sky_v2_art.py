#!/usr/bin/env python3
"""Prepare user-selected Sky v2 PNGs for Godot runtime use.

Source files remain untouched under docs/art/ver2bygpt. Transparent components
are cropped only to their existing alpha bounds and resized; no masks, shadows,
or replacement artwork are generated. The broken RGB checkerboard variant
`污染小怪兽_天空雾霾_不服气右.png` is intentionally excluded.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "art" / "ver2bygpt" / "天空关卡"
OUTPUT = ROOT / "assets" / "art" / "sky_v2"


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


def main() -> None:
    _save_cover("关卡背景.png", "background/sky_background.png", (1280, 720))
    _save_scaled("三联棋盘格2.png", "stage/sky_triptych_stage.png", (1920, 1080))

    components = [
        ("计时附着条.png", "hud/top_attachment_strip.png", (720, 120)),
        ("标记图标.png", "hud/plane_counter_icon.png", (96, 96)),
        ("刷新按钮.png", "buttons/restart_button.png", (192, 192)),
        ("设置按钮.png", "buttons/settings_button.png", (192, 192)),
        ("天空标记.png", "markers/sky_marker.png", (320, 320)),
        ("天空标记_失败.png", "markers/sky_marker_failed.png", (320, 320)),
        ("天空标记_错误.png", "markers/sky_marker_wrong.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾.png", "characters/haze_alert.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_不服气.png", "characters/haze_defiant.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_不服气左.png", "characters/haze_defiant_left.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_嘲笑.png", "characters/haze_mock.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_嘲笑左.png", "characters/haze_mock_left.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_嘲笑右.png", "characters/haze_mock_right.png", (512, 512)),
        ("污染小怪兽/污染小怪兽_天空雾霾_失败.png", "characters/haze_defeated.png", (512, 512)),
        ("主角机器人/主角飞行器.png", "characters/skycraft.png", (640, 512)),
    ]
    for source_name, destination, maximum in components:
        _save_trimmed(source_name, destination, maximum)

    for digit in range(1, 7):
        _save_trimmed(
            f"数字显示/{digit}.png",
            f"digits/digit_{digit}.png",
            (192, 192),
        )

    ecology = [
        (15, "cloud_crown", "云冠"),
        (16, "wind_ring", "风环"),
        (17, "rainbow_bridge", "虹桥"),
        (18, "floating_isles", "浮岛"),
        (19, "cloud_ridge", "云脊"),
        (20, "storm_eye", "雷眼"),
        (21, "sky_palace", "天宫"),
    ]
    for level_number, slug, source_name in ecology:
        _save_trimmed(
            f"生态场景/{source_name}.png",
            f"ecology/level_{level_number}_{slug}.png",
            (1024, 512),
        )
        _save_trimmed(
            f"生态场景/{source_name}_污染.png",
            f"ecology/polluted/level_{level_number}_{slug}.png",
            (1024, 512),
        )
        _save_trimmed(
            f"生态场景/{source_name}_徽章.png",
            f"badges/zh/level_{level_number}_{slug}.png",
            (512, 640),
        )
        _save_trimmed(
            f"生态场景/{source_name}_英文徽章.png",
            f"badges/en/level_{level_number}_{slug}.png",
            (512, 640),
        )

    storm_eye_layers = [
        ("01_静态主体.png", "storm_eye_body.png"),
        ("02_旋转云环.png", "storm_eye_ring.png"),
        ("03_静态中心星芒.png", "storm_eye_star.png"),
        ("04_闪电闪烁.png", "storm_eye_lightning.png"),
    ]
    for source_name, output_name in storm_eye_layers:
        _save_scaled(
            f"游戏机制/{source_name}",
            f"mechanics/{output_name}",
            (512, 512),
        )

    print(f"Prepared Sky v2 runtime artwork in {OUTPUT}")


if __name__ == "__main__":
    main()
