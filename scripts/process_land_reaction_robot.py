from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
BODY_PATH = ROOT / "assets" / "art" / "land_levels" / "guardians" / "robot_failure_body.png"
SPROUT_PATH = ROOT / "assets" / "art" / "welcome" / "actors" / "robot_head_sprout.png"
OUTPUT_PATH = ROOT / "assets" / "art" / "land_levels" / "guardians" / "robot_reaction_body_with_sprout.png"
TOP_PADDING = 190
SPROUT_POSITION = (224, 15)


def read_rgba(path: Path) -> np.ndarray:
    image = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_UNCHANGED)
    if image is None:
        raise FileNotFoundError(path)
    if image.shape[2] == 3:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    return image


def alpha_composite(destination: np.ndarray, source: np.ndarray, x: int, y: int) -> None:
    height, width = source.shape[:2]
    target = destination[y:y + height, x:x + width].astype(np.float32) / 255.0
    overlay = source.astype(np.float32) / 255.0
    source_alpha = overlay[:, :, 3:4]
    target_alpha = target[:, :, 3:4]
    output_alpha = source_alpha + target_alpha * (1.0 - source_alpha)
    output_rgb = (
        overlay[:, :, :3] * source_alpha
        + target[:, :, :3] * target_alpha * (1.0 - source_alpha)
    ) / np.maximum(output_alpha, 1e-6)
    target[:, :, :3] = output_rgb
    target[:, :, 3:4] = output_alpha
    destination[y:y + height, x:x + width] = np.clip(target * 255.0, 0, 255).astype(np.uint8)


def main() -> None:
    body = read_rgba(BODY_PATH)
    sprout = read_rgba(SPROUT_PATH)
    canvas = np.zeros(
        (body.shape[0] + TOP_PADDING, body.shape[1], 4),
        dtype=np.uint8,
    )
    alpha_composite(canvas, body, 0, TOP_PADDING)
    alpha_composite(canvas, sprout, *SPROUT_POSITION)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    cv2.imencode(".png", canvas)[1].tofile(OUTPUT_PATH)
    print(OUTPUT_PATH.relative_to(ROOT))


if __name__ == "__main__":
    main()
