from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "docs"
    / "ui_history"
    / "天空关卡棋盘概念图"
    / "右键标记"
)
OUTPUT = ROOT / "assets" / "art" / "sky_levels" / "markers"
SOURCES = {
    "sky_flag_plane_normal.png": "纸飞机标志.png",
    "sky_flag_plane_failed.png": "纸飞机失败.png",
}


def read_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def largest_component(mask: np.ndarray) -> np.ndarray:
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        return mask
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return np.where(labels == largest, 255, 0).astype(np.uint8)


def extract_plane(source: Path, target: Path) -> None:
    image = read_image(source)
    blue, green, red = cv2.split(image.astype(np.int16))
    warm = (
        (red - blue > 18)
        & (green - blue > 7)
        & (red > 72)
        & (green > 55)
    ).astype(np.uint8) * 255
    warm = cv2.morphologyEx(
        warm,
        cv2.MORPH_CLOSE,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9)),
        iterations=2,
    )
    warm = largest_component(warm)

    probable = cv2.dilate(
        warm,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)),
        iterations=2,
    )
    grab_mask = np.full(image.shape[:2], cv2.GC_BGD, dtype=np.uint8)
    grab_mask[probable > 0] = cv2.GC_PR_FGD
    grab_mask[warm > 0] = cv2.GC_FGD
    cv2.grabCut(
        image,
        grab_mask,
        None,
        np.zeros((1, 65), dtype=np.float64),
        np.zeros((1, 65), dtype=np.float64),
        4,
        cv2.GC_INIT_WITH_MASK,
    )
    alpha = np.where(
        (grab_mask == cv2.GC_FGD) | (grab_mask == cv2.GC_PR_FGD),
        255,
        0,
    ).astype(np.uint8)
    alpha = largest_component(alpha)
    alpha = cv2.erode(
        alpha,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)),
        iterations=1,
    )

    points = cv2.findNonZero(alpha)
    if points is None:
        raise RuntimeError(f"No paper plane found in {source}")
    x, y, width, height = cv2.boundingRect(points)
    padding = max(12, round(max(width, height) * 0.035))
    x0 = max(0, x - padding)
    y0 = max(0, y - padding)
    x1 = min(image.shape[1], x + width + padding)
    y1 = min(image.shape[0], y + height + padding)

    keyed = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    keyed[:, :, 3] = alpha
    keyed[alpha == 0, :3] = np.asarray((70, 176, 228), dtype=np.uint8)
    crop = keyed[y0:y1, x0:x1]
    target.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", crop)[1].tofile(target)


def main() -> None:
    for output_name, source_name in SOURCES.items():
        target = OUTPUT / output_name
        extract_plane(SOURCE / source_name, target)
        print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
