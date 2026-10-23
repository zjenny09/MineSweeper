#!/usr/bin/env python3
"""Prepare badge hall prototype artwork for Godot.

Chapter stages and ecology overlays keep shared alignment canvases so all pieces
remain aligned and editor-adjustable. Source alpha is preserved; no generated
cutouts or shadows are added.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "art" / "ver2bygpt" / "勋章展示系统"
OUTPUT = ROOT / "assets" / "art" / "badge_hall"


def _resample() -> Image.Resampling:
    return Image.Resampling.LANCZOS


def _save_cover(relative: str, destination: str, size: tuple[int, int]) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGB")
        prepared = ImageOps.fit(image, size, method=_resample(), centering=(0.5, 0.5))
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_aligned(relative: str, destination: str) -> None:
    with Image.open(SOURCE / relative) as source:
        prepared = source.convert("RGBA").resize((1280, 720), _resample())
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


def _save_aligned_contained(relative: str, destination: str) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        image.thumbnail((1280, 720), _resample())
        prepared = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
        prepared.alpha_composite(
            image,
            ((1280 - image.width) // 2, (720 - image.height) // 2),
        )
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(target, optimize=True)


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


def _save_shared_canvas(
    relative: str,
    destination: str,
    expected_size: tuple[int, int],
) -> None:
    with Image.open(SOURCE / relative) as source:
        image = source.convert("RGBA")
        if image.size != expected_size:
            raise ValueError(
                f"Shared canvas mismatch for {relative}: "
                f"{image.size} != {expected_size}"
            )
        target = OUTPUT / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, optimize=True)


def main() -> None:
    _save_cover("勋章殿堂背景.png", "background.png", (1280, 720))
    _save_aligned(
        "陆地关卡/陆地生态展示台初始状态.png",
        "land/stage_initial.png",
    )
    _save_aligned("陆地关卡/陆地生态展示台.png", "land/stage_complete.png")

    ecology = [
        ("萌芽关卡.png", "01_sprout.png"),
        ("灌木关卡.png", "02_shrub.png"),
        ("湿地关卡.png", "03_wetland.png"),
        ("草原关卡.png", "04_grassland.png"),
        ("林缘关卡.png", "05_forest_edge.png"),
        ("密林关卡.png", "06_dense_forest.png"),
        ("古林关卡.png", "07_ancient_forest.png"),
    ]
    for source_name, output_name in ecology:
        _save_aligned(f"陆地关卡/{source_name}", f"land/ecology/{output_name}")

    _save_trimmed(
        "陆地关卡/陆地关卡勋章本封皮.png",
        "land/book_cover.png",
        (512, 640),
    )

    _save_aligned_contained(
        "海洋关卡/海洋生态展示台初始状态.png",
        "ocean/stage_initial.png",
    )
    _save_aligned_contained(
        "海洋关卡/海洋生态展示台.png",
        "ocean/stage_complete.png",
    )
    _save_aligned_contained(
        "海洋关卡/上方贝壳框架.png",
        "ocean/shell_frame_top.png",
    )

    ocean_ecology = [
        ("海葵关卡.png", "01_anemone.png"),
        ("海草关卡.png", "02_seagrass.png"),
        ("珊瑚关卡.png", "03_coral.png"),
        ("水母关卡.png", "04_jellyfish.png"),
        ("鱼群关卡.png", "05_fish_school.png"),
        ("海沟关卡.png", "06_trench.png"),
        ("鲸落关卡.png", "07_whale_fall.png"),
    ]
    for source_name, output_name in ocean_ecology:
        _save_aligned_contained(
            f"海洋关卡/{source_name}",
            f"ocean/ecology/{output_name}",
        )

    _save_trimmed(
        "海洋关卡/海洋关卡勋章本封皮.png",
        "ocean/book_cover.png",
        (512, 640),
    )

    _save_aligned_contained(
        "天空关卡/天空殿堂_灰色初始概念图.png",
        "sky/stage_initial.png",
    )
    _save_aligned_contained(
        "天空关卡/天空殿堂_彩色全景概念图.png",
        "sky/stage_complete.png",
    )

    sky_ecology = [
        ("云冠_生态单元.png", "01_cloud_crown.png"),
        ("风环_生态单元.png", "02_wind_ring.png"),
        ("虹桥_生态单元.png", "03_rainbow_bridge.png"),
        ("浮岛_生态单元.png", "04_floating_isles.png"),
        ("云脊_生态单元.png", "05_cloud_ridge.png"),
        ("雷眼_生态单元.png", "06_storm_eye.png"),
        ("天宫_生态单元.png", "07_sky_palace.png"),
    ]
    for source_name, output_name in sky_ecology:
        _save_aligned_contained(
            f"天空关卡/{source_name}",
            f"sky/ecology/{output_name}",
        )

    _save_trimmed(
        "天空关卡/天空关卡勋章本封皮.png",
        "sky/book_cover.png",
        (512, 640),
    )

    _save_aligned_contained(
        "宇宙关卡/宇宙生态展示台.png",
        "universe/stage.png",
    )
    _save_trimmed(
        "宇宙关卡/小行星.png",
        "universe/ecology/01_asteroid.png",
        (256, 256),
    )
    _save_trimmed(
        "宇宙关卡/大行星.png",
        "universe/ecology/02_planet.png",
        (512, 512),
    )
    _save_trimmed(
        "宇宙关卡/小星团.png",
        "universe/ecology/03_star_cluster.png",
        (512, 512),
    )
    _save_shared_canvas(
        "宇宙关卡/01_银河外层星尘.png",
        "universe/ecology/04_galaxy_outer.png",
        (1024, 512),
    )
    _save_shared_canvas(
        "宇宙关卡/02_银河旋臂.png",
        "universe/ecology/05_galaxy_spiral.png",
        (1024, 512),
    )
    _save_shared_canvas(
        "宇宙关卡/03_银河核心.png",
        "universe/ecology/06_galaxy_core.png",
        (1024, 512),
    )
    _save_trimmed(
        "宇宙关卡/终极奖杯.png",
        "universe/ecology/07_trophy.png",
        (512, 512),
    )
    # The universe chapter intentionally has no badge-book cover runtime asset.
    print(f"Prepared badge hall prototype artwork in {OUTPUT}")


if __name__ == "__main__":
    main()
