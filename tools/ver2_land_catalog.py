#!/usr/bin/env python3
"""Maintain the stable candidate catalog for docs/art/ver2bygpt.

The V2L_#### namespace identifies source/candidate images only. Approved runtime
assets keep or receive their separate ART_#### IDs in the authoritative catalog.

Commands:
  initialize  Build the curated catalog from the current image set.
  discover    Append IDs for new PNG files without renumbering existing rows.
  export      Refresh metadata and rebuild the Excel workbook.
  validate    Check IDs, paths, metadata, names, and workbook synchronization.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from openpyxl import Workbook, load_workbook
from openpyxl.formatting.rule import FormulaRule
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "docs" / "art" / "ver2bygpt"
MANIFEST = SOURCE_ROOT / "VER2_LAND_ART_CATALOG.json"
WORKBOOK = SOURCE_ROOT / "VER2_LAND_ART_CATALOG.xlsx"
ID_PATTERN = re.compile(r"^V2L_\d{4}$")
SHORT_PATTERN = re.compile(r"^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$")

# Ordering is permanent. Newly discovered files always continue after max_id.
INITIAL_ITEMS: list[tuple[str, str, str, str, str]] = [
    ("陆地关卡/关卡背景.png", "v2_land_background", "陆地关卡山谷场景背景", "背景", "基础"),
    ("陆地关卡/ART_0051_land_stage_body.png", "v2_land_stage_body", "陆地三联棋盘舞台主体", "棋盘舞台", "基础"),
    ("陆地关卡/中间徽记_微笑.png", "v2_land_robot_emblem_smile", "顶部中央机器人微笑徽记", "HUD组件", "微笑"),
    ("陆地关卡/剩余雷数显示框.png", "v2_land_mine_counter_frame", "顶部剩余雷数显示框", "HUD组件", "基础"),
    ("陆地关卡/计时框附着条.png", "v2_land_timer_attachment", "顶部计时器附着条", "HUD组件", "基础"),
    ("陆地关卡/开始暂停按钮.png", "v2_land_play_button_normal", "开始/暂停按钮（当前为播放图标）", "按钮", "常态"),
    ("陆地关卡/刷新按钮.png", "v2_land_refresh_button_normal", "重新生成按钮", "按钮", "常态"),
    ("陆地关卡/面板设置按钮.png", "v2_land_settings_button_normal", "设置按钮", "按钮", "常态"),
    ("陆地关卡/标记图标.png", "v2_land_counter_sprout_icon", "剩余雷数用小芽图标", "HUD图标", "基础"),
    ("陆地关卡/计时图标.png", "v2_land_timer_icon", "计时器秒表图标", "HUD图标", "基础"),
    ("陆地关卡/陆地标记.png", "v2_land_cell_sprout_marker", "棋盘格用小芽土堆标记", "棋盘标记", "常态"),
    ("陆地关卡/藤曼素材左.png", "v2_land_vine_left", "陆地舞台左侧藤蔓装饰", "装饰", "左侧"),
    ("陆地关卡/藤曼素材右.png", "v2_land_vine_right", "陆地舞台右侧藤蔓装饰", "装饰", "右侧"),
    ("陆地关卡/默认状态棋盘纸.png", "v2_land_cell_hidden", "陆地棋盘格（未翻开）", "棋盘格", "未翻开"),
    ("陆地关卡/翻开状态棋盘纸.png", "v2_land_cell_revealed", "陆地棋盘格（已翻开）", "棋盘格", "已翻开"),
    ("陆地关卡/污染状态棋盘纸.png", "v2_land_cell_polluted", "陆地棋盘格（污染）", "棋盘格", "污染"),
    ("陆地关卡/数字显示/1.png", "v2_land_digit_1", "陆地棋盘数字1", "棋盘数字", "数字1"),
    ("陆地关卡/数字显示/2.png", "v2_land_digit_2", "陆地棋盘数字2", "棋盘数字", "数字2"),
    ("陆地关卡/数字显示/3.png", "v2_land_digit_3", "陆地棋盘数字3", "棋盘数字", "数字3"),
    ("陆地关卡/数字显示/4.png", "v2_land_digit_4", "陆地棋盘数字4", "棋盘数字", "数字4"),
    ("陆地关卡/数字显示/5.png", "v2_land_digit_5", "陆地棋盘数字5", "棋盘数字", "数字5"),
    ("陆地关卡/数字显示/6.png", "v2_land_digit_6", "陆地棋盘数字6", "棋盘数字", "数字6"),
    ("陆地关卡/数字显示/7.png", "v2_land_digit_7", "陆地棋盘数字7", "棋盘数字", "数字7"),
    ("陆地关卡/数字显示/8.png", "v2_land_digit_8", "陆地棋盘数字8", "棋盘数字", "数字8"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆.png", "v2_land_slime_alert", "陆地污染核心史莱姆（警戒基准）", "污染怪角色", "警戒"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气.png", "v2_land_slime_defiant_a", "陆地污染核心史莱姆（不服气候选A）", "污染怪角色", "不服气A"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气2.png", "v2_land_slime_defiant_b", "陆地污染核心史莱姆（不服气候选B）", "污染怪角色", "不服气B"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_不服气3.png", "v2_land_slime_defiant_c", "陆地污染核心史莱姆（不服气候选C）", "污染怪角色", "不服气C"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_嘲笑.png", "v2_land_slime_mock_a", "陆地污染核心史莱姆（嘲笑候选A）", "污染怪角色", "嘲笑A"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_嘲笑2.png", "v2_land_slime_mock_b", "陆地污染核心史莱姆（嘲笑候选B）", "污染怪角色", "嘲笑B"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_嘲笑3.png", "v2_land_slime_mock_c", "陆地污染核心史莱姆（嘲笑候选C）", "污染怪角色", "嘲笑C"),
    ("陆地关卡/污染小怪兽/污染小怪兽_陆地史莱姆_被打倒.png", "v2_land_slime_defeated", "陆地污染核心史莱姆（被打倒）", "污染怪角色", "被打倒"),
    ("陆地关卡/主角机器人/正面/主角机器人正面.png", "v2_robot_front_full", "小芽机器人正面完整立姿", "机器人整图", "正面"),
    ("陆地关卡/主角机器人/正面/主角机器人头部.png", "v2_robot_front_head", "小芽机器人正面头部组件", "机器人组件", "正面头部"),
    ("陆地关卡/主角机器人/正面/主角机器人躯干.png", "v2_robot_front_torso", "小芽机器人正面躯干组件", "机器人组件", "正面躯干"),
    ("陆地关卡/主角机器人/正面/主角机器人手臂.png", "v2_robot_front_arm", "小芽机器人正面手臂组件", "机器人组件", "正面手臂"),
    ("陆地关卡/主角机器人/正面/主角机器人爪子.png", "v2_robot_front_claw", "小芽机器人正面纸爪组件", "机器人组件", "正面纸爪"),
    ("陆地关卡/主角机器人/正面/左手.png", "v2_robot_left_hand", "小芽机器人左手组件", "机器人组件", "左手"),
    ("陆地关卡/主角机器人/背面/主角机器人.png", "v2_robot_back_full", "小芽机器人背面完整立姿", "机器人整图", "背面"),
    ("陆地关卡/主角机器人/左侧/主角机器人.png", "v2_robot_left_full_a", "小芽机器人左侧完整立姿候选A", "机器人整图", "左侧A"),
    ("陆地关卡/主角机器人/左侧/主角机器人2.png", "v2_robot_left_full_b", "小芽机器人左侧完整立姿候选B", "机器人整图", "左侧B"),
    ("陆地关卡/主角机器人/左侧/主角机器人左前.png", "v2_robot_left_front_full", "小芽机器人左前方完整立姿", "机器人整图", "左前方"),
    ("陆地关卡/主角机器人/右侧/主角机器人_右.png", "v2_robot_right_full", "小芽机器人右侧完整立姿", "机器人整图", "右侧"),
    ("陆地关卡/主角机器人/右侧/主角机器人_右前.png", "v2_robot_right_front_full", "小芽机器人右前方完整立姿", "机器人整图", "右前方"),
    ("陆地关卡/主角机器人/右侧/主角机器人_右头像.png", "v2_robot_right_head", "小芽机器人右侧头部组件", "机器人组件", "右侧头部"),
    ("陆地关卡/主角机器人/右侧/主角机器人_右前头像.png", "v2_robot_right_front_head", "小芽机器人右前方头部组件", "机器人组件", "右前方头部"),
    ("陆地关卡/主角机器人/右侧/主角机器人_右躯干.png", "v2_robot_right_torso", "小芽机器人右侧躯干组件", "机器人组件", "右侧躯干"),
    ("陆地关卡/主角机器人/右侧/主角机器人_躯干.png", "v2_robot_right_front_torso", "小芽机器人右前方躯干组件", "机器人组件", "右前方躯干"),
    ("陆地关卡/棋盘操作区概念图.png", "v2_land_board_ui_concept", "陆地棋盘操作区概念图", "设计概念", "布局概念"),
    ("陆地关卡/UI尺寸概念图.png", "v2_land_ui_size_concept", "陆地关卡UI尺寸标注概念图", "设计概念", "尺寸标注"),
    ("1cf6f0e5-01ad-418c-8cd4-6d31c718662d.png", "v2_land_scene_concept_a", "陆地完整游戏界面概念图A", "设计概念", "场景方案A"),
    ("9843eb63-bfea-44be-82fb-43082413f7fe.png", "v2_land_scene_concept_b", "陆地完整游戏界面概念图B", "设计概念", "场景方案B"),
    ("全局落地色卡.png", "v2_global_color_board", "全局落地色卡", "色彩参考", "全局色板"),
    ("四章节配色概念图.png", "v2_chapter_color_concept", "四章节配色概念图", "色彩参考", "章节色板"),
    ("concepts/four_worlds_concept_v01.png", "v2_four_worlds_concept", "陆海空宇四世界综合概念图", "设计概念", "四章概念"),
    ("references/桌面背景5.png", "v2_ref_land_desktop", "既有陆地桌面背景参考", "历史参考", "陆地背景"),
    ("references/棋盘.png", "v2_ref_land_board", "既有陆地棋盘参考", "历史参考", "陆地棋盘"),
    ("references/棋盘托2.png", "v2_ref_land_board_tray", "既有陆地棋盘托参考", "历史参考", "陆地棋盘托"),
    ("references/第三版棋盘灰蓝背景.png", "v2_ref_land_board_grayblue", "既有灰蓝陆地棋盘参考", "历史参考", "灰蓝棋盘"),
    ("references/海洋棋盘桌面.png", "v2_ref_ocean_board", "既有海洋棋盘桌面参考", "历史参考", "海洋棋盘"),
    ("references/天空棋盘桌面2.png", "v2_ref_sky_board", "既有天空棋盘桌面参考", "历史参考", "天空棋盘"),
    ("陆地关卡/关卡生态元素/第一关_萌芽.png", "v2_land_l01_sprout_healthy", "第1关嫩芽生态（健康）", "关卡生态", "第1关健康"),
    ("陆地关卡/关卡生态元素/第一关_萌芽_污染.png", "v2_land_l01_sprout_polluted", "第1关嫩芽生态（污染）", "关卡生态", "第1关污染"),
    ("陆地关卡/关卡生态元素/第二关_灌木.png", "v2_land_l02_shrub_healthy", "第2关灌木生态（健康）", "关卡生态", "第2关健康"),
    ("陆地关卡/关卡生态元素/第二关_灌木_污染.png", "v2_land_l02_shrub_polluted", "第2关灌木生态（污染）", "关卡生态", "第2关污染"),
    ("陆地关卡/关卡生态元素/第三关_湿地.png", "v2_land_l03_wetland_healthy", "第3关湿地生态（健康）", "关卡生态", "第3关健康"),
    ("陆地关卡/关卡生态元素/第三关_湿地_污染.png", "v2_land_l03_wetland_polluted", "第3关湿地生态（污染）", "关卡生态", "第3关污染"),
    ("陆地关卡/关卡生态元素/第四关_草原.png", "v2_land_l04_grassland_healthy", "第4关草原生态（健康）", "关卡生态", "第4关健康"),
    ("陆地关卡/关卡生态元素/第四关_草原_污染.png", "v2_land_l04_grassland_polluted", "第4关草原生态（污染）", "关卡生态", "第4关污染"),
    ("陆地关卡/关卡生态元素/第五关_林缘.png", "v2_land_l05_forest_edge_healthy", "第5关森林边缘生态（健康）", "关卡生态", "第5关健康"),
    ("陆地关卡/关卡生态元素/第五关_林缘_污染.png", "v2_land_l05_forest_edge_polluted", "第5关森林边缘生态（污染）", "关卡生态", "第5关污染"),
    ("陆地关卡/关卡生态元素/第六关_密林.png", "v2_land_l06_dense_forest_healthy", "第6关密林生态（健康）", "关卡生态", "第6关健康"),
    ("陆地关卡/关卡生态元素/第六关_密林_污染.png", "v2_land_l06_dense_forest_polluted", "第6关密林生态（污染）", "关卡生态", "第6关污染"),
    ("陆地关卡/关卡生态元素/第七关_古林.png", "v2_land_l07_ancient_forest_healthy", "第7关古林生态（健康）", "关卡生态", "第7关健康"),
    ("陆地关卡/关卡生态元素/第七关_古林_污染.png", "v2_land_l07_ancient_forest_polluted", "第7关古林生态（污染）", "关卡生态", "第7关污染"),
    ("陆地关卡/陆地标记_枯萎.png", "v2_land_cell_sprout_wilted", "棋盘格用小芽土堆标记（枯萎）", "棋盘标记", "枯萎"),
    ("陆地关卡/陆地标记_cuowu .png", "v2_land_wrong_marker_feedback", "棋盘错误标记反馈（史莱姆拔起小芽）", "错误反馈插画", "错误标记"),
    ("陆地关卡/关卡生态元素/第一关_萌芽_胜利展示生态世界.png", "v2_land_l01_victory_ecology", "第1关萌芽生态（胜利展示）", "胜利展示生态", "第1关胜利"),
    ("陆地关卡/关卡生态元素/第三关_湿地_胜利展示生态世界.png", "v2_land_l03_victory_ecology", "第3关湿地生态（胜利展示）", "胜利展示生态", "第3关胜利"),
    ("陆地关卡/关卡生态元素/第二关_灌木_胜利展示生态世界..png", "v2_land_l02_victory_ecology", "第2关灌木生态（胜利展示）", "胜利展示生态", "第2关胜利"),
    ("陆地关卡/关卡生态元素/第四关_草原_胜利展示生态世界.png", "v2_land_l04_victory_ecology", "第4关草原生态（胜利展示）", "胜利展示生态", "第4关胜利"),
    ("陆地关卡/关卡生态元素/第七关_古林_胜利展示生态世界.png", "v2_land_l07_victory_ecology", "第7关古林生态（胜利展示）", "胜利展示生态", "第7关胜利"),
    ("陆地关卡/关卡生态元素/第五关_林缘_胜利展示生态世界.png", "v2_land_l05_victory_ecology", "第5关林缘生态（胜利展示）", "胜利展示生态", "第5关胜利"),
    ("陆地关卡/关卡生态元素/第六关_密林_胜利展示生态世界.png", "v2_land_l06_victory_ecology", "第6关密林生态（胜利展示）", "胜利展示生态", "第6关胜利"),
]

HEADERS = [
    "编号", "素材名称（中文）", "规范短名", "大类", "状态/视角", "资产层级",
    "闭环角色", "候选组", "当前文件", "文件状态", "尺寸", "Alpha状态", "透明像素%",
    "安全边界", "文件大小KB", "SHA-256", "建议处理", "对应正式ART编号",
    "提示词代号", "权利状态", "审核状态", "备注",
]

def sha256_for(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def alpha_metadata(image: Image.Image) -> tuple[str, float, str]:
    if "A" not in image.mode:
        return "无Alpha（整图）", 0.0, "整幅画布"
    alpha = image.getchannel("A")
    histogram = alpha.histogram()
    total = image.width * image.height
    zero_percent = round(histogram[0] * 100.0 / total, 2)
    minimum, maximum = alpha.getextrema()
    if minimum == maximum == 255:
        alpha_status = "RGBA但全不透明"
    elif zero_percent >= 1.0:
        alpha_status = "有透明背景"
    elif maximum < 255 or sum(histogram[1:250]) > total * 0.02:
        alpha_status = "整幅半透明（需检查）"
    else:
        alpha_status = "透明边角很少"

    threshold = alpha.point(lambda value: 255 if value >= 32 else 0)
    bbox = threshold.getbbox()
    if bbox is None:
        boundary = "无可见内容"
    else:
        left, top, right, bottom = bbox
        margins = [
            left / image.width,
            top / image.height,
            (image.width - right) / image.width,
            (image.height - bottom) / image.height,
        ]
        margin_text = "/".join(f"{value * 100:.1f}%" for value in margins)
        boundary = (
            f"边距不足 L/T/R/B={margin_text}"
            if min(margins) < 0.01
            else f"有安全边距 L/T/R/B={margin_text}"
        )
    return alpha_status, zero_percent, boundary


def candidate_group(short_name: str, category: str) -> str:
    if "slime_defiant" in short_name:
        return "史莱姆·不服气三选一"
    if "slime_mock" in short_name:
        return "史莱姆·嘲笑三选一"
    if "slime_" in short_name:
        return "史莱姆状态组"
    if "digit_" in short_name:
        return "棋盘数字1–8"
    if category == "胜利展示生态":
        match = re.search(r"_l(\d{2})_", short_name)
        return f"第{int(match.group(1))}关胜利展示" if match else "关卡胜利展示"
    if category == "关卡生态":
        match = re.search(r"_l(\d{2})_", short_name)
        return f"第{int(match.group(1))}关生态健康/污染组" if match else "关卡生态状态组"
    if category == "错误反馈插画":
        return "棋盘错误反馈"
    if "cell_" in short_name and category == "棋盘格":
        return "棋盘格状态组"
    if "button" in short_name:
        return "操作按钮组"
    if short_name.startswith("v2_robot_front") or short_name == "v2_robot_left_hand":
        return "机器人正面与拆件"
    if short_name.startswith("v2_robot_left"):
        return "机器人左侧候选组"
    if short_name.startswith("v2_robot_right"):
        return "机器人右侧与拆件"
    if short_name == "v2_robot_back_full":
        return "机器人背面"
    if category in {"设计概念", "色彩参考"}:
        return "方案与规格参考"
    if category == "历史参考":
        return "旧版输入参考"
    return category


def asset_tier(category: str) -> str:
    if category == "历史参考":
        return "历史输入"
    if category in {"设计概念", "色彩参考"}:
        return "设计参考"
    return "运行候选"


def closure_role(category: str) -> str:
    if category in {"背景", "棋盘舞台", "按钮", "HUD组件", "HUD图标", "棋盘标记", "错误反馈插画", "棋盘格", "棋盘数字", "关卡生态", "污染怪角色", "机器人整图"}:
        return "核心闭环"
    if category == "胜利展示生态":
        return "胜利演出扩展"
    if category == "机器人组件":
        return "动画拆分"
    if category == "装饰":
        return "可选装饰"
    return "不进入运行闭环"


def recommended_action(short_name: str, category: str, alpha_status: str) -> str:
    if category == "背景":
        return "候选；需在1280×720实机确认构图与底部舞台留白"
    if category == "棋盘舞台":
        return "候选；保持V2L编号，实机确认开口、三联比例和响应式布局"
    if category == "按钮":
        return "本轮运行预览四态共用同一无字图，hover/focus/pressed由Godot缩放反馈；用户确认后再决定是否补独立状态PNG"
    if category in {"HUD组件", "HUD图标"}:
        return "候选；按最终24–64px显示尺寸检查可读性并与Godot文字分层"
    if category == "棋盘标记":
        return "候选；需在34×34格内检查轮廓，另补正确/错误揭示状态"
    if category == "错误反馈插画":
        return "大幅复合错误反馈插画；可用于触雷/误标反馈层，不建议直接缩成34×34棋盘标记"
    if category == "棋盘格":
        suffix = "；当前Alpha覆盖整幅画布" if "整幅半透明" in alpha_status else ""
        return "三张基础贴图已够；悬停、键盘焦点和扫描继续由cell.gd动态绘制，接入时让hover复用基础格并进行34×34测试" + suffix
    if category == "棋盘数字":
        return "已接入实际1–8图片，按棋盘格内82%等比显示；陆地数字不再使用Godot动态文字，实机可读性由用户确认"
    if category == "胜利展示生态":
        return "第1–7关大型通关演出已齐全；统一作为底部舞台胜利展示层，不替代棋盘内健康/污染成对生态"
    if category == "关卡生态":
        if "_l05_" in short_name:
            return "健康/污染成对齐全；两张源图尺寸不同，接入前必须统一画布、中心、底线和占位"
        return "健康/污染成对齐全；接入前统一同关两张图的画布、中心、底线和占位"
    if category == "装饰":
        return "可选；不得遮挡棋盘、左右文字安全区或底部角色"
    if category == "污染怪角色":
        if "defiant" in short_name:
            return "三张不服气状态均已接入待机随机轮换；实机确认切换节奏、画布中心和底线"
        if short_name == "v2_land_slime_mock_a":
            return "已接入玩家失败嘲笑状态；实机确认动作与画布中心、底线"
        if short_name == "v2_land_slime_defeated":
            return "已接入玩家胜利被打倒状态；实机确认静止姿态与画布中心、底线"
        if "mock" in short_name:
            return "同表情备用候选；当前运行预览使用嘲笑候选A"
        return "状态候选；与选定基准统一画布、中心、轮廓和底线"
    if category == "机器人整图":
        if short_name in {
            "v2_robot_left_front_full",
            "v2_robot_front_full",
            "v2_robot_right_front_full",
        }:
            return "已接入陆地左前、正面、右前随机待机与轻微晃动；实机确认切换节奏和编辑器占位匹配"
        return "视角候选；先选定各方向唯一基准，再制作动作与失败/胜利状态"
    if category == "机器人组件":
        if short_name in {"v2_robot_front_arm", "v2_robot_right_front_torso"}:
            return "已接入陆地充能、胜利挥臂与失败触电动作；实机确认接缝、锚点和遮挡顺序"
        return "动画拆件候选；需检查与选定整图的比例、接缝、锚点和遮挡顺序"
    if category in {"设计概念", "色彩参考"}:
        return "仅用于方案追溯，不作为游戏运行素材"
    if category == "历史参考":
        return "旧版输入参考，不分配正式运行路径"
    return "待人工确认"


OFFICIAL_LINKS = {
    "v2_land_background": "ART_0211（运行预览，待用户确认）",
    "v2_land_stage_body": "ART_0242（运行预览，待用户确认）",
    "v2_land_robot_emblem_smile": "ART_0235（运行预览，待用户确认）",
    "v2_land_mine_counter_frame": "ART_0234（运行预览，待用户确认）",
    "v2_land_timer_attachment": "ART_0238（运行预览，待用户确认）",
    "v2_land_play_button_normal": "ART_0212（运行预览，四态共用并由程序缩放反馈）",
    "v2_land_refresh_button_normal": "ART_0213（运行预览，四态共用并由程序缩放反馈）",
    "v2_land_settings_button_normal": "ART_0214（已进入运行库，当前未引用）",
    "v2_land_counter_sprout_icon": "ART_0236（运行预览，待用户确认）",
    "v2_land_timer_icon": "ART_0237（运行预览，待用户确认）",
    "v2_land_cell_sprout_marker": "ART_0239（运行预览，待用户确认）",
    "v2_land_cell_hidden": "ART_0215（运行预览，待用户确认）",
    "v2_land_cell_revealed": "ART_0217（运行预览，待用户确认）",
    "v2_land_cell_polluted": "ART_0216（运行预览，待用户确认）",
    "v2_land_digit_1": "ART_0250（运行预览，待用户确认）",
    "v2_land_digit_2": "ART_0251（运行预览，待用户确认）",
    "v2_land_digit_3": "ART_0252（运行预览，待用户确认）",
    "v2_land_digit_4": "ART_0253（运行预览，待用户确认）",
    "v2_land_digit_5": "ART_0254（运行预览，待用户确认）",
    "v2_land_digit_6": "ART_0255（运行预览，待用户确认）",
    "v2_land_digit_7": "ART_0256（运行预览，待用户确认）",
    "v2_land_digit_8": "ART_0257（运行预览，待用户确认）",
    "v2_land_slime_alert": "ART_0218（运行预览，待用户确认）",
    "v2_land_slime_defiant_a": "ART_0261（运行预览，待机随机轮换）",
    "v2_land_slime_defiant_b": "ART_0262（运行预览，待机随机轮换）",
    "v2_land_slime_defiant_c": "ART_0263（运行预览，待机随机轮换）",
    "v2_land_slime_mock_a": "ART_0264（运行预览，玩家失败状态）",
    "v2_land_slime_defeated": "ART_0265（运行预览，玩家胜利状态）",
    "v2_robot_front_full": "ART_0219（运行预览，随机待机正面）",
    "v2_robot_front_arm": "ART_0260（运行预览，陆地动作拆件）",
    "v2_robot_left_front_full": "ART_0266（运行预览，随机待机左前）",
    "v2_robot_right_front_full": "ART_0258（运行预览，随机待机右前）",
    "v2_robot_right_front_torso": "ART_0259（运行预览，陆地动作拆件）",
    "v2_land_l01_sprout_healthy": "ART_0220（运行预览，待用户确认）",
    "v2_land_l01_sprout_polluted": "ART_0221（运行预览，待用户确认）",
    "v2_land_l02_shrub_healthy": "ART_0222（运行预览，待用户确认）",
    "v2_land_l02_shrub_polluted": "ART_0223（运行预览，待用户确认）",
    "v2_land_l03_wetland_healthy": "ART_0224（运行预览，待用户确认）",
    "v2_land_l03_wetland_polluted": "ART_0225（运行预览，待用户确认）",
    "v2_land_l04_grassland_healthy": "ART_0226（运行预览，待用户确认）",
    "v2_land_l04_grassland_polluted": "ART_0227（运行预览，待用户确认）",
    "v2_land_l05_forest_edge_healthy": "ART_0228（运行预览，待用户确认）",
    "v2_land_l05_forest_edge_polluted": "ART_0229（运行预览，待用户确认）",
    "v2_land_l06_dense_forest_healthy": "ART_0230（运行预览，待用户确认）",
    "v2_land_l06_dense_forest_polluted": "ART_0231（运行预览，待用户确认）",
    "v2_land_l07_ancient_forest_healthy": "ART_0232（运行预览，待用户确认）",
    "v2_land_l07_ancient_forest_polluted": "ART_0233（运行预览，待用户确认）",
    "v2_land_cell_sprout_wilted": "ART_0240（运行预览，待用户确认）",
    "v2_land_wrong_marker_feedback": "ART_0241（运行预览，作为误标反馈）",
    "v2_land_l01_victory_ecology": "ART_0243（运行预览，待用户确认）",
    "v2_land_l02_victory_ecology": "ART_0244（运行预览，待用户确认）",
    "v2_land_l03_victory_ecology": "ART_0245（运行预览，待用户确认）",
    "v2_land_l04_victory_ecology": "ART_0246（运行预览，待用户确认）",
    "v2_land_l05_victory_ecology": "ART_0247（运行预览，待用户确认）",
    "v2_land_l06_victory_ecology": "ART_0248（运行预览，待用户确认）",
    "v2_land_l07_victory_ecology": "ART_0249（运行预览，待用户确认）",
}


def prompt_id(category: str) -> str:
    return {
        "背景": "PRM_BG_LAND",
        "棋盘舞台": "PRM_STAGE_LAND",
        "按钮": "PRM_BUTTON",
        "HUD组件": "PRM_PANEL",
        "HUD图标": "PRM_MARKER",
        "棋盘标记": "PRM_MARKER",
        "错误反馈插画": "PRM_MARKER",
        "棋盘格": "PRM_CELL_LAND",
        "棋盘数字": "PRM_CELL_LAND",
        "关卡生态": "PRM_ECOLOGY",
        "胜利展示生态": "PRM_ECOLOGY",
        "装饰": "PRM_ECOLOGY",
        "污染怪角色": "PRM_MONSTER",
        "机器人整图": "PRM_ROBOT",
        "机器人组件": "PRM_ROBOT",
        "设计概念": "PRM_STYLE_BOARD",
        "色彩参考": "PRM_STYLE",
        "历史参考": "参考资料",
    }.get(category, "PRM_STYLE")


def metadata_for(path: Path) -> dict[str, Any]:
    with Image.open(path) as image:
        alpha_status, zero_percent, boundary = alpha_metadata(image)
        dimensions = f"{image.width}×{image.height}"
    return {
        "format": path.suffix.removeprefix(".").upper(),
        "dimensions": dimensions,
        "alpha_status": alpha_status,
        "transparent_percent": zero_percent,
        "safe_boundary": boundary,
        "file_size_kb": round(path.stat().st_size / 1024.0, 1),
        "sha256": sha256_for(path),
    }


def build_entry(index: int, item: tuple[str, str, str, str, str]) -> dict[str, Any]:
    relative, short_name, name, category, state = item
    path = SOURCE_ROOT / relative
    if not path.exists():
        raise SystemExit(f"Missing expected image: {relative}")
    tier = asset_tier(category)
    entry = {
        "id": f"V2L_{index:04d}",
        "asset_name": name,
        "short_name": short_name,
        "category": category,
        "state_view": state,
        "asset_tier": tier,
        "closure_role": closure_role(category),
        "candidate_group": candidate_group(short_name, category),
        "path": relative,
        "file_status": "存在",
        "recommended_action": recommended_action(short_name, category, ""),
        "official_art_id": OFFICIAL_LINKS.get(short_name, ""),
        "prompt_id": prompt_id(category),
        "rights_status": "待复核",
        "review_status": "待用户确认",
        "note": "",
    }
    entry.update(metadata_for(path))
    entry["recommended_action"] = recommended_action(
        short_name, category, entry["alpha_status"]
    )
    return entry

EDITABLE_FIELDS = {
    "素材名称（中文）": "asset_name",
    "规范短名": "short_name",
    "大类": "category",
    "状态/视角": "state_view",
    "资产层级": "asset_tier",
    "闭环角色": "closure_role",
    "候选组": "candidate_group",
    "当前文件": "path",
    "建议处理": "recommended_action",
    "对应正式ART编号": "official_art_id",
    "提示词代号": "prompt_id",
    "权利状态": "rights_status",
    "审核状态": "review_status",
    "备注": "note",
}


def load_payload() -> dict[str, Any]:
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if payload.get("schema") != 1:
        raise SystemExit(f"Unsupported catalog schema: {payload.get('schema')}")
    return payload


def save_payload(payload: dict[str, Any]) -> None:
    highest = max(
        [int(entry["id"].split("_")[1]) for entry in payload["entries"]] or [0]
    )
    payload["schema"] = 1
    payload["id_format"] = "V2L_####"
    payload["namespace"] = "ver2bygpt Land candidate/source images"
    payload["source_of_truth"] = "docs/art/ver2bygpt/VER2_LAND_ART_CATALOG.xlsx"
    payload["authoritative_runtime_catalog"] = "docs/art/GAME_ART_CATALOG.xlsx"
    payload["max_id"] = max(int(payload.get("max_id", 0)), highest)
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def refresh_entries(entries: list[dict[str, Any]]) -> None:
    for entry in entries:
        path = SOURCE_ROOT / entry["path"]
        if path.exists() and path.is_file():
            entry["file_status"] = "存在"
            entry.update(metadata_for(path))
        else:
            entry["file_status"] = "文件缺失"


def iter_png_paths() -> list[Path]:
    return sorted(
        [path for path in SOURCE_ROOT.rglob("*.png") if path.is_file()],
        key=lambda path: path.relative_to(SOURCE_ROOT).as_posix(),
    )


def generic_entry(path: Path, index: int) -> dict[str, Any]:
    relative = path.relative_to(SOURCE_ROOT).as_posix()
    stem = re.sub(r"[^a-z0-9]+", "_", path.stem.lower()).strip("_")
    short_name = f"v2_land_{stem}" if stem else f"v2_land_asset_{index:04d}"
    entry = {
        "id": f"V2L_{index:04d}",
        "asset_name": f"新增候选素材：{path.stem}",
        "short_name": short_name[:48].rstrip("_"),
        "category": "待分类",
        "state_view": "待填写",
        "asset_tier": "运行候选",
        "closure_role": "待判断",
        "candidate_group": "新增待分类",
        "path": relative,
        "file_status": "存在",
        "recommended_action": "请在Excel中补充具体名称、类别、用途与状态",
        "official_art_id": "",
        "prompt_id": "PRM_STYLE",
        "rights_status": "待复核",
        "review_status": "待用户确认",
        "note": "由discover自动追加",
    }
    digit_match = re.fullmatch(r"number_([1-8])", path.stem.lower())
    if path.parent.name == "数字显示" and digit_match:
        digit = int(digit_match.group(1))
        entry.update({
            "asset_name": f"陆地新版棋盘数字{digit}",
            "short_name": f"v2_land_number_{digit}",
            "category": "棋盘数字",
            "state_view": f"新版数字{digit}",
            "closure_role": "核心闭环",
            "candidate_group": "新版棋盘数字1–8",
            "recommended_action": "替换旧版运行数字；按棋盘格内82%等比显示并由用户实机确认",
            "official_art_id": f"ART_{249 + digit:04d}（运行预览，新版数字）",
            "prompt_id": "PRM_CELL_LAND",
            "note": "用户新增的number_1～number_8替换组",
        })
    entry.update(metadata_for(path))
    return entry


def discover() -> None:
    payload = load_payload()
    entries = payload["entries"]
    current = {
        path.relative_to(SOURCE_ROOT).as_posix(): path for path in iter_png_paths()
    }
    known = {entry["path"]: entry for entry in entries}
    missing = [entry for entry in entries if entry["path"] not in current]
    untracked = {relative: path for relative, path in current.items() if relative not in known}

    missing_by_hash: dict[str, list[dict[str, Any]]] = {}
    for entry in missing:
        checksum = entry.get("sha256", "")
        if checksum:
            missing_by_hash.setdefault(checksum, []).append(entry)
    new_by_hash: dict[str, list[tuple[str, Path]]] = {}
    for relative, path in untracked.items():
        new_by_hash.setdefault(sha256_for(path), []).append((relative, path))

    moved = 0
    for checksum, old_entries in missing_by_hash.items():
        new_paths = new_by_hash.get(checksum, [])
        if len(old_entries) == 1 and len(new_paths) == 1:
            entry = old_entries[0]
            new_relative, _path = new_paths[0]
            print(f"Preserved {entry['id']}: {entry['path']} -> {new_relative}")
            entry["path"] = new_relative
            untracked.pop(new_relative, None)
            moved += 1

    next_id = max(
        int(payload.get("max_id", 0)),
        max([int(entry["id"].split("_")[1]) for entry in entries] or [0]),
    )
    added = 0
    used_names = {entry["short_name"] for entry in entries}
    for relative in sorted(untracked):
        next_id += 1
        entry = generic_entry(untracked[relative], next_id)
        base = entry["short_name"]
        counter = 2
        while entry["short_name"] in used_names:
            entry["short_name"] = f"{base}_{counter}"
            counter += 1
        used_names.add(entry["short_name"])
        entries.append(entry)
        added += 1
    payload["max_id"] = next_id
    entries.sort(key=lambda item: int(item["id"].split("_")[1]))
    refresh_entries(entries)
    save_payload(payload)
    export_workbook(entries)
    print(f"Added {added} new images and preserved {moved} moved IDs")


def style_header(sheet: Any, color: str = "31583F") -> None:
    fill = PatternFill("solid", fgColor=color)
    font = Font(color="FFFFFF", bold=True)
    for cell in sheet[1]:
        cell.fill = fill
        cell.font = font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    sheet.row_dimensions[1].height = 30


def add_list_validation(sheet: Any, column: str, values: list[str]) -> None:
    validation = DataValidation(
        type="list", formula1='"' + ",".join(values) + '"', allow_blank=False
    )
    sheet.add_data_validation(validation)
    validation.add(f"{column}2:{column}2000")


def export_workbook(entries: list[dict[str, Any]]) -> None:
    workbook = Workbook()
    sheet = workbook.active
    sheet.title = "新素材总表"
    sheet.append(HEADERS)
    style_header(sheet)

    tier_colors = {
        "运行候选": "E2F0D9",
        "设计参考": "FFF2CC",
        "历史输入": "E7E6E6",
    }
    for entry in sorted(entries, key=lambda item: int(item["id"].split("_")[1])):
        sheet.append([
            entry["id"], entry["asset_name"], entry["short_name"], entry["category"],
            entry["state_view"], entry["asset_tier"], entry["closure_role"],
            entry["candidate_group"], entry["path"], entry.get("file_status", ""),
            entry.get("dimensions", ""), entry.get("alpha_status", ""),
            entry.get("transparent_percent", 0.0), entry.get("safe_boundary", ""),
            entry.get("file_size_kb", 0.0), entry.get("sha256", ""),
            entry["recommended_action"], entry.get("official_art_id", ""),
            entry["prompt_id"], entry.get("rights_status", "待复核"),
            entry.get("review_status", "待用户确认"), entry.get("note", ""),
        ])
        row = sheet.max_row
        sheet.cell(row, 6).fill = PatternFill(
            "solid", fgColor=tier_colors.get(entry["asset_tier"], "FFFFFF")
        )
        path_cell = sheet.cell(row, 9)
        if entry.get("file_status") == "存在":
            path_cell.hyperlink = entry["path"]
            path_cell.style = "Hyperlink"
        for column in range(1, len(HEADERS) + 1):
            sheet.cell(row, column).alignment = Alignment(vertical="top", wrap_text=True)
        for column in [1, 4, 5, 6, 7, 10, 11, 12, 13, 15, 19, 20, 21]:
            sheet.cell(row, column).alignment = Alignment(
                horizontal="center", vertical="top", wrap_text=True
            )

    widths = [13, 38, 36, 18, 16, 15, 16, 28, 65, 13, 14, 22, 14, 42, 14, 18, 62, 30, 20, 15, 16, 34]
    for index, width in enumerate(widths, 1):
        sheet.column_dimensions[get_column_letter(index)].width = width
    sheet.freeze_panes = "I2"
    sheet.auto_filter.ref = sheet.dimensions
    add_list_validation(sheet, "F", ["运行候选", "设计参考", "历史输入"])
    add_list_validation(sheet, "T", ["待复核", "已确认商用", "需替换"])
    add_list_validation(sheet, "U", ["待用户确认", "保留", "淘汰", "已映射正式素材"])
    sheet.conditional_formatting.add(
        f"U2:U{sheet.max_row}",
        FormulaRule(formula=['$U2="保留"'], fill=PatternFill("solid", fgColor="C6E0B4")),
    )
    sheet.conditional_formatting.add(
        f"T2:T{sheet.max_row}",
        FormulaRule(formula=['$T2="需替换"'], fill=PatternFill("solid", fgColor="F4CCCC")),
    )

    analysis = workbook.create_sheet("闭环与缺口")
    analysis.column_dimensions["A"].width = 24
    analysis.column_dimensions["B"].width = 105
    analysis.append(["项目", "分析结论"])
    tier_counts: dict[str, int] = {}
    for entry in entries:
        tier_counts[entry["asset_tier"]] = tier_counts.get(entry["asset_tier"], 0) + 1
    rows = [
        ["图片总数", f"{len(entries)}张PNG：{tier_counts.get('运行候选', 0)}张运行候选、{tier_counts.get('设计参考', 0)}张设计/色彩参考、{tier_counts.get('历史输入', 0)}张历史输入参考。"],
        ["已形成的闭环", "陆地背景、三联棋盘舞台、HUD框与图标、三个操作按钮、三种棋盘格、1–8数字、小芽标记、藤蔓装饰、1–7关健康/污染生态组、1–7关大型胜利展示生态、污染史莱姆状态组、机器人多视角与动画拆件。"],
        ["按钮实现", "开始/暂停、刷新、设置目前都只有单一无字外观。本轮运行预览让normal/hover/pressed/focus共用同一贴图，并由Godot缩放反馈交互；用户确认整体方向后再决定是否补独立状态PNG。"],
        ["棋盘格实现方式", "未翻开、已翻开、污染三张基础纸面已经足够。悬停与键盘焦点继续由cell.gd绘制不同颜色/粗细的虚线内框；扫描候选由四角线框表示，安全/危险结果由扩散圆环表示，不需要额外PNG。接入新版贴图时让hover复用当前基础格，避免继续加载旧风格hover图。"],
        ["棋盘数字实现", "用户指定使用生成的1–8图片。本轮陆地格内按82%等比绘制这些数字图，不再回退为Godot动态文字；最终缩放可读性由用户在真实游戏中确认。"],
        ["史莱姆使用", "三张不服气素材全部用于待机随机轮换，嘲笑候选A用于玩家失败，被打倒素材用于玩家胜利；其余两张嘲笑图保留为备用候选。所有状态的最终切换节奏、画布中心和底线由用户在实机确认。"],
        ["机器人使用", "陆地左侧待机使用右前方完整立姿；动作状态使用右前方躯干与独立手臂拆件，实现充能完成提示、胜利挥臂和失败触电。其余视角继续作为后续候选。"],
        ["关卡内容现状", "第1–7关生态健康/污染成对素材及大型胜利展示均已补齐；第5关健康/污染源图尺寸不同，全部状态组仍需统一画布、中心和底线。旧玩法中的断墙、蛛网、苔藓石、污染节点和Boss古树独立机制素材仍未包含。"],
        ["审批边界", "清单只确认文件存在、用途和技术元数据，不代表画风、缩放、透明边缘、布局或商用权已经通过；最终效果仍需用户在真实游戏中确认。"],
    ]
    for row in rows:
        analysis.append(row)
    style_header(analysis, "5B6F3A")
    for row in analysis.iter_rows():
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)

    rules = workbook.create_sheet("编号规则")
    rules.append(["项目", "规则", "说明"])
    rule_rows = [
        ["候选编号", "V2L_####", "本文件夹图片的永久来源编号；删除或淘汰后不复用。"],
        ["正式编号", "ART_####", "只有用户确认并进入assets/art等运行目录后，才映射或分配正式编号。"],
        ["双编号关系", "V2L编号保持不变", "同一图进入运行库后，在“对应正式ART编号”记录映射，不把V2L改写成ART。"],
        ["新增图片", "只追加", "运行 discover；新图从历史max_id继续编号，旧行不重排。"],
        ["移动图片", "保留编号", "唯一SHA-256一致时discover自动识别移动；否则人工更新原行路径。"],
        ["文件名", "不依赖中文文件排序", "同步只使用V2L编号；文件路径和行号均不是永久身份。"],
    ]
    for row in rule_rows:
        rules.append(row)
    style_header(rules, "74643C")
    for index, width in enumerate([20, 34, 86], 1):
        rules.column_dimensions[get_column_letter(index)].width = width
    for row in rules.iter_rows():
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)

    support = workbook.create_sheet("辅助文件")
    support.append(["相对路径", "类型", "用途/处理建议"])
    generated_names = {MANIFEST.name, WORKBOOK.name}
    support_paths = sorted(
        [
            path for path in SOURCE_ROOT.rglob("*")
            if path.is_file() and path.suffix.lower() != ".png" and path.name not in generated_names
        ],
        key=lambda path: path.relative_to(SOURCE_ROOT).as_posix(),
    )
    for path in support_paths:
        relative = path.relative_to(SOURCE_ROOT).as_posix()
        if path.name.startswith("~$"):
            usage = "Excel临时锁文件；关闭对应工作簿后可删除，不属于素材。"
        elif path.suffix.lower() == ".zip":
            usage = "阶段快照压缩包，仅归档。"
        elif path.suffix.lower() == ".xlsx":
            usage = "既有美术目录快照/来源文档，不是本清单主文件。"
        elif path.suffix.lower() == ".md":
            usage = "设计决策、布局、配色或说明文档。"
        else:
            usage = "辅助文件。"
        support.append([relative, path.suffix.removeprefix(".").upper(), usage])
        support.cell(support.max_row, 1).hyperlink = relative
        support.cell(support.max_row, 1).style = "Hyperlink"
    style_header(support, "385D78")
    for index, width in enumerate([75, 14, 80], 1):
        support.column_dimensions[get_column_letter(index)].width = width
    for row in support.iter_rows():
        for cell in row:
            cell.alignment = Alignment(vertical="top", wrap_text=True)
    support.freeze_panes = "A2"
    support.auto_filter.ref = support.dimensions

    guide = workbook.create_sheet("使用说明")
    guide.column_dimensions["A"].width = 115
    instructions = [
        "ver2bygpt 陆地美术候选清单",
        "1. V2L_####是本文件夹图片的永久来源编号，不等同于游戏正式ART_####。",
        "2. 先按“资产层级”筛选：运行候选用于后续实机选择；设计参考和历史输入禁止直接当运行素材。",
        "3. “当前文件”可点击打开图片；“素材名称（中文）”直接说明具体内容，不能只写按钮、角色或背景。",
        "4. 同组多候选不一定只选一张：本轮三张不服气史莱姆均用于待机轮换；其余候选用途以“建议处理”和正式ID映射为准。",
        "5. Excel可编辑名称、分类、状态、建议、正式ID映射、权利和审核字段；修改后执行 python tools/ver2_land_catalog.py import。",
        "6. 添加新PNG后执行 discover；工具只追加编号。移动/改名应保留原编号。",
        "7. 提交前执行 validate。结构通过不代表视觉、布局、透明边缘或商用权通过。",
    ]
    for index, text in enumerate(instructions, 1):
        guide.cell(index, 1, text)
        guide.cell(index, 1).alignment = Alignment(vertical="top", wrap_text=True)
    guide.cell(1, 1).font = Font(size=16, bold=True, color="31583F")

    metadata = workbook.create_sheet("元数据")
    metadata.sheet_state = "hidden"
    metadata.append(["schema", 1])
    metadata.append(["id_format", "V2L_####"])
    metadata.append(["entry_count", len(entries)])
    metadata.append(["max_id", max(int(entry["id"].split("_")[1]) for entry in entries)])

    workbook.save(WORKBOOK)

def initialize() -> None:
    if MANIFEST.exists():
        raise SystemExit(f"Refusing to initialize: {MANIFEST} already exists")
    expected = {item[0] for item in INITIAL_ITEMS}
    current = {path.relative_to(SOURCE_ROOT).as_posix() for path in iter_png_paths()}
    missing = sorted(expected - current)
    extra = sorted(current - expected)
    if missing:
        raise SystemExit(f"Expected images are missing: {missing}")
    if extra:
        raise SystemExit(f"Unclassified images exist before initialization: {extra}")
    entries = [build_entry(index, item) for index, item in enumerate(INITIAL_ITEMS, 1)]
    payload = {"schema": 1, "max_id": len(entries), "entries": entries}
    save_payload(payload)
    export_workbook(entries)
    print(f"Initialized {len(entries)} stable V2L candidate IDs")
    print(f"Workbook: {WORKBOOK}")


def import_workbook() -> None:
    payload = load_payload()
    entries = payload["entries"]
    by_id = {entry["id"]: entry for entry in entries}
    workbook = load_workbook(WORKBOOK)
    if "新素材总表" not in workbook.sheetnames:
        raise SystemExit("Workbook is missing sheet: 新素材总表")
    sheet = workbook["新素材总表"]
    headers = {str(cell.value or "").strip(): index for index, cell in enumerate(sheet[1], 1)}
    required = {"编号", *EDITABLE_FIELDS}
    missing_headers = required - set(headers)
    if missing_headers:
        raise SystemExit(f"Workbook is missing columns: {sorted(missing_headers)}")

    seen: set[str] = set()
    for row in range(2, sheet.max_row + 1):
        asset_id = str(sheet.cell(row, headers["编号"]).value or "").strip()
        if not asset_id:
            continue
        if asset_id in seen:
            raise SystemExit(f"Duplicate ID in workbook: {asset_id}")
        if asset_id not in by_id:
            raise SystemExit(
                f"Unknown ID in workbook: {asset_id}; add new PNGs with discover"
            )
        seen.add(asset_id)
        entry = by_id[asset_id]
        for column, field in EDITABLE_FIELDS.items():
            value = str(sheet.cell(row, headers[column]).value or "").strip()
            entry[field] = value.replace("\\", "/") if field == "path" else value
    missing_ids = set(by_id) - seen
    if missing_ids:
        raise SystemExit(f"Workbook is missing IDs: {sorted(missing_ids)}")

    errors = basic_errors(payload)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
    refresh_entries(entries)
    save_payload(payload)
    export_workbook(entries)
    print(f"Imported {len(entries)} rows and rebuilt JSON/Excel catalog")


def basic_errors(payload: dict[str, Any]) -> list[str]:
    entries = payload.get("entries", [])
    errors: list[str] = []
    ids = [str(entry.get("id", "")) for entry in entries]
    paths = [str(entry.get("path", "")) for entry in entries]
    names = [str(entry.get("short_name", "")) for entry in entries]
    if len(ids) != len(set(ids)):
        errors.append("Duplicate V2L IDs")
    if len(paths) != len(set(paths)):
        errors.append("Duplicate image paths")
    if len(names) != len(set(names)):
        errors.append("Duplicate normalized short names")
    numeric: list[int] = []
    for entry in entries:
        asset_id = str(entry.get("id", ""))
        if not ID_PATTERN.fullmatch(asset_id):
            errors.append(f"Invalid ID: {asset_id}")
        else:
            numeric.append(int(asset_id.split("_")[1]))
        short_name = str(entry.get("short_name", ""))
        if not SHORT_PATTERN.fullmatch(short_name) or len(short_name) > 48:
            errors.append(f"Invalid short name: {asset_id} {short_name!r}")
        if not str(entry.get("asset_name", "")).strip():
            errors.append(f"Missing Chinese asset name: {asset_id}")
        relative = str(entry.get("path", ""))
        if Path(relative).is_absolute() or ".." in Path(relative).parts:
            errors.append(f"Unsafe relative path: {asset_id} {relative}")
        if Path(relative).suffix.lower() != ".png":
            errors.append(f"Catalog entry is not PNG: {asset_id} {relative}")
    if numeric and int(payload.get("max_id", 0)) < max(numeric):
        errors.append("max_id is lower than an assigned ID")
    return errors


def workbook_errors(entries: list[dict[str, Any]]) -> list[str]:
    if not WORKBOOK.exists():
        return ["Workbook is missing"]
    workbook = load_workbook(WORKBOOK, read_only=True, data_only=False)
    if "新素材总表" not in workbook.sheetnames:
        return ["Workbook is missing sheet: 新素材总表"]
    sheet = workbook["新素材总表"]
    headers = {str(cell.value or "").strip(): index for index, cell in enumerate(sheet[1], 1)}
    required = {"编号", *EDITABLE_FIELDS}
    if required - set(headers):
        return [f"Workbook columns are missing: {sorted(required - set(headers))}"]
    rows: dict[str, dict[str, str]] = {}
    errors: list[str] = []
    for row in range(2, sheet.max_row + 1):
        asset_id = str(sheet.cell(row, headers["编号"]).value or "").strip()
        if not asset_id:
            continue
        if asset_id in rows:
            errors.append(f"Duplicate workbook ID: {asset_id}")
            continue
        rows[asset_id] = {
            field: str(sheet.cell(row, headers[column]).value or "").strip().replace("\\", "/")
            if field == "path"
            else str(sheet.cell(row, headers[column]).value or "").strip()
            for column, field in EDITABLE_FIELDS.items()
        }
    expected = {entry["id"]: entry for entry in entries}
    if set(rows) != set(expected):
        errors.append("Workbook ID set differs from manifest")
    for asset_id in sorted(set(rows) & set(expected)):
        for field in EDITABLE_FIELDS.values():
            if rows[asset_id][field] != str(expected[asset_id].get(field, "")):
                errors.append(f"Workbook differs: {asset_id} {field}")
    return errors


def validate() -> None:
    payload = load_payload()
    entries = payload["entries"]
    errors = basic_errors(payload)
    manifest_paths = {entry["path"] for entry in entries}
    current_paths = {path.relative_to(SOURCE_ROOT).as_posix() for path in iter_png_paths()}
    untracked = sorted(current_paths - manifest_paths)
    if untracked:
        errors.append(f"PNG files lack V2L IDs: {untracked}")

    refreshed = json.loads(json.dumps(entries, ensure_ascii=False))
    refresh_entries(refreshed)
    refreshed_by_id = {entry["id"]: entry for entry in refreshed}
    computed = [
        "file_status", "format", "dimensions", "alpha_status", "transparent_percent",
        "safe_boundary", "file_size_kb", "sha256",
    ]
    for entry in entries:
        other = refreshed_by_id[entry["id"]]
        for field in computed:
            if entry.get(field) != other.get(field):
                errors.append(f"Computed metadata is stale: {entry['id']} {field}")
    errors.extend(workbook_errors(entries))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
    tiers: dict[str, int] = {}
    for entry in entries:
        tiers[entry["asset_tier"]] = tiers.get(entry["asset_tier"], 0) + 1
    print(f"Validated {len(entries)} V2L IDs, files, metadata, and workbook: {tiers}")


def export_catalog() -> None:
    payload = load_payload()
    refresh_entries(payload["entries"])
    save_payload(payload)
    export_workbook(payload["entries"])
    print(f"Exported {len(payload['entries'])} rows to {WORKBOOK}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "command", choices=["initialize", "discover", "export", "import", "validate"]
    )
    args = parser.parse_args()
    if args.command == "initialize":
        initialize()
    elif args.command == "discover":
        discover()
    elif args.command == "export":
        export_catalog()
    elif args.command == "import":
        import_workbook()
    else:
        validate()


if __name__ == "__main__":
    main()
