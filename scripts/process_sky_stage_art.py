from pathlib import Path
import shutil

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SKY_SOURCE = (
    ROOT
    / "docs"
    / "ui_history"
    / "天空关卡棋盘概念图"
    / "棋盘与棋盘格"
)
OCEAN_SOURCE = (
    ROOT
    / "docs"
    / "ui_history"
    / "海洋关卡棋盘概念图"
    / "棋盘和棋盘格"
)
SKY_BACKGROUND = ROOT / "assets" / "art" / "sky_levels" / "background"
SKY_STAGE = ROOT / "assets" / "art" / "sky_levels" / "stage"
SKY_LEVEL_SELECT = ROOT / "assets" / "art" / "level_select"
SKY_LEVEL_MAP_SOURCE = (
    ROOT
    / "docs"
    / "ui_history"
    / "天空关卡棋盘概念图"
    / "关卡地图"
    / "绘制天空关卡地图.png"
)
OCEAN_BACKGROUND = ROOT / "assets" / "art" / "ocean_levels" / "background"


def read_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def smoothstep(low: float, high: float, values: np.ndarray) -> np.ndarray:
    scaled = np.clip((values - low) / (high - low), 0.0, 1.0)
    return scaled * scaled * (3.0 - 2.0 * scaled)


def central_frame_ring(width: int, height: int) -> np.ndarray:
    scale_x = width / 2848.0
    scale_y = height / 1600.0

    def points(values: list[tuple[int, int]]) -> np.ndarray:
        return np.asarray(
            [(round(x * scale_x), round(y * scale_y)) for x, y in values],
            dtype=np.int32,
        )

    outer = points([
        (900, 150),
        (1948, 150),
        (2074, 265),
        (2074, 1260),
        (1960, 1362),
        (892, 1362),
        (790, 1260),
        (790, 266),
    ])
    opening = points([
        (930, 291),
        (1929, 291),
        (1980, 335),
        (1980, 1204),
        (1930, 1249),
        (927, 1249),
        (884, 1204),
        (884, 337),
    ])
    ring = np.zeros((height, width), dtype=np.uint8)
    cv2.fillPoly(ring, [outer], 255)
    cv2.fillPoly(ring, [opening], 0)
    return ring.astype(np.float32) / 255.0


def central_opening_border(width: int, height: int) -> np.ndarray:
    scale_x = width / 2848.0
    scale_y = height / 1600.0
    opening = np.asarray(
        [
            (round(x * scale_x), round(y * scale_y))
            for x, y in [
                (930, 291),
                (1929, 291),
                (1980, 335),
                (1980, 1204),
                (1930, 1249),
                (927, 1249),
                (884, 1204),
                (884, 337),
            ]
        ],
        dtype=np.int32,
    )
    opening_mask = np.zeros((height, width), dtype=np.uint8)
    cv2.fillPoly(opening_mask, [opening], 255)
    border_size = max(3, round(45.0 * min(scale_x, scale_y)))
    if border_size % 2 == 0:
        border_size += 1
    expanded = cv2.dilate(
        opening_mask,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (border_size, border_size)),
    )
    return cv2.subtract(expanded, opening_mask)


def remove_red_stage_background(source: Path, target: Path) -> None:
    image = read_image(source)
    height, width = image.shape[:2]
    scale_x = width / 2848.0
    scale_y = height / 1600.0
    cylinder_mask = np.zeros((height, width), dtype=np.uint8)
    for center in [(1437, 105), (1438, 1397)]:
        cv2.ellipse(
            cylinder_mask,
            (round(center[0] * scale_x), round(center[1] * scale_y)),
            (round(64 * scale_x), round(70 * scale_y)),
            0,
            0,
            360,
            255,
            -1,
            lineType=cv2.LINE_AA,
        )
    image = cv2.inpaint(image, cylinder_mask, 13.0, cv2.INPAINT_TELEA)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV).astype(np.float32)
    bgr = image.astype(np.float32)
    blue, green, red = cv2.split(bgr)

    hue_distance = np.minimum(hsv[:, :, 0], 180.0 - hsv[:, :, 0])
    red_background = (
        (hue_distance <= 24.0)
        & (hsv[:, :, 1] >= 10.0)
        & ((red - green) >= 2.0)
        & ((red - blue) >= 4.0)
    )
    red_mask = red_background.astype(np.uint8) * 255
    red_mask = cv2.dilate(
        red_mask,
        cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)),
        iterations=1,
    )
    alpha = 255 - red_mask
    center_left = round(1330 * scale_x)
    center_right = round(1550 * scale_x)
    alpha[:round(150 * scale_y), center_left:center_right] = 0
    alpha[round(1363 * scale_y):, center_left:center_right] = 0

    keyed = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    keyed[alpha == 0, :3] = np.asarray((238, 232, 210), dtype=np.uint8)
    keyed[:, :, 3] = alpha
    target.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", keyed)[1].tofile(target)


def build_sky_level_map(source: Path, target: Path) -> None:
    image = read_image(source)
    height, width = image.shape[:2]
    crop = image[
        round(height * 0.12):round(height * 0.855),
        round(width * 0.052):round(width * 0.95),
    ]
    resized = cv2.resize(crop, (1200, 544), interpolation=cv2.INTER_AREA)
    target.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", resized)[1].tofile(target)


def remove_corner_brand(source: Path, target: Path) -> None:
    image = read_image(source)
    height, width = image.shape[:2]
    mask = np.zeros((height, width), dtype=np.uint8)
    cv2.rectangle(
        mask,
        (round(width * 0.947), round(height * 0.925)),
        (round(width * 0.997), round(height * 0.997)),
        255,
        -1,
    )
    cleaned = cv2.inpaint(image, mask, 9.0, cv2.INPAINT_TELEA)
    target.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", cleaned)[1].tofile(target)


def main() -> None:
    SKY_BACKGROUND.mkdir(parents=True, exist_ok=True)
    OCEAN_BACKGROUND.mkdir(parents=True, exist_ok=True)
    remove_corner_brand(
        SKY_SOURCE / "天空棋盘桌面2.png",
        SKY_BACKGROUND / "sky_desktop_clean.png",
    )
    remove_corner_brand(
        OCEAN_SOURCE / "海洋棋盘桌面.png",
        OCEAN_BACKGROUND / "ocean_desktop_clean.png",
    )
    build_sky_level_map(
        SKY_LEVEL_MAP_SOURCE,
        SKY_LEVEL_SELECT / "sky_level_map_clean.png",
    )
    remove_red_stage_background(
        SKY_SOURCE / "棋盘.png",
        SKY_STAGE / "sky_board_frame.png",
    )
    print("Updated ocean desktop, sky desktop, and transparent sky board frame.")


if __name__ == "__main__":
    main()
