from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ui_history" / "污染核心史莱姆"
OUTPUT = ROOT / "assets" / "art" / "sky_levels" / "markers"
SOURCES = {
    "sky_pollution_core_cloud.png": "天空污染核心.png",
    "sky_marker_wrong_cloud.png": "天空标记错误标志.png",
}


def read_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def border_connected(mask: np.ndarray) -> np.ndarray:
    _count, labels = cv2.connectedComponents(mask, 8)
    border_labels = np.unique(
        np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1]))
    )
    connected = np.isin(labels, border_labels[border_labels != 0])
    return connected.astype(np.uint8) * 255


def largest_component(mask: np.ndarray) -> np.ndarray:
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        return mask
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return np.where(labels == largest, 255, 0).astype(np.uint8)


def extract_icon(source: Path, target: Path) -> None:
    image = read_image(source)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    blue, green, red = cv2.split(image.astype(np.int16))
    yellow_background = (
        (hsv[:, :, 0] >= 7)
        & (hsv[:, :, 0] <= 48)
        & (hsv[:, :, 1] >= 12)
        & (red - blue >= 14)
        & (green - blue >= 4)
    ).astype(np.uint8) * 255
    yellow_background = cv2.morphologyEx(
        yellow_background,
        cv2.MORPH_CLOSE,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)),
    )
    background = border_connected(yellow_background)
    background = cv2.dilate(
        background,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)),
    )
    alpha = largest_component(255 - background)
    if target.name == "sky_marker_wrong_cloud.png":
        plane_region = np.zeros_like(alpha)
        cv2.rectangle(plane_region, (500, 990), (1680, 1580), 255, -1)
        alpha[(plane_region > 0) & (yellow_background > 0)] = 255

    x, y, width, height = cv2.boundingRect(alpha)
    padding = max(8, round(max(width, height) * 0.02))
    x0 = max(0, x - padding)
    y0 = max(0, y - padding)
    x1 = min(image.shape[1], x + width + padding)
    y1 = min(image.shape[0], y + height + padding)

    keyed = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    keyed[alpha == 0, :3] = np.asarray((154, 126, 154), dtype=np.uint8)
    keyed[:, :, 3] = alpha
    target.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", keyed[y0:y1, x0:x1])[1].tofile(target)


def main() -> None:
    for output_name, source_name in SOURCES.items():
        target = OUTPUT / output_name
        extract_icon(SOURCE / source_name, target)
        print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
