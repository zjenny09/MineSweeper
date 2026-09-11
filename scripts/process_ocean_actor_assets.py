from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "docs" / "ui_history" / "海洋关卡棋盘概念图"
OUTPUT_ROOT = ROOT / "assets" / "art" / "ocean_levels" / "actors"
REVIEW_ROOT = ROOT / "docs" / "asset_reviews" / "ocean_actors"
CANVAS_SIZE = (1024, 1024)
BASELINE_Y = 958
SIDE_MARGIN = 54
TOP_MARGIN = 48


@dataclass(frozen=True)
class AssetSpec:
    level: int
    state: str
    source: Path
    output_name: str
    boundary: tuple[tuple[int, int], ...]
    foreground: tuple[tuple[tuple[int, int], ...], ...]
    background: tuple[tuple[tuple[int, int], ...], ...] = ()


SPECS = (
    AssetSpec(
        6,
        "healthy",
        SOURCE_ROOT / "第六关素材" / "海葵1.png",
        "level_06_anemone_healthy.png",
        ((760, 455), (1230, 475), (1510, 610), (1695, 875), (1700, 1235),
         (1560, 1460), (1510, 1685), (550, 1720), (455, 1650), (430, 1480),
         (285, 1270), (280, 920), (430, 680)),
        (
            ((650, 1510), (1400, 1510), (1380, 1640), (650, 1640)),
        ),
    ),
    AssetSpec(
        6,
        "wilted",
        SOURCE_ROOT / "第六关素材" / "海葵枯萎.png",
        "level_06_anemone_wilted.png",
        ((760, 455), (1240, 470), (1510, 590), (1700, 850), (1705, 1250),
         (1570, 1470), (1515, 1685), (545, 1720), (455, 1650), (425, 1450),
         (300, 1250), (285, 880), (435, 650)),
        (
            ((650, 1510), (1400, 1510), (1380, 1640), (650, 1640)),
        ),
    ),
    AssetSpec(
        7,
        "healthy",
        SOURCE_ROOT / "第七关素材" / "海草小芽 (2).png",
        "level_07_seagrass_healthy.png",
        ((830, 420), (1210, 430), (1450, 610), (1510, 930), (1480, 1270),
         (1430, 1490), (1260, 1605), (705, 1625), (455, 1530), (395, 1300),
         (430, 1000), (520, 760)),
        (
            ((600, 1350), (1390, 1350), (1330, 1510), (690, 1540)),
        ),
    ),
    AssetSpec(
        7,
        "wilted",
        SOURCE_ROOT / "第七关素材" / "海草小芽 枯萎.png",
        "level_07_seagrass_wilted.png",
        ((820, 420), (1215, 430), (1480, 620), (1540, 940), (1490, 1290),
         (1430, 1495), (1260, 1605), (700, 1625), (445, 1530), (390, 1280),
         (405, 980), (520, 745)),
        (
            ((600, 1350), (1390, 1350), (1330, 1510), (690, 1540)),
        ),
    ),
    AssetSpec(
        8,
        "healthy",
        SOURCE_ROOT / "第八关素材" / "珊瑚 (2).png",
        "level_08_coral_healthy.png",
        ((750, 445), (1245, 440), (1515, 610), (1630, 865), (1640, 1190),
         (1510, 1430), (1370, 1575), (650, 1605), (465, 1515), (405, 1280),
         (410, 890), (535, 620)),
        (
            ((610, 1450), (1410, 1450), (1360, 1560), (660, 1570)),
        ),
    ),
    AssetSpec(
        8,
        "wilted",
        SOURCE_ROOT / "第八关素材" / "珊瑚枯萎.png",
        "level_08_coral_wilted.png",
        ((750, 440), (1250, 440), (1515, 605), (1635, 860), (1645, 1190),
         (1515, 1440), (1375, 1575), (650, 1605), (460, 1515), (405, 1280),
         (410, 885), (535, 615)),
        (
            ((610, 1450), (1410, 1450), (1360, 1560), (660, 1570)),
        ),
    ),
    AssetSpec(
        9,
        "healthy",
        SOURCE_ROOT / "第九关素材" / "海带 (1).png",
        "level_09_kelp_healthy.png",
        ((505, 250), (720, 190), (920, 330), (1080, 180), (1260, 175),
         (1480, 345), (1690, 650), (1705, 1160), (1580, 1600), (1495, 1865),
         (540, 1880), (430, 1770), (350, 1380), (310, 820)),
        (
            ((590, 1760), (1460, 1760), (1420, 1840), (625, 1840)),
        ),
    ),
    AssetSpec(
        9,
        "wilted",
        SOURCE_ROOT / "第九关素材" / "海带枯萎.png",
        "level_09_kelp_wilted.png",
        ((335, 315), (700, 265), (930, 300), (1110, 115), (1320, 220),
         (1635, 430), (1710, 800), (1610, 1450), (1130, 1760), (1360, 1815),
         (1490, 1880), (1510, 1950), (1370, 1980), (590, 1980), (465, 1930),
         (500, 1870), (790, 1780), (370, 1790), (330, 1350), (300, 740)),
        (
            ((630, 1870), (760, 1815), (1250, 1815), (1390, 1880),
             (1360, 1950), (610, 1950)),
        ),
        (
            ((340, 1230), (620, 1230), (700, 1720), (370, 1760)),
            ((1390, 1360), (1650, 1260), (1590, 1740), (1390, 1740)),
        ),
    ),
    AssetSpec(
        10,
        "healthy",
        SOURCE_ROOT / "第十关素材" / "鲸落.png",
        "level_10_whale_fall_healthy.png",
        ((20, 865), (165, 675), (420, 520), (650, 330), (1430, 280), (1840, 390),
         (2020, 650), (2047, 1390), (1900, 1630), (1500, 1735), (520, 1785),
         (120, 1700), (0, 1470)),
        (
            ((170, 1350), (1870, 1350), (1790, 1640), (260, 1680)),
            ((410, 940), (600, 830), (835, 880), (760, 1035), (520, 1120)),
            ((760, 735), (1490, 495), (1660, 530), (1510, 640), (850, 875)),
        ),
    ),
    AssetSpec(
        10,
        "wilted",
        SOURCE_ROOT / "第十关素材" / "鲸落枯萎.png",
        "level_10_whale_fall_wilted.png",
        ((25, 920), (150, 700), (390, 515), (650, 300), (1430, 245), (1850, 400),
         (2020, 690), (2035, 1430), (1880, 1660), (1450, 1765), (500, 1810),
         (105, 1725), (0, 1500)),
        (
            ((150, 1380), (1890, 1380), (1800, 1680), (230, 1710)),
            ((300, 1000), (520, 870), (800, 930), (700, 1110), (430, 1180)),
            ((690, 760), (1510, 485), (1740, 520), (1540, 655), (790, 900)),
        ),
    ),
    AssetSpec(
        11,
        "healthy",
        SOURCE_ROOT / "第11关素材" / "水母.png",
        "level_11_jellyfish_healthy.png",
        ((255, 270), (1340, 270), (1590, 390), (1735, 735), (1740, 1510),
         (1600, 1805), (280, 1835), (230, 1510), (255, 870)),
        (
            ((850, 470), (1160, 450), (1260, 580), (1200, 680), (800, 675)),
            ((350, 750), (500, 730), (550, 820), (470, 875), (330, 850)),
            ((1490, 1100), (1680, 1090), (1730, 1170), (1660, 1230), (1460, 1210)),
            ((915, 760), (965, 760), (950, 1370), (900, 1450)),
            ((340, 860), (385, 860), (340, 1000), (305, 1025)),
            ((1550, 1220), (1590, 1220), (1570, 1460), (1530, 1485)),
        ),
    ),
    AssetSpec(
        11,
        "wilted",
        SOURCE_ROOT / "第11关素材" / "死亡水母.png",
        "level_11_jellyfish_wilted.png",
        ((95, 320), (1400, 315), (1650, 520), (1800, 900), (1800, 1640),
         (140, 1730), (90, 1320)),
        (
            ((760, 430), (1320, 400), (1510, 610), (1430, 900), (650, 910)),
            ((520, 900), (1020, 860), (1130, 1450), (420, 1580)),
            ((1050, 1250), (1270, 1230), (1320, 1370), (1240, 1450), (1010, 1430)),
            ((1450, 1200), (1690, 1180), (1750, 1330), (1680, 1450), (1400, 1420)),
        ),
    ),
    AssetSpec(
        12,
        "healthy",
        SOURCE_ROOT / "第12关素材" / "鱼群.png",
        "level_12_fish_school_healthy.png",
        ((75, 640), (1770, 650), (1840, 960), (1650, 1315), (300, 1390),
         (85, 1210)),
        (
            ((570, 755), (790, 750), (835, 820), (770, 865), (545, 850)),
            ((1010, 760), (1285, 755), (1330, 830), (1260, 875), (980, 855)),
            ((1450, 885), (1700, 880), (1740, 960), (1660, 1015), (1415, 990)),
            ((255, 980), (535, 965), (580, 1050), (505, 1110), (220, 1080)),
            ((805, 965), (1090, 955), (1140, 1035), (1060, 1090), (770, 1070)),
            ((1180, 1110), (1450, 1100), (1500, 1190), (1415, 1245), (1140, 1215)),
            ((565, 1170), (835, 1160), (885, 1240), (810, 1300), (530, 1270)),
        ),
    ),
    AssetSpec(
        12,
        "wilted",
        SOURCE_ROOT / "第12关素材" / "死亡鱼群.png",
        "level_12_fish_school_wilted.png",
        ((250, 530), (1590, 520), (1780, 755), (1810, 1465), (1030, 1490),
         (275, 1390)),
        (
            ((825, 610), (1260, 600), (1350, 685), (1240, 755), (780, 735)),
            ((450, 765), (850, 750), (925, 835), (825, 900), (405, 875)),
            ((1240, 850), (1605, 830), (1690, 920), (1580, 995), (1190, 970)),
            ((390, 995), (760, 975), (835, 1065), (735, 1130), (340, 1095)),
            ((900, 960), (1100, 940), (1160, 1120), (1060, 1260), (900, 1160)),
            ((480, 1225), (850, 1200), (925, 1290), (820, 1360), (430, 1330)),
            ((1230, 1190), (1600, 1160), (1690, 1260), (1570, 1350), (1180, 1315)),
            ((1125, 815), (1190, 805), (1210, 845), (1130, 860)),
            ((1300, 1100), (1390, 1085), (1420, 1130), (1310, 1160)),
        ),
    ),
    AssetSpec(
        13,
        "healthy",
        SOURCE_ROOT / "第13关素材" / "海沟.png",
        "level_13_trench_healthy.png",
        ((155, 650), (250, 570), (500, 450), (780, 360), (1030, 340),
         (1300, 390), (1530, 460), (1770, 590), (1850, 700), (1870, 1150),
         (1835, 1390), (1600, 1560), (1320, 1650), (1080, 1690), (520, 1670),
         (300, 1580), (175, 1440), (145, 1100), (145, 700)),
        (
            ((510, 450), (980, 370), (1420, 470), (1580, 600), (1320, 670), (650, 620)),
            ((215, 720), (410, 650), (455, 1360), (260, 1430)),
            ((1540, 690), (1770, 720), (1780, 1370), (1530, 1430)),
            ((660, 710), (1390, 680), (1500, 1070), (610, 1140)),
            ((430, 1230), (1560, 1160), (1690, 1450), (1370, 1590), (520, 1570), (300, 1450)),
        ),
    ),
    AssetSpec(
        13,
        "wilted",
        SOURCE_ROOT / "第13关素材" / "海沟枯萎.png",
        "level_13_trench_wilted.png",
        ((155, 650), (250, 570), (500, 450), (790, 360), (1040, 340),
         (1310, 390), (1540, 460), (1770, 590), (1850, 700), (1870, 1150),
         (1835, 1395), (1600, 1565), (1320, 1650), (1080, 1690), (520, 1670),
         (300, 1580), (175, 1440), (145, 1100), (145, 700)),
        (
            ((510, 450), (990, 370), (1430, 470), (1590, 600), (1330, 670), (650, 620)),
            ((215, 720), (410, 650), (455, 1360), (260, 1430)),
            ((1540, 690), (1770, 720), (1780, 1370), (1530, 1430)),
            ((660, 710), (1400, 680), (1500, 1070), (610, 1140)),
            ((430, 1230), (1560, 1160), (1690, 1450), (1370, 1590), (520, 1570), (300, 1450)),
        ),
    ),
)


def polygon(points: tuple[tuple[int, int], ...]) -> np.ndarray:
    return np.asarray(points, dtype=np.int32)


def extract_green_screen_rgba(spec: AssetSpec, bgr: np.ndarray) -> Image.Image:
    blue, green, red = cv2.split(bgr.astype(np.float32))
    green_score = green - np.maximum(red, blue)
    key_alpha = np.clip((28.0 - green_score) / 20.0, 0.0, 1.0)

    rough_foreground = np.zeros(bgr.shape[:2], dtype=np.uint8)
    cv2.fillPoly(rough_foreground, [polygon(spec.boundary)], 1)
    seed = np.zeros_like(rough_foreground)
    for points in spec.foreground:
        cv2.fillPoly(seed, [polygon(points)], 1)

    binary = ((key_alpha > 0.08) & (rough_foreground > 0)).astype(np.uint8)
    binary = cv2.morphologyEx(
        binary,
        cv2.MORPH_CLOSE,
        np.ones((3, 3), np.uint8),
    )
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    kept = np.zeros_like(binary)
    for label in range(1, count):
        component = labels == label
        if stats[label, cv2.CC_STAT_AREA] >= 32 and np.any(seed[component]):
            kept[component] = 1

    if spec.level == 12 and spec.state == "wilted":
        inside = cv2.distanceTransform(kept, cv2.DIST_L2, 5)
        outside = cv2.distanceTransform(1 - kept, cv2.DIST_L2, 5)
        signed = inside - outside
        alpha = np.clip((signed - 0.15) / 2.0 + 0.5, 0.0, 1.0)
        alpha = cv2.GaussianBlur(alpha, (0, 0), 0.55)
        alpha = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    else:
        alpha = np.clip(key_alpha * kept * 255.0, 0, 255).astype(np.uint8)
        alpha = cv2.GaussianBlur(alpha, (0, 0), 0.45)

    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB).astype(np.float32)
    spill = np.maximum(0.0, green - np.maximum(red, blue))
    if spec.level == 12 and spec.state == "wilted":
        edge_weight = 1.0 - alpha.astype(np.float32) / 255.0
        rgb[:, :, 1] = np.clip(
            rgb[:, :, 1] - spill * 0.82 * edge_weight,
            0,
            255,
        )
    else:
        rgb[:, :, 1] = np.clip(rgb[:, :, 1] - spill * 0.82, 0, 255)
    return Image.fromarray(np.dstack((rgb.astype(np.uint8), alpha)), "RGBA")


def extract_rgba(spec: AssetSpec) -> Image.Image:
    encoded = np.fromfile(spec.source, dtype=np.uint8)
    bgr = cv2.imdecode(encoded, cv2.IMREAD_COLOR)
    if bgr is None:
        raise FileNotFoundError(spec.source)
    if spec.level in (11, 12):
        return extract_green_screen_rgba(spec, bgr)

    mask = np.full(bgr.shape[:2], cv2.GC_BGD, dtype=np.uint8)
    cv2.fillPoly(mask, [polygon(spec.boundary)], cv2.GC_PR_FGD)
    for points in spec.foreground:
        cv2.fillPoly(mask, [polygon(points)], cv2.GC_FGD)
    for points in spec.background:
        cv2.fillPoly(mask, [polygon(points)], cv2.GC_BGD)

    exterior_red_background = np.zeros(bgr.shape[:2], dtype=bool)
    if spec.level == 13:
        hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
        red_candidate = (
            ((hsv[:, :, 0] <= 12) | (hsv[:, :, 0] >= 170))
            & (hsv[:, :, 1] >= 42)
            & (hsv[:, :, 2] >= 72)
            & (mask != cv2.GC_FGD)
        )
        component_count, component_labels, _, _ = cv2.connectedComponentsWithStats(
            red_candidate.astype(np.uint8),
            8,
        )
        edge_labels = np.unique(
            np.concatenate(
                (
                    component_labels[0, :],
                    component_labels[-1, :],
                    component_labels[:, 0],
                    component_labels[:, -1],
                )
            )
        )
        edge_labels = edge_labels[
            (edge_labels > 0) & (edge_labels < component_count)
        ]
        exterior_red_background = np.isin(component_labels, edge_labels)
        mask[exterior_red_background] = cv2.GC_BGD

    bg_model = np.zeros((1, 65), dtype=np.float64)
    fg_model = np.zeros((1, 65), dtype=np.float64)
    cv2.grabCut(bgr, mask, None, bg_model, fg_model, 8, cv2.GC_INIT_WITH_MASK)

    binary = np.isin(mask, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8)
    binary[exterior_red_background] = 0
    seed = (mask == cv2.GC_FGD).astype(np.uint8)

    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    if spec.level in (11, 12):
        green_background = (
            (hsv[:, :, 0] >= 32)
            & (hsv[:, :, 0] <= 78)
            & (hsv[:, :, 1] >= 52)
            & (seed == 0)
        )
        candidate_count, candidate_labels, _, _ = (
            cv2.connectedComponentsWithStats(
                green_background.astype(np.uint8),
                8,
            )
        )
        edge_labels = np.unique(
            np.concatenate(
                (
                    candidate_labels[0, :],
                    candidate_labels[-1, :],
                    candidate_labels[:, 0],
                    candidate_labels[:, -1],
                )
            )
        )
        edge_labels = edge_labels[
            (edge_labels > 0) & (edge_labels < candidate_count)
        ]
        binary[np.isin(candidate_labels, edge_labels)] = 0
    else:
        saturation_limit = 125 if spec.level == 10 else 92
        photographed_background = (
            (hsv[:, :, 0] >= 82)
            & (hsv[:, :, 0] <= 112)
            & (hsv[:, :, 1] <= saturation_limit)
            & (seed == 0)
        )
        if spec.level in (7, 8, 9):
            binary[photographed_background & (hsv[:, :, 1] <= 82)] = 0
        else:
            connectivity = photographed_background
            if spec.level == 10:
                # The whale skeleton encloses large pieces of the studio backdrop. Do not
                # let broad foreground seed polygons protect those blue-gray regions.
                connectivity = (
                    (hsv[:, :, 0] >= 80)
                    & (hsv[:, :, 0] <= 112)
                    & (hsv[:, :, 1] <= 72)
                )
            candidate_count, candidate_labels, candidate_stats, _ = (
                cv2.connectedComponentsWithStats(connectivity.astype(np.uint8), 8)
            )
            edge_labels = np.unique(
                np.concatenate(
                    (
                        candidate_labels[0, :],
                        candidate_labels[-1, :],
                        candidate_labels[:, 0],
                        candidate_labels[:, -1],
                    )
                )
            )
            edge_labels = edge_labels[(edge_labels > 0) & (edge_labels < candidate_count)]
            if spec.level == 10:
                large_labels = np.flatnonzero(candidate_stats[:, cv2.CC_STAT_AREA] >= 96)
                removable_labels = np.union1d(edge_labels, large_labels[large_labels > 0])
                binary[np.isin(candidate_labels, removable_labels)] = 0
            else:
                exterior_background = photographed_background & np.isin(
                    candidate_labels, edge_labels
                )
                binary[exterior_background] = 0

    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    kept = np.zeros_like(binary)
    for label in range(1, count):
        component = labels == label
        if stats[label, cv2.CC_STAT_AREA] >= 48 and np.any(seed[component]):
            kept[component] = 1

    inside = cv2.distanceTransform(kept, cv2.DIST_L2, 5)
    outside = cv2.distanceTransform(1 - kept, cv2.DIST_L2, 5)
    signed = inside - outside
    if spec.level == 6:
        # Keep a gentler, slightly fuller matte for the soft anemone and loose sand.
        alpha = np.clip((signed + 0.45) / 3.0 + 0.5, 0.0, 1.0)
        blur_sigma = 0.8
    else:
        alpha = np.clip((signed - 0.35) / 2.2 + 0.5, 0.0, 1.0)
        blur_sigma = 0.65
    alpha = cv2.GaussianBlur(alpha, (0, 0), blur_sigma)
    alpha = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)

    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    rgba = np.dstack((rgb, alpha))
    return Image.fromarray(rgba, "RGBA")


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.asarray(image.getchannel("A"))
    ys, xs = np.nonzero(alpha > 8)
    if not len(xs):
        raise ValueError("Empty alpha mask")
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def base_center_x(image: Image.Image, bbox: tuple[int, int, int, int]) -> float:
    alpha = np.asarray(image.getchannel("A"), dtype=np.float32) / 255.0
    left, top, right, bottom = bbox
    band_top = max(top, bottom - max(24, int((bottom - top) * 0.12)))
    band = alpha[band_top:bottom, left:right]
    weights = band.sum(axis=0)
    if weights.sum() <= 0:
        return (left + right) / 2.0
    xs = np.arange(left, right, dtype=np.float32)
    return float(np.dot(xs, weights) / weights.sum())


def align_pair(images: list[Image.Image], level: int) -> list[Image.Image]:
    bboxes = [alpha_bbox(image) for image in images]
    if level >= 11:
        crops = [image.crop(bbox) for image, bbox in zip(images, bboxes)]
        margin = 24
        canvas_size = (
            max(crop.width for crop in crops) + margin * 2,
            max(crop.height for crop in crops) + margin * 2,
        )
        aligned = []
        for crop in crops:
            paste_x = (canvas_size[0] - crop.width) // 2
            paste_y = (
                (canvas_size[1] - crop.height) // 2
                if level in (11, 12)
                else canvas_size[1] - margin - crop.height
            )
            canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            canvas.alpha_composite(crop, (paste_x, paste_y))
            aligned.append(canvas)
        return aligned

    max_width = max(right - left for left, _, right, _ in bboxes)
    max_height = max(bottom - top for _, top, _, bottom in bboxes)
    scale = min(
        (CANVAS_SIZE[0] - SIDE_MARGIN * 2) / max_width,
        (BASELINE_Y - TOP_MARGIN) / max_height,
    )

    aligned = []
    for image, bbox in zip(images, bboxes):
        left, top, right, bottom = bbox
        crop = image.crop((left, top, right, bottom))
        size = (
            max(1, round(crop.width * scale)),
            max(1, round(crop.height * scale)),
        )
        crop = crop.resize(size, Image.Resampling.LANCZOS)
        center_in_crop = (base_center_x(image, bbox) - left) * scale
        paste_x = round(CANVAS_SIZE[0] / 2 - center_in_crop)
        paste_y = BASELINE_Y - crop.height
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        canvas.alpha_composite(crop, (paste_x, paste_y))
        aligned.append(canvas)
    return aligned


def checkerboard(size: tuple[int, int], tile: int = 24) -> Image.Image:
    width, height = size
    result = Image.new("RGB", size, (232, 236, 240))
    draw = ImageDraw.Draw(result)
    for y in range(0, height, tile):
        for x in range(0, width, tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(188, 196, 204))
    return result


def composite_on(image: Image.Image, color: tuple[int, int, int] | None) -> Image.Image:
    background = checkerboard(image.size) if color is None else Image.new("RGB", image.size, color)
    background.paste(image, mask=image.getchannel("A"))
    return background


def preview_on(
    image: Image.Image,
    color: tuple[int, int, int] | None,
    size: tuple[int, int],
) -> Image.Image:
    background = checkerboard(size) if color is None else Image.new("RGB", size, color)
    preview = image.copy()
    preview.thumbnail((size[0] - 36, size[1] - 36), Image.Resampling.LANCZOS)
    position = (
        (size[0] - preview.width) // 2,
        (size[1] - preview.height) // 2,
    )
    background.paste(preview, position, preview.getchannel("A"))
    return background


def create_review(level: int, healthy: Image.Image, wilted: Image.Image) -> Image.Image:
    backgrounds = (
        ("checker", None),
        ("white", (250, 250, 248)),
        ("black", (12, 16, 20)),
        ("magenta", (255, 0, 190)),
    )
    panel_size = (700, 350)
    gutter = 18
    header = 64
    row_label = 34
    width = gutter * 3 + panel_size[0] * 2
    height = header + len(backgrounds) * (row_label + panel_size[1] + gutter)
    sheet = Image.new("RGB", (width, height), (25, 29, 34))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=22)
    small = ImageFont.load_default(size=17)
    draw.text((gutter, 12), f"LEVEL {level:02d}", fill=(245, 245, 242), font=font)
    draw.text((gutter + 210, 18), "healthy", fill=(255, 220, 80), font=small)
    draw.text((gutter * 2 + panel_size[0] + 210, 18), "wilted", fill=(255, 220, 80), font=small)

    y = header
    for label, color in backgrounds:
        draw.text((gutter, y), label, fill=(220, 226, 230), font=small)
        y += row_label
        sheet.paste(preview_on(healthy, color, panel_size), (gutter, y))
        sheet.paste(
            preview_on(wilted, color, panel_size),
            (gutter * 2 + panel_size[0], y),
        )
        y += panel_size[1] + gutter
    return sheet


def create_gap_review(level: int, healthy: Image.Image, wilted: Image.Image) -> Image.Image:
    panel_size = (760, 430)
    gutter = 20
    header = 50
    sheet = Image.new(
        "RGB",
        (panel_size[0] * 2 + gutter * 3, panel_size[1] * 2 + header + gutter * 2),
        (25, 29, 34),
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=22)
    draw.text((gutter, 12), f"LEVEL {level:02d} edge review", fill=(245, 245, 242), font=font)
    panels = (
        (healthy, (12, 16, 20), (gutter, header), "healthy / black"),
        (wilted, (12, 16, 20), (gutter * 2 + panel_size[0], header), "wilted / black"),
        (healthy, (255, 0, 190), (gutter, header + panel_size[1] + gutter), "healthy / magenta"),
        (
            wilted,
            (255, 0, 190),
            (gutter * 2 + panel_size[0], header + panel_size[1] + gutter),
            "wilted / magenta",
        ),
    )
    for image, color, position, label in panels:
        sheet.paste(preview_on(image, color, panel_size), position)
        draw.text(
            (position[0] + 16, position[1] + 12),
            label,
            fill=(255, 230, 70),
            stroke_width=2,
            stroke_fill=(0, 0, 0),
            font=font,
        )
    return sheet


def validate(image: Image.Image) -> dict[str, object]:
    alpha = np.asarray(image.getchannel("A"))
    bbox = alpha_bbox(image)
    return {
        "mode": image.mode,
        "size": image.size,
        "bbox": bbox,
        "alpha_min": int(alpha.min()),
        "alpha_max": int(alpha.max()),
        "opaque_fraction": round(float(np.mean(alpha >= 250)), 4),
    }


def parse_levels() -> tuple[int, ...]:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--levels",
        type=int,
        nargs="+",
        choices=range(6, 14),
        default=range(6, 14),
    )
    return tuple(dict.fromkeys(parser.parse_args().levels))


def main() -> None:
    levels = parse_levels()
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    REVIEW_ROOT.mkdir(parents=True, exist_ok=True)

    selected_specs = [spec for spec in SPECS if spec.level in levels]
    extracted = {(spec.level, spec.state): extract_rgba(spec) for spec in selected_specs}
    for level in levels:
        pair = [extracted[(level, "healthy")], extracted[(level, "wilted")]]
        healthy, wilted = align_pair(pair, level)
        pair_specs = [spec for spec in SPECS if spec.level == level]
        for spec, image in zip(pair_specs, (healthy, wilted)):
            target = OUTPUT_ROOT / spec.output_name
            image.save(target, optimize=True)
            print(target.relative_to(ROOT), validate(image))

        review = create_review(level, healthy, wilted)
        review_path = REVIEW_ROOT / f"level_{level:02d}_cutout_review.png"
        review.save(review_path, optimize=True)
        print(review_path.relative_to(ROOT), review.size)

        gap_review = create_gap_review(level, healthy, wilted)
        gap_review_path = REVIEW_ROOT / f"level_{level:02d}_gap_review.png"
        gap_review.save(gap_review_path, optimize=True)
        print(gap_review_path.relative_to(ROOT), gap_review.size)


if __name__ == "__main__":
    main()
