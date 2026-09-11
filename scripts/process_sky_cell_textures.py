from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "ui_history" / "天空关卡棋盘概念图" / "棋盘与棋盘格"
OUTPUT = ROOT / "assets" / "art" / "sky_levels" / "board"
TEXTURE_SIZE = 512
EDGE_INSET = 0.012

SOURCE_SPECS = {
    "pentagon_hidden_surface.png": {
        "source": "五边形棋盘格 (1).png",
        "vertices": [(992, 435), (1580, 820), (1438, 1518), (548, 1524), (405, 820)],
    },
    "pentagon_revealed_surface.png": {
        "source": "五边形棋盘格 (2).png",
        "vertices": [(1000, 252), (1752, 770), (1445, 1695), (548, 1695), (243, 770)],
    },
    "pentagon_polluted_surface.png": {
        "source": "五边形棋盘格 (3).png",
        "vertices": [(1000, 414), (1603, 780), (1435, 1538), (560, 1538), (373, 780)],
    },
    "hexagon_hidden_surface.png": {
        "source": "六边形棋盘格 (2).png",
        "vertices": [(1670, 960), (1320, 1580), (690, 1580), (315, 960), (690, 390), (1320, 390)],
    },
    "hexagon_revealed_surface.png": {
        "source": "六边形棋盘格 (1).png",
        "vertices": [(1670, 960), (1320, 1580), (690, 1580), (315, 960), (690, 390), (1320, 390)],
    },
    "hexagon_polluted_surface.png": {
        "source": "六边形棋盘格 (3).png",
        "vertices": [(1550, 700), (1550, 1300), (1000, 1640), (450, 1310), (450, 700), (1000, 377)],
    },
}


def read_image(path: Path) -> np.ndarray:
    encoded = np.fromfile(path, dtype=np.uint8)
    image = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(path)
    return image


def target_polygon(vertex_count: int) -> np.ndarray:
    angles = np.arange(vertex_count, dtype=np.float32) * (2.0 * np.pi / vertex_count)
    points = np.column_stack((np.cos(angles), np.sin(angles)))
    minimum = points.min(axis=0)
    maximum = points.max(axis=0)
    return 1.0 + (points - minimum) / (maximum - minimum) * (TEXTURE_SIZE - 3.0)


def inset_vertices(vertices: np.ndarray) -> np.ndarray:
    center = vertices.mean(axis=0)
    return center + (vertices - center) * (1.0 - EDGE_INSET)


def warp_surface(source: Path, vertex_values: list[tuple[int, int]]) -> np.ndarray:
    image = read_image(source)
    source_vertices = inset_vertices(np.asarray(vertex_values, dtype=np.float32))
    destination_vertices = target_polygon(len(vertex_values)).astype(np.float32)
    source_center = source_vertices.mean(axis=0)
    destination_center = destination_vertices.mean(axis=0)
    result = np.zeros((TEXTURE_SIZE, TEXTURE_SIZE, 3), dtype=np.uint8)

    for index in range(len(vertex_values)):
        next_index = (index + 1) % len(vertex_values)
        source_triangle = np.asarray(
            [source_center, source_vertices[index], source_vertices[next_index]],
            dtype=np.float32,
        )
        destination_triangle = np.asarray(
            [destination_center, destination_vertices[index], destination_vertices[next_index]],
            dtype=np.float32,
        )
        transform = cv2.getAffineTransform(source_triangle, destination_triangle)
        warped = cv2.warpAffine(
            image,
            transform,
            (TEXTURE_SIZE, TEXTURE_SIZE),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_REFLECT_101,
        )
        triangle_mask = np.zeros((TEXTURE_SIZE, TEXTURE_SIZE), dtype=np.uint8)
        cv2.fillConvexPoly(
            triangle_mask,
            np.rint(destination_triangle).astype(np.int32),
            255,
            lineType=cv2.LINE_AA,
        )
        result[triangle_mask > 0] = warped[triangle_mask > 0]

    blue, green, red = cv2.split(result.astype(np.int16))
    red_residue = (red - np.maximum(green, blue) > 34).astype(np.uint8) * 255
    polygon_mask = np.zeros((TEXTURE_SIZE, TEXTURE_SIZE), dtype=np.uint8)
    cv2.fillConvexPoly(
        polygon_mask,
        np.rint(destination_vertices).astype(np.int32),
        255,
        lineType=cv2.LINE_AA,
    )
    red_residue = cv2.bitwise_and(red_residue, polygon_mask)
    if np.any(red_residue):
        result = cv2.inpaint(result, red_residue, 4.0, cv2.INPAINT_TELEA)

    alpha = cv2.GaussianBlur(polygon_mask, (0, 0), 0.45)
    alpha = np.minimum(alpha, 250).astype(np.uint8)
    return np.dstack((result, alpha))


def normal_map(surface: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(surface[:, :, :3], cv2.COLOR_BGR2GRAY).astype(np.float32)
    broad_light = cv2.GaussianBlur(gray, (0, 0), 32.0)
    detail = gray / np.maximum(broad_light, 1.0)
    softened = cv2.GaussianBlur(detail, (0, 0), 0.8)
    dx = cv2.Sobel(softened, cv2.CV_32F, 1, 0, ksize=3) * 0.22
    dy = cv2.Sobel(softened, cv2.CV_32F, 0, 1, ksize=3) * 0.22
    normal = np.dstack((-dx, -dy, np.ones_like(detail)))
    normal /= np.maximum(np.linalg.norm(normal, axis=2, keepdims=True), 1e-6)
    encoded = ((normal * 0.5 + 0.5) * 255.0).astype(np.uint8)
    return cv2.cvtColor(encoded, cv2.COLOR_RGB2BGR)


def save_png(path: Path, image: np.ndarray) -> None:
    cv2.imencode(".png", image)[1].tofile(path)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    shape_surfaces: dict[str, np.ndarray] = {}
    for output_name, spec in SOURCE_SPECS.items():
        surface = warp_surface(
            SOURCE / str(spec["source"]),
            spec["vertices"],
        )
        save_png(OUTPUT / output_name, surface)
        shape = output_name.split("_", 1)[0]
        if shape not in shape_surfaces:
            shape_surfaces[shape] = surface
        print((OUTPUT / output_name).relative_to(ROOT))
    for shape, surface in shape_surfaces.items():
        target = OUTPUT / f"{shape}_surface_normal.png"
        save_png(target, normal_map(surface))
        print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
