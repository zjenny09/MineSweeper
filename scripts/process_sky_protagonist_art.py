from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ui_history" / "主角设计"
OUTPUT = ROOT / "assets" / "art" / "sky_levels" / "actors"
MAX_OUTPUT_SIDE = 800


def read_image(name: str) -> np.ndarray:
    path = SOURCE / name
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def crop_to_alpha(rgba: np.ndarray, margin: int = 10) -> np.ndarray:
    ys, xs = np.nonzero(rgba[:, :, 3] > 8)
    if not len(xs):
        raise ValueError("Empty sky actor mask")
    left = max(0, int(xs.min()) - margin)
    top = max(0, int(ys.min()) - margin)
    right = min(rgba.shape[1], int(xs.max()) + margin + 1)
    bottom = min(rgba.shape[0], int(ys.max()) + margin + 1)
    return rgba[top:bottom, left:right]


def draw_shapes(size: tuple[int, int], shapes: list[dict]) -> np.ndarray:
    width, height = size
    mask = np.zeros((height, width), dtype=np.uint8)
    for shape in shapes:
        if shape["type"] == "polygon":
            cv2.fillPoly(
                mask,
                [np.asarray(shape["points"], dtype=np.int32)],
                255,
                lineType=cv2.LINE_AA,
            )
        elif shape["type"] == "ellipse":
            cv2.ellipse(
                mask,
                tuple(shape["center"]),
                tuple(shape["axes"]),
                float(shape.get("angle", 0.0)),
                0,
                360,
                255,
                -1,
                lineType=cv2.LINE_AA,
            )
    return mask


def finish_rgba(crop: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    alpha = cv2.GaussianBlur(alpha, (0, 0), 0.6)
    rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2BGRA)
    rgba[:, :, 3] = alpha
    result = crop_to_alpha(rgba)
    scale = min(1.0, MAX_OUTPUT_SIDE / float(max(result.shape[:2])))
    if scale < 1.0:
        result = cv2.resize(result, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    return result


def extract_grabcut(
    image: np.ndarray,
    crop_rect: tuple[int, int, int, int],
    rough_shapes: list[dict],
    seed_rects: list[tuple[int, int, int, int]],
    preserve_shapes: list[dict] | None = None,
) -> np.ndarray:
    left, top, right, bottom = crop_rect
    crop = image[top:bottom, left:right]
    rough = draw_shapes((crop.shape[1], crop.shape[0]), rough_shapes)
    mask = np.full(crop.shape[:2], cv2.GC_BGD, dtype=np.uint8)
    mask[rough > 0] = cv2.GC_PR_FGD
    for x1, y1, x2, y2 in seed_rects:
        cv2.rectangle(mask, (x1, y1), (x2, y2), cv2.GC_FGD, -1)
    background_model = np.zeros((1, 65), dtype=np.float64)
    foreground_model = np.zeros((1, 65), dtype=np.float64)
    cv2.grabCut(
        crop,
        mask,
        None,
        background_model,
        foreground_model,
        7,
        cv2.GC_INIT_WITH_MASK,
    )
    alpha = np.isin(mask, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8) * 255
    alpha = cv2.bitwise_and(alpha, rough)
    if preserve_shapes:
        preserved = draw_shapes((crop.shape[1], crop.shape[0]), preserve_shapes)
        alpha = np.maximum(alpha, preserved)
    return finish_rgba(crop, alpha)


def extract_red(
    image: np.ndarray,
    crop_rect: tuple[int, int, int, int],
    shapes: list[dict],
) -> np.ndarray:
    left, top, right, bottom = crop_rect
    crop = image[top:bottom, left:right]
    alpha = draw_shapes((crop.shape[1], crop.shape[0]), shapes)
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    blue, green, red = cv2.split(crop.astype(np.int16))
    red_background = (
        ((hsv[:, :, 0] <= 7) | (hsv[:, :, 0] >= 173))
        & (hsv[:, :, 1] >= 130)
        & (red > 125)
        & (red - green > 62)
        & (red - blue > 68)
    )
    alpha[red_background] = 0
    return finish_rgba(crop, alpha)


def extract_cyan(
    image: np.ndarray,
    crop_rect: tuple[int, int, int, int],
    shapes: list[dict],
) -> np.ndarray:
    left, top, right, bottom = crop_rect
    crop = image[top:bottom, left:right]
    alpha = draw_shapes((crop.shape[1], crop.shape[0]), shapes)
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    cyan_background = (
        (hsv[:, :, 0] >= 82)
        & (hsv[:, :, 0] <= 108)
        & (hsv[:, :, 1] >= 72)
        & (hsv[:, :, 2] >= 50)
    )
    alpha[cyan_background] = 0
    return finish_rgba(crop, alpha)


NORMAL_CROP = (500, 280, 1515, 1770)
NORMAL_SHAPES = [
    {"type": "polygon", "points": [(390, 15), (625, 15), (630, 315), (380, 315)]},
    {"type": "polygon", "points": [(205, 245), (755, 245), (770, 720), (195, 720)]},
    {"type": "polygon", "points": [(65, 610), (920, 610), (940, 1335), (55, 1335)]},
    {"type": "ellipse", "center": (185, 1320), "axes": (180, 190)},
    {"type": "ellipse", "center": (515, 1325), "axes": (190, 190)},
    {"type": "ellipse", "center": (825, 1250), "axes": (150, 190)},
    {"type": "polygon", "points": [(300, 690), (520, 665), (565, 1240), (505, 1375), (365, 1350)]},
]
NORMAL_SEEDS = [(260, 300, 700, 650), (150, 750, 850, 1210), (120, 1200, 800, 1380)]

VICTORY_CROP = (300, 260, 1660, 1810)
VICTORY_SHAPES = [
    {"type": "polygon", "points": [(500, 20), (870, 20), (880, 340), (490, 340)]},
    {"type": "polygon", "points": [(435, 265), (985, 265), (1010, 720), (420, 720)]},
    {"type": "polygon", "points": [(315, 650), (1110, 650), (1140, 1320), (300, 1320)]},
    {"type": "ellipse", "center": (430, 1320), "axes": (185, 205)},
    {"type": "ellipse", "center": (950, 1320), "axes": (190, 205)},
]
VICTORY_SEEDS = [(500, 310, 920, 660), (410, 760, 1030, 1220), (380, 1220, 1000, 1400)]
VICTORY_WHEEL_PRESERVE = [
    {"type": "ellipse", "center": (430, 1320), "axes": (145, 172)},
    {"type": "ellipse", "center": (950, 1320), "axes": (150, 172)},
]

FAILURE_CROP = (190, 700, 1515, 1545)
FAILURE_SHAPES = [
    {"type": "polygon", "points": [(35, 220), (575, 185), (600, 650), (190, 665), (35, 520)]},
    {"type": "polygon", "points": [(480, 75), (1100, 55), (1130, 640), (500, 650)]},
    {"type": "ellipse", "center": (1115, 210), "axes": (205, 190), "angle": 12},
    {"type": "ellipse", "center": (1125, 440), "axes": (205, 190), "angle": 12},
    {"type": "polygon", "points": [(565, 45), (1010, 35), (1040, 155), (585, 185)]},
    {"type": "polygon", "points": [(640, 455), (780, 430), (990, 730), (900, 820), (720, 650)]},
]

PLANE_CROP = (250, 700, 1835, 1490)
PLANE_SHAPES = [
    {
        "type": "polygon",
        "points": [
            (55, 90), (500, 40), (1455, 95), (1570, 140),
            (1300, 350), (930, 690), (415, 755), (55, 545),
            (205, 360), (75, 235),
        ],
    },
]


def save_png(name: str, image: np.ndarray) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", image)[1].tofile(OUTPUT / name)
    print((OUTPUT / name).relative_to(ROOT))


def main() -> None:
    normal_source = read_image("《绿色清扫者》主角设计 (4).png")
    victory_source = read_image("《绿色清扫者》主角设计.png")
    failure_source = read_image("天空机器人 (2).png")
    plane_source = read_image("天空机器人纸飞机.png")
    save_png(
        "sky_robot_upright.png",
        extract_grabcut(normal_source, NORMAL_CROP, NORMAL_SHAPES, NORMAL_SEEDS),
    )
    save_png(
        "sky_robot_victory_body.png",
        extract_grabcut(
            victory_source,
            VICTORY_CROP,
            VICTORY_SHAPES,
            VICTORY_SEEDS,
            VICTORY_WHEEL_PRESERVE,
        ),
    )
    save_png(
        "sky_robot_failure_body.png",
        extract_red(failure_source, FAILURE_CROP, FAILURE_SHAPES),
    )
    save_png(
        "sky_robot_plane.png",
        extract_cyan(plane_source, PLANE_CROP, PLANE_SHAPES),
    )


if __name__ == "__main__":
    main()
