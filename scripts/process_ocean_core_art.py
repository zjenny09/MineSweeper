from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ui_history" / "污染核心史莱姆"
OUTPUT = ROOT / "assets" / "art" / "ocean_levels" / "markers"
SOURCES = {
    "ocean_pollution_core_monster.png": "海洋污染核心.png",
    "ocean_marker_monster_wrong.png": "海洋怪兽错误标记.png",
}


def read_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def simplify_for_small_display(image: np.ndarray, max_size: int = 192) -> np.ndarray:
    height, width = image.shape[:2]
    scale = min(1.0, float(max_size) / float(max(height, width)))
    target_size = (
        max(1, round(width * scale)),
        max(1, round(height * scale)),
    )
    reduced = cv2.resize(image, target_size, interpolation=cv2.INTER_AREA)
    rgb = cv2.bilateralFilter(reduced[:, :, :3], 7, 28.0, 28.0)
    alpha = reduced[:, :, 3]

    opaque = alpha > 24
    pixels = rgb[opaque].reshape(-1, 3).astype(np.float32)
    if pixels.size > 0:
        cv2.setRNGSeed(7)
        _compactness, labels, centers = cv2.kmeans(
            pixels,
            14,
            None,
            (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 24, 0.8),
            3,
            cv2.KMEANS_PP_CENTERS,
        )
        rgb[opaque] = centers[labels.flatten()].reshape(-1, 3).astype(np.uint8)
    return np.dstack((rgb, alpha))


def extract_icon(source: Path, target: Path) -> None:
    image = read_image(source)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    blue, green, red = cv2.split(image.astype(np.int16))
    green_background = (
        (hsv[:, :, 0] >= 31)
        & (hsv[:, :, 0] <= 98)
        & (hsv[:, :, 1] >= 22)
        & (green - blue >= 5)
        & (green - red >= 4)
    ).astype(np.uint8) * 255
    green_background = cv2.dilate(
        green_background,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)),
    )
    foreground = 255 - green_background
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(foreground, 8)
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    x, y, width, height = stats[largest, :4]
    padding = max(12, round(max(width, height) * 0.025))
    x0 = max(0, x - padding)
    y0 = max(0, y - padding)
    x1 = min(image.shape[1], x + width + padding)
    y1 = min(image.shape[0], y + height + padding)

    region_mask = np.zeros_like(foreground)
    region_mask[y0:y1, x0:x1] = 255
    alpha = cv2.bitwise_and(foreground, region_mask)
    keyed = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    keyed[alpha == 0, :3] = np.asarray((156, 126, 164), dtype=np.uint8)
    keyed[:, :, 3] = alpha
    target.parent.mkdir(parents=True, exist_ok=True)
    cropped = keyed[y0:y1, x0:x1]
    simplified = simplify_for_small_display(cropped)
    cv2.imencode(".png", simplified)[1].tofile(target)


def main() -> None:
    for output_name, source_name in SOURCES.items():
        target = OUTPUT / output_name
        extract_icon(SOURCE / source_name, target)
        print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
