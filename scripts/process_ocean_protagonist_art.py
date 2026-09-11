from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ui_history" / "主角设计" / "海洋中的主角.png"
OUTPUT = ROOT / "assets" / "art" / "ocean_levels" / "actors"


def read_image(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def feather_mask(mask: np.ndarray, sigma: float = 0.8) -> np.ndarray:
    blurred = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), sigma)
    return np.clip(blurred, 0, 255).astype(np.uint8)


def crop_to_alpha(rgba: np.ndarray, margin: int = 8) -> np.ndarray:
    alpha = rgba[:, :, 3]
    ys, xs = np.nonzero(alpha > 6)
    if not len(xs):
        raise ValueError("Empty protagonist mask")
    left = max(0, int(xs.min()) - margin)
    top = max(0, int(ys.min()) - margin)
    right = min(rgba.shape[1], int(xs.max()) + margin + 1)
    bottom = min(rgba.shape[0], int(ys.max()) + margin + 1)
    return rgba[top:bottom, left:right]


def build_robot(image: np.ndarray) -> np.ndarray:
    left, top, right, bottom = 425, 320, 880, 970
    crop = image[top:bottom, left:right]
    height, width = crop.shape[:2]
    mask = np.full((height, width), cv2.GC_BGD, dtype=np.uint8)

    rough = np.zeros((height, width), dtype=np.uint8)
    cv2.ellipse(rough, (215, 195), (195, 165), 0, 0, 360, 255, -1)
    cv2.fillPoly(
        rough,
        [np.asarray([(40, 280), (365, 275), (405, 545), (345, 620), (55, 620)], dtype=np.int32)],
        255,
    )
    cv2.circle(rough, (90, 540), 92, 255, -1)
    cv2.circle(rough, (218, 550), 88, 255, -1)
    cv2.circle(rough, (350, 530), 70, 255, -1)
    mask[rough > 0] = cv2.GC_PR_FGD

    seed = np.zeros((height, width), dtype=np.uint8)
    cv2.rectangle(seed, (105, 310), (325, 500), 255, -1)
    cv2.rectangle(seed, (130, 145), (305, 285), 255, -1)
    cv2.circle(seed, (92, 545), 58, 255, -1)
    cv2.circle(seed, (220, 555), 58, 255, -1)
    cv2.circle(seed, (350, 540), 42, 255, -1)
    mask[seed > 0] = cv2.GC_FGD

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

    dome = np.zeros_like(alpha)
    cv2.ellipse(dome, (215, 195), (190, 158), 0, 0, 360, 255, -1)
    alpha = np.maximum(alpha, dome)
    alpha = feather_mask(alpha)
    rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2BGRA)
    rgba[:, :, 3] = alpha
    return crop_to_alpha(rgba)


def remove_robot_arm(rgba: np.ndarray) -> np.ndarray:
    result = rgba.copy()
    height, width = result.shape[:2]
    mask = np.zeros((height, width), dtype=np.uint8)
    points = np.asarray(
        [
            (0.22, 0.46), (0.43, 0.45), (0.45, 0.55),
            (0.39, 0.58), (0.45, 0.69), (0.52, 0.72),
            (0.50, 0.80), (0.40, 0.82), (0.31, 0.76),
            (0.31, 0.70), (0.36, 0.67), (0.28, 0.57),
        ],
        dtype=np.float32,
    )
    points[:, 0] *= width
    points[:, 1] *= height
    cv2.fillPoly(mask, [np.rint(points).astype(np.int32)], 255)
    mask = cv2.dilate(mask, np.ones((5, 5), np.uint8), iterations=1)
    result[:, :, :3] = cv2.inpaint(
        result[:, :, :3],
        mask,
        7.0,
        cv2.INPAINT_TELEA,
    )
    return result


def build_monster(image: np.ndarray) -> np.ndarray:
    left, top, right, bottom = 990, 325, 1550, 885
    crop = image[top:bottom, left:right]
    alpha = np.zeros(crop.shape[:2], dtype=np.uint8)
    cv2.ellipse(alpha, (283, 278), (258, 255), 0, 0, 360, 255, -1)
    alpha = feather_mask(alpha, 0.9)
    rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2BGRA)
    rgba[:, :, 3] = alpha
    return crop_to_alpha(rgba)


def build_crying_monster(rgba: np.ndarray) -> np.ndarray:
    result = rgba.copy()
    height, width = result.shape[:2]
    mouth_mask = np.zeros((height, width), dtype=np.uint8)
    mouth_center = (234, 320)
    mouth_axes = (27, 16)
    cv2.ellipse(mouth_mask, mouth_center, mouth_axes, 0, 0, 360, 255, -1)
    result[:, :, :3] = cv2.inpaint(
        result[:, :, :3],
        mouth_mask,
        7.0,
        cv2.INPAINT_TELEA,
    )
    frown = np.asarray(
        [
            (210, 329),
            (222, 315),
            (234, 310),
            (246, 315),
            (258, 329),
        ],
        dtype=np.int32,
    )
    cv2.polylines(
        result,
        [frown],
        False,
        (18, 31, 48, 255),
        5,
        cv2.LINE_AA,
    )
    return result


def save_png(path: Path, image: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", image)[1].tofile(path)


def main() -> None:
    image = read_image(SOURCE)
    robot = build_robot(image)
    save_png(OUTPUT / "ocean_robot_helmet.png", robot)
    save_png(OUTPUT / "ocean_robot_reaction_body.png", remove_robot_arm(robot))
    monster = build_monster(image)
    save_png(OUTPUT / "ocean_bubble_monster.png", monster)
    save_png(OUTPUT / "ocean_bubble_monster_crying.png", build_crying_monster(monster))
    print("Updated ocean robot, reaction body, and monster expressions.")


if __name__ == "__main__":
    main()
