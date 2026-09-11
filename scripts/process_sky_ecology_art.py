from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "docs" / "ui_history" / "天空关卡棋盘概念图"
OUTPUT_ROOT = ROOT / "assets" / "art" / "sky_levels" / "ecology"
CANVAS_SIZE = (768, 768)
CANVAS_MARGIN = 28


@dataclass(frozen=True)
class AssetSpec:
    level: int
    source_folder: str
    healthy_name: str
    failed_name: str
    subject_polygon: tuple[tuple[float, float], ...]
    foreground_regions: tuple[tuple[tuple[float, float], ...], ...]


SPECS = (
    AssetSpec(
        15,
        "第15关素材",
        "云冠.png",
        "云冠失败.png",
        ((0.15, 0.35), (0.25, 0.25), (0.40, 0.21), (0.60, 0.21),
         (0.75, 0.25), (0.85, 0.35), (0.90, 0.58), (0.84, 0.75),
         (0.68, 0.82), (0.32, 0.82), (0.16, 0.75), (0.10, 0.58)),
        (
            ((0.39, 0.60), (0.61, 0.60), (0.61, 0.68), (0.39, 0.68)),
            ((0.47, 0.31), (0.53, 0.31), (0.53, 0.50), (0.47, 0.50)),
        ),
    ),
    AssetSpec(
        16,
        "第16关素材",
        "风环.png",
        "风环失败.png",
        ((0.18, 0.18), (0.82, 0.18), (0.88, 0.25), (0.87, 0.37),
         (0.79, 0.41), (0.84, 0.55), (0.84, 0.68), (0.75, 0.75),
         (0.60, 0.78), (0.40, 0.78), (0.25, 0.75), (0.16, 0.68),
         (0.16, 0.54), (0.21, 0.42), (0.13, 0.36), (0.12, 0.25)),
        (
            ((0.38, 0.285), (0.62, 0.285), (0.62, 0.315), (0.38, 0.315)),
            ((0.40, 0.58), (0.60, 0.58), (0.60, 0.66), (0.40, 0.66)),
            ((0.48, 0.39), (0.52, 0.39), (0.52, 0.51), (0.48, 0.51)),
        ),
    ),
    AssetSpec(
        17,
        "第17关素材",
        "虹桥.png",
        "虹桥失败.png",
        ((0.28, 0.20), (0.72, 0.20), (0.77, 0.30), (0.78, 0.42),
         (0.84, 0.49), (0.85, 0.65), (0.78, 0.74), (0.64, 0.78),
         (0.36, 0.78), (0.22, 0.74), (0.15, 0.65), (0.16, 0.49),
         (0.22, 0.42), (0.23, 0.30)),
        (
            ((0.42, 0.265), (0.58, 0.265), (0.58, 0.32), (0.42, 0.32)),
            ((0.40, 0.59), (0.60, 0.59), (0.60, 0.67), (0.40, 0.67)),
            ((0.48, 0.40), (0.52, 0.40), (0.52, 0.53), (0.48, 0.53)),
        ),
    ),
    AssetSpec(
        18,
        "第18关素材",
        "浮岛.png",
        "浮岛失败.png",
        ((0.39, 0.23), (0.61, 0.23), (0.63, 0.34), (0.78, 0.37),
         (0.85, 0.50), (0.87, 0.66), (0.79, 0.76), (0.65, 0.80),
         (0.35, 0.80), (0.21, 0.76), (0.13, 0.66), (0.15, 0.50),
         (0.22, 0.37), (0.37, 0.34)),
        (
            ((0.42, 0.46), (0.58, 0.46), (0.58, 0.58), (0.42, 0.58)),
            ((0.38, 0.64), (0.62, 0.64), (0.62, 0.71), (0.38, 0.71)),
            ((0.48, 0.29), (0.52, 0.29), (0.52, 0.45), (0.48, 0.45)),
        ),
    ),
    AssetSpec(
        19,
        "第19关素材",
        "云脊 .png",
        "云脊失败.png",
        ((0.42, 0.14), (0.58, 0.14), (0.61, 0.31), (0.69, 0.39),
         (0.79, 0.32), (0.89, 0.43), (0.94, 0.57), (0.91, 0.68),
         (0.79, 0.73), (0.65, 0.74), (0.52, 0.79), (0.36, 0.75),
         (0.21, 0.73), (0.09, 0.66), (0.06, 0.55), (0.13, 0.43),
         (0.22, 0.33), (0.34, 0.40), (0.39, 0.31)),
        (
            ((0.37, 0.46), (0.63, 0.46), (0.66, 0.57), (0.34, 0.57)),
            ((0.31, 0.60), (0.69, 0.60), (0.69, 0.67), (0.31, 0.67)),
            ((0.48, 0.18), (0.52, 0.18), (0.52, 0.32), (0.48, 0.32)),
        ),
    ),
    AssetSpec(
        20,
        "第20关素材",
        "雷眼.png",
        "雷眼失败.png",
        ((0.58, 0.13), (0.78, 0.16), (0.87, 0.25), (0.91, 0.43),
         (0.90, 0.60), (0.84, 0.78), (0.70, 0.85), (0.52, 0.82),
         (0.34, 0.87), (0.18, 0.78), (0.09, 0.64), (0.05, 0.46),
         (0.09, 0.32), (0.19, 0.23), (0.36, 0.16)),
        (
            ((0.36, 0.32), (0.64, 0.32), (0.69, 0.39), (0.31, 0.39)),
            ((0.26, 0.54), (0.74, 0.54), (0.74, 0.63), (0.26, 0.63)),
            ((0.47, 0.43), (0.53, 0.43), (0.53, 0.54), (0.47, 0.54)),
        ),
    ),
    AssetSpec(
        21,
        "第21关素材",
        "天宫.png",
        "天宫失败.png",
        ((0.59, 0.09), (0.76, 0.10), (0.86, 0.20), (0.91, 0.38),
         (0.90, 0.59), (0.84, 0.70), (0.69, 0.75), (0.50, 0.78),
         (0.29, 0.77), (0.14, 0.70), (0.09, 0.60), (0.11, 0.47),
         (0.22, 0.39), (0.22, 0.27), (0.31, 0.17), (0.40, 0.15),
         (0.48, 0.11)),
        (
            ((0.34, 0.23), (0.62, 0.23), (0.62, 0.31), (0.34, 0.31)),
            ((0.38, 0.37), (0.59, 0.37), (0.59, 0.55), (0.38, 0.55)),
            ((0.29, 0.62), (0.70, 0.62), (0.70, 0.69), (0.29, 0.69)),
            ((0.72, 0.28), (0.79, 0.28), (0.82, 0.53), (0.75, 0.53)),
        ),
    ),
)


def scaled_polygon(
    points: tuple[tuple[float, float], ...], width: int, height: int
) -> np.ndarray:
    return np.asarray(
        [(round(x * width), round(y * height)) for x, y in points],
        dtype=np.int32,
    )


def load_bgr(path: Path) -> np.ndarray:
    encoded = np.fromfile(path, dtype=np.uint8)
    image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def extract_rgba(path: Path, spec: AssetSpec) -> Image.Image:
    original = load_bgr(path)
    original_height, original_width = original.shape[:2]
    process_scale = min(1.0, 1024.0 / max(original_width, original_height))
    working = cv2.resize(
        original,
        (round(original_width * process_scale), round(original_height * process_scale)),
        interpolation=cv2.INTER_AREA,
    )
    height, width = working.shape[:2]

    mask = np.full((height, width), cv2.GC_BGD, dtype=np.uint8)
    subject = scaled_polygon(spec.subject_polygon, width, height)
    cv2.fillPoly(mask, [subject], cv2.GC_PR_FGD)

    definite_foreground = np.zeros_like(mask, dtype=np.uint8)
    for region in spec.foreground_regions:
        region_polygon = scaled_polygon(region, width, height)
        cv2.fillPoly(mask, [region_polygon], cv2.GC_FGD)
        cv2.fillPoly(definite_foreground, [region_polygon], 1)

    border = max(3, round(min(width, height) * 0.012))
    mask[:border, :] = cv2.GC_BGD
    mask[-border:, :] = cv2.GC_BGD
    mask[:, :border] = cv2.GC_BGD
    mask[:, -border:] = cv2.GC_BGD

    background_model = np.zeros((1, 65), dtype=np.float64)
    foreground_model = np.zeros((1, 65), dtype=np.float64)
    cv2.grabCut(
        working,
        mask,
        None,
        background_model,
        foreground_model,
        8,
        cv2.GC_INIT_WITH_MASK,
    )

    binary = np.isin(mask, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8)
    binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))

    component_count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    kept = np.zeros_like(binary)
    minimum_area = max(48, round(width * height * 0.0003))
    for label in range(1, component_count):
        component = labels == label
        if stats[label, cv2.CC_STAT_AREA] < minimum_area:
            continue
        if np.any(definite_foreground[component]):
            kept[component] = 1

    inside = cv2.distanceTransform(kept, cv2.DIST_L2, 5)
    outside = cv2.distanceTransform(1 - kept, cv2.DIST_L2, 5)
    signed = inside - outside
    alpha = np.clip((signed + 0.25) / 2.4 + 0.5, 0.0, 1.0)
    alpha = cv2.GaussianBlur(alpha, (0, 0), 0.65)
    alpha = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    alpha = cv2.resize(
        alpha,
        (original_width, original_height),
        interpolation=cv2.INTER_LINEAR,
    )

    rgb = cv2.cvtColor(original, cv2.COLOR_BGR2RGB)
    return Image.fromarray(np.dstack((rgb, alpha)), "RGBA")


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.asarray(image.getchannel("A"))
    ys, xs = np.nonzero(alpha > 8)
    if not len(xs):
        raise ValueError("Empty alpha mask")
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def align_pair(images: tuple[Image.Image, Image.Image]) -> tuple[Image.Image, Image.Image]:
    boxes = [alpha_bbox(image) for image in images]
    crops = [image.crop(box) for image, box in zip(images, boxes)]
    maximum_width = max(crop.width for crop in crops)
    maximum_height = max(crop.height for crop in crops)
    scale = min(
        (CANVAS_SIZE[0] - CANVAS_MARGIN * 2) / maximum_width,
        (CANVAS_SIZE[1] - CANVAS_MARGIN * 2) / maximum_height,
    )

    aligned: list[Image.Image] = []
    for crop in crops:
        resized = crop.resize(
            (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        position = (
            (CANVAS_SIZE[0] - resized.width) // 2,
            CANVAS_SIZE[1] - CANVAS_MARGIN - resized.height,
        )
        canvas.alpha_composite(resized, position)
        aligned.append(canvas)
    return aligned[0], aligned[1]


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    for spec in SPECS:
        source_folder = SOURCE_ROOT / spec.source_folder
        healthy = extract_rgba(source_folder / spec.healthy_name, spec)
        failed = extract_rgba(source_folder / spec.failed_name, spec)
        healthy, failed = align_pair((healthy, failed))
        healthy_path = OUTPUT_ROOT / f"level_{spec.level:02d}_ecology_healthy.png"
        failed_path = OUTPUT_ROOT / f"level_{spec.level:02d}_ecology_failed.png"
        healthy.save(healthy_path, optimize=True)
        failed.save(failed_path, optimize=True)
        print(healthy_path.relative_to(ROOT))
        print(failed_path.relative_to(ROOT))


if __name__ == "__main__":
    main()
