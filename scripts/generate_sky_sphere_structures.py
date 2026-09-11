from __future__ import annotations

import json
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "data" / "sky_sphere_structures.json"

PHI = (1.0 + np.sqrt(5.0)) * 0.5
ICO_VERTICES = np.asarray(
    [
        (-1, PHI, 0), (1, PHI, 0), (-1, -PHI, 0), (1, -PHI, 0),
        (0, -1, PHI), (0, 1, PHI), (0, -1, -PHI), (0, 1, -PHI),
        (PHI, 0, -1), (PHI, 0, 1), (-PHI, 0, -1), (-PHI, 0, 1),
    ],
    dtype=np.float64,
)
ICO_VERTICES /= np.linalg.norm(ICO_VERTICES, axis=1, keepdims=True)
ICO_FACES = [
    [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
    [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
    [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
    [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
]
STRUCTURES = [(42, 2), (92, 3), (162, 4), (252, 5), (362, 6), (492, 7)]


def normalize(point: np.ndarray) -> np.ndarray:
    return point / np.linalg.norm(point)


def orient_face(vertices: list[np.ndarray], face: list[int]) -> list[int]:
    points = [vertices[index] for index in face]
    normal = np.cross(points[1] - points[0], points[2] - points[0])
    if np.dot(normal, np.mean(points, axis=0)) < 0.0:
        return list(reversed(face))
    return face


def add_vertex(
    point: np.ndarray,
    vertices: list[np.ndarray],
    lookup: dict[tuple[float, float, float], int],
) -> int:
    key = tuple(np.round(point, 9))
    if key not in lookup:
        lookup[key] = len(vertices)
        vertices.append(point)
    return lookup[key]


def geodesic_icosahedron(frequency: int) -> tuple[list[np.ndarray], list[list[int]]]:
    vertices: list[np.ndarray] = []
    faces: list[list[int]] = []
    lookup: dict[tuple[float, float, float], int] = {}
    for base_face in ICO_FACES:
        a, b, c = [ICO_VERTICES[index] for index in base_face]
        local: dict[tuple[int, int], int] = {}
        for i in range(frequency + 1):
            for j in range(frequency + 1 - i):
                point = normalize(
                    ((frequency - i - j) * a + i * b + j * c) / frequency
                )
                local[(i, j)] = add_vertex(point, vertices, lookup)
        for i in range(frequency):
            for j in range(frequency - i):
                faces.append(orient_face(vertices, [
                    local[(i, j)],
                    local[(i + 1, j)],
                    local[(i, j + 1)],
                ]))
                if i + j <= frequency - 2:
                    faces.append(orient_face(vertices, [
                        local[(i + 1, j)],
                        local[(i + 1, j + 1)],
                        local[(i, j + 1)],
                    ]))
    return vertices, faces


def dual_polyhedron(
    primal_vertices: list[np.ndarray],
    primal_faces: list[list[int]],
) -> tuple[list[np.ndarray], list[list[int]]]:
    dual_vertices: list[np.ndarray] = []
    incident_faces: list[list[int]] = [[] for _ in primal_vertices]
    for face_index, face in enumerate(primal_faces):
        a, b, c = [primal_vertices[index] for index in face]
        normal = normalize(np.cross(b - a, c - a))
        if np.dot(normal, a) < 0.0:
            normal = -normal
        dual_vertices.append(normal / np.dot(normal, a))
        for vertex_index in face:
            incident_faces[vertex_index].append(face_index)
    maximum_radius = max(np.linalg.norm(point) for point in dual_vertices)
    dual_vertices = [point / maximum_radius for point in dual_vertices]

    dual_faces: list[list[int]] = []
    for vertex_index, incident in enumerate(incident_faces):
        normal = primal_vertices[vertex_index]
        axis_x = np.cross(normal, np.asarray((0.0, 1.0, 0.0)))
        if np.linalg.norm(axis_x) < 0.1:
            axis_x = np.cross(normal, np.asarray((1.0, 0.0, 0.0)))
        axis_x = normalize(axis_x)
        axis_y = normalize(np.cross(normal, axis_x))
        ordered = sorted(
            incident,
            key=lambda face_index: np.arctan2(
                np.dot(dual_vertices[face_index], axis_y),
                np.dot(dual_vertices[face_index], axis_x),
            ),
        )
        dual_faces.append(orient_face(dual_vertices, ordered))
    return dual_vertices, dual_faces


def build_structure(frequency: int) -> dict:
    primal_vertices, primal_faces = geodesic_icosahedron(frequency)
    vertices, faces = dual_polyhedron(primal_vertices, primal_faces)
    side_counts = {len(face) for face in faces}
    if not side_counts.issubset({5, 6}):
        raise ValueError(f"Unexpected face sizes: {sorted(side_counts)}")
    return {
        "vertices": np.round(np.asarray(vertices), 9).tolist(),
        "faces": faces,
    }


def main() -> None:
    structures = {
        str(face_count): build_structure(frequency)
        for face_count, frequency in STRUCTURES
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(structures, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(OUTPUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
