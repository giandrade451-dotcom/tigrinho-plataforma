"""
Fex Private — procedural texture generator.

Generates every PNG used by the Bedrock / Java 1.8.9 / Java 1.21.4 resource packs
from a single style: minimalist black + white PvP with a custom "Fex" mark.

Run from repo root:
    python3 fex-private/tools/gen_textures.py
"""
from __future__ import annotations

import math
import os
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BEDROCK_RP = ROOT / "bedrock" / "resource_pack"
BEDROCK_BP = ROOT / "bedrock" / "behavior_pack"
JAVA_1214 = ROOT / "java" / "1_21_4" / "resource_pack" / "assets" / "minecraft"
JAVA_189 = ROOT / "java" / "1_8_9" / "resource_pack" / "assets" / "minecraft"

# Palette ----------------------------------------------------------------------
BLACK = (12, 12, 14, 255)
DARK = (28, 28, 32, 255)
MID = (60, 60, 66, 255)
LIGHT = (200, 200, 205, 255)
WHITE = (245, 245, 248, 255)
SILVER = (170, 175, 180, 255)
ACCENT = (240, 240, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

# Fonts ------------------------------------------------------------------------
JP_FONT_CANDIDATES = [
    "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf",
    "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
]


def _load_font(size: int) -> ImageFont.FreeTypeFont:
    for p in JP_FONT_CANDIDATES:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                continue
    return ImageFont.load_default()


# ------------------------------------------------------------------------------
# Primitive helpers
# ------------------------------------------------------------------------------
def new_canvas(size: int = 16) -> Image.Image:
    return Image.new("RGBA", (size, size), TRANSPARENT)


def save(img: Image.Image, *paths: Path) -> None:
    for p in paths:
        p.parent.mkdir(parents=True, exist_ok=True)
        img.save(p)


def fex_mark(size: int, fg=WHITE, bg=BLACK) -> Image.Image:
    """A unique "Fex" swoosh — stylized lightning slash. Not a Nike swoosh."""
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    d = ImageDraw.Draw(img)
    s = size / 16.0
    # Outer dark glow
    pts_out = [
        (1 * s, 11 * s),
        (6 * s, 4 * s),
        (10 * s, 6 * s),
        (15 * s, 2 * s),
        (15 * s, 5 * s),
        (10 * s, 9 * s),
        (6 * s, 7 * s),
        (3 * s, 13 * s),
    ]
    d.polygon(pts_out, fill=bg)
    pts_in = [
        (2 * s, 11 * s),
        (6 * s, 5 * s),
        (10 * s, 7 * s),
        (14 * s, 3 * s),
        (14 * s, 4 * s),
        (10 * s, 8 * s),
        (6 * s, 6 * s),
        (4 * s, 12 * s),
    ]
    d.polygon(pts_in, fill=fg)
    return img


def gradient_v(size: int, top, bot) -> Image.Image:
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    px = img.load()
    for y in range(size):
        t = y / max(1, size - 1)
        c = tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(4))
        for x in range(size):
            px[x, y] = c
    return img


def noise_overlay(img: Image.Image, alpha: int = 18, seed: int = 7) -> Image.Image:
    import random

    random.seed(seed)
    w, h = img.size
    out = img.copy()
    px = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            n = random.randint(-alpha, alpha)
            r, g, b, a = px[x, y]
            px[x, y] = (
                max(0, min(255, r + n)),
                max(0, min(255, g + n)),
                max(0, min(255, b + n)),
                a,
            )
    return out


# ------------------------------------------------------------------------------
# Items
# ------------------------------------------------------------------------------
def sword(tier: str = "iron") -> Image.Image:
    """Slim 16x16 PvP sword, black blade with white edge.

    The blade is intentionally narrow (1px wide) — "espada menor" — so the
    player's view of the target is barely obstructed during PvP.
    """
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    # Tier tint on the pommel/cross-guard
    pommel = {
        "wood": (110, 70, 35, 255),
        "stone": (120, 120, 124, 255),
        "iron": (210, 210, 215, 255),
        "gold": (230, 200, 70, 255),
        "diamond": (90, 220, 235, 255),
        "netherite": (60, 50, 55, 255),
    }.get(tier, LIGHT)

    # Blade outline (black) — narrow diagonal from bottom-left to top-right
    blade_outline = [
        (3, 12), (4, 11), (5, 10), (6, 9), (7, 8),
        (8, 7), (9, 6), (10, 5), (11, 4), (12, 3),
    ]
    for x, y in blade_outline:
        d.rectangle((x - 1, y, x + 1, y + 1), fill=BLACK)
    # Inner white edge — single pixel highlight
    inner = [
        (4, 11), (5, 10), (6, 9), (7, 8), (8, 7),
        (9, 6), (10, 5), (11, 4),
    ]
    for x, y in inner:
        d.point((x, y), fill=WHITE)
    # Tip
    d.point((12, 3), fill=WHITE)
    d.point((13, 2), fill=BLACK)
    # Cross-guard
    d.rectangle((2, 12, 5, 13), fill=BLACK)
    d.point((3, 12), fill=pommel)
    d.point((4, 12), fill=pommel)
    # Handle (wrapped grip)
    d.rectangle((1, 13, 3, 15), fill=BLACK)
    d.point((2, 14), fill=WHITE)
    # Pommel cap
    d.point((0, 15), fill=pommel)
    d.point((1, 15), fill=BLACK)
    return img


def scythe() -> Image.Image:
    """Black & white scythe — replaces the Mace item.

    Shape: vertical shaft up the right side, curved blade arcing across the top
    and over to the left. White edge, black body.
    """
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    # Shaft (vertical, right side)
    for y in range(3, 15):
        d.point((11, y), fill=BLACK)
        d.point((12, y), fill=DARK)
    d.point((11, 15), fill=BLACK)
    # Grip wrap
    d.rectangle((10, 10, 13, 11), fill=WHITE)
    d.rectangle((10, 13, 13, 14), fill=WHITE)
    # Blade arc — black body
    blade_pts = [
        (11, 2), (10, 2), (9, 2), (8, 2), (7, 2),
        (6, 3), (5, 3), (4, 4), (3, 5), (2, 6),
        (2, 7), (3, 8), (4, 8),
    ]
    for x, y in blade_pts:
        d.point((x, y), fill=BLACK)
    # Sharp inner edge — white
    edge_pts = [
        (11, 3), (10, 3), (9, 3), (8, 3), (7, 3),
        (6, 4), (5, 4), (4, 5), (3, 6), (3, 7),
    ]
    for x, y in edge_pts:
        d.point((x, y), fill=WHITE)
    # Backside of blade (thick outline)
    d.point((1, 7), fill=BLACK)
    d.point((1, 8), fill=BLACK)
    d.point((2, 8), fill=BLACK)
    # Top knob
    d.point((11, 1), fill=WHITE)
    d.point((12, 2), fill=BLACK)
    return img


def bow(pull_stage: int = 0) -> Image.Image:
    """Bow — black limbs, white bowstring. pull_stage: 0=relaxed, 1=mid, 2=full."""
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    if pull_stage == 0:
        # Relaxed
        d.line([(2, 1), (1, 4), (1, 11), (2, 14)], fill=BLACK, width=1)
        d.line([(3, 2), (2, 5), (2, 10), (3, 13)], fill=DARK, width=1)
        # String
        d.line([(3, 1), (3, 14)], fill=WHITE, width=1)
    elif pull_stage == 1:
        # Mid pull
        d.line([(2, 0), (0, 4), (0, 11), (2, 15)], fill=BLACK, width=1)
        d.line([(3, 1), (1, 5), (1, 10), (3, 14)], fill=DARK, width=1)
        # String pulled to middle
        d.line([(3, 1), (7, 7)], fill=WHITE, width=1)
        d.line([(7, 7), (7, 8)], fill=ACCENT, width=1)
        d.line([(7, 8), (3, 14)], fill=WHITE, width=1)
        # Arrow
        for x in range(7, 14):
            d.point((x, 7), fill=BLACK)
        d.point((14, 7), fill=WHITE)
    else:
        # Full pull
        d.line([(2, 0), (-1, 4), (-1, 11), (2, 15)], fill=BLACK, width=1)
        d.line([(3, 1), (0, 5), (0, 10), (3, 14)], fill=DARK, width=1)
        d.line([(3, 1), (9, 7)], fill=WHITE, width=1)
        d.line([(9, 7), (9, 8)], fill=ACCENT, width=1)
        d.line([(9, 8), (3, 14)], fill=WHITE, width=1)
        # Arrow nearly drawn back
        for x in range(9, 15):
            d.point((x, 7), fill=BLACK)
        d.point((15, 7), fill=WHITE)
    return img


def arrow() -> Image.Image:
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    # Shaft
    d.line([(2, 13), (13, 2)], fill=BLACK, width=1)
    d.line([(3, 13), (13, 3)], fill=DARK, width=1)
    # Head
    d.polygon([(11, 2), (14, 2), (14, 5)], fill=WHITE)
    d.polygon([(12, 3), (13, 3), (13, 4)], fill=BLACK)
    # Fletching
    d.line([(0, 15), (4, 11)], fill=WHITE, width=1)
    d.line([(1, 15), (5, 11)], fill=LIGHT, width=1)
    d.point((0, 14), fill=BLACK)
    d.point((2, 15), fill=BLACK)
    return img


def totem_margarine() -> Image.Image:
    """Replaces totem of undying with a stick of margarine."""
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    # Outer wrapper (yellow-gold to evoke butter brand packaging)
    WRAP = (244, 196, 48, 255)
    WRAP_D = (190, 140, 20, 255)
    WRAP_L = (255, 235, 130, 255)
    BUTTER = (255, 232, 130, 255)
    BUTTER_D = (220, 190, 70, 255)
    # Box body
    d.rectangle((2, 3, 13, 14), fill=WRAP)
    d.rectangle((2, 3, 13, 3), fill=WRAP_D)
    d.rectangle((2, 14, 13, 14), fill=WRAP_D)
    d.rectangle((2, 3, 2, 14), fill=WRAP_D)
    d.rectangle((13, 3, 13, 14), fill=WRAP_D)
    # Highlights
    d.rectangle((3, 4, 12, 4), fill=WRAP_L)
    # End caps (folded ends)
    d.rectangle((2, 2, 13, 2), fill=WRAP_D)
    d.rectangle((2, 15, 13, 15), fill=WRAP_D)
    d.point((1, 3), fill=WRAP_D)
    d.point((14, 3), fill=WRAP_D)
    d.point((1, 14), fill=WRAP_D)
    d.point((14, 14), fill=WRAP_D)
    # Label band (white, with "MARGARINE" implied via brand band)
    d.rectangle((3, 7, 12, 11), fill=WHITE)
    d.rectangle((3, 7, 12, 7), fill=LIGHT)
    # Brand letters (3 dots representing logo)
    d.point((5, 9), fill=BLACK)
    d.point((7, 9), fill=BLACK)
    d.point((9, 9), fill=BLACK)
    d.point((11, 9), fill=BLACK)
    # Slogan stripe
    d.line([(3, 11), (12, 11)], fill=WRAP_D)
    # Exposed butter at one corner
    d.rectangle((11, 4, 12, 6), fill=BUTTER)
    d.point((12, 5), fill=BUTTER_D)
    return img


def shield() -> Image.Image:
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    d.rectangle((3, 2, 12, 13), fill=BLACK)
    d.rectangle((4, 3, 11, 12), fill=DARK)
    # Border accent
    d.rectangle((4, 3, 11, 3), fill=WHITE)
    d.rectangle((4, 12, 11, 12), fill=WHITE)
    d.rectangle((4, 3, 4, 12), fill=WHITE)
    d.rectangle((11, 3, 11, 12), fill=WHITE)
    # Center Fex mark
    mark = fex_mark(8, fg=WHITE, bg=BLACK)
    img.alpha_composite(mark, (4, 4))
    # Handle hint
    d.point((7, 14), fill=MID)
    d.point((8, 14), fill=MID)
    return img


# ------------------------------------------------------------------------------
# Armor layer textures
# ------------------------------------------------------------------------------
def armor_layer(layer: int, with_logo: bool = True) -> Image.Image:
    """Generate a 64x32 armor layer texture.

    Layer 1: helmet, chest, boots silhouette.
    Layer 2: leggings silhouette.

    Black plate with white edges and a small Fex mark on the chest.
    """
    img = Image.new("RGBA", (64, 32), TRANSPARENT)
    d = ImageDraw.Draw(img)

    def plate(x: int, y: int, w: int, h: int, edge=WHITE, body=BLACK):
        d.rectangle((x, y, x + w - 1, y + h - 1), fill=body)
        d.rectangle((x, y, x + w - 1, y), fill=edge)
        d.rectangle((x, y + h - 1, x + w - 1, y + h - 1), fill=edge)
        d.rectangle((x, y, x, y + h - 1), fill=edge)
        d.rectangle((x + w - 1, y, x + w - 1, y + h - 1), fill=edge)

    if layer == 1:
        # Helmet UV (top-left of 64x32 atlas: face / top / sides)
        plate(0, 0, 32, 16, edge=WHITE, body=BLACK)
        # Face plate accent
        d.rectangle((9, 8, 22, 13), fill=DARK)
        d.rectangle((9, 8, 22, 8), fill=WHITE)
        # Body (chest)
        plate(16, 16, 24, 16, edge=WHITE, body=BLACK)
        # Arms
        plate(40, 16, 16, 16, edge=WHITE, body=BLACK)
        # Boots (right portion)
        plate(0, 16, 16, 16, edge=WHITE, body=BLACK)
        # Fex mark on chest center
        if with_logo:
            mark = fex_mark(8, fg=WHITE, bg=DARK)
            img.alpha_composite(mark, (24, 20))
            mark2 = fex_mark(6, fg=WHITE, bg=DARK)
            # Small mark on helmet forehead
            img.alpha_composite(mark2, (12, 4))
    else:
        # Leggings layer 2 (64x32)
        # Belt
        plate(16, 16, 24, 8, edge=WHITE, body=BLACK)
        # Legs
        plate(0, 16, 16, 16, edge=WHITE, body=BLACK)
        plate(40, 16, 16, 16, edge=WHITE, body=BLACK)
        # Bottom belt accent
        d.rectangle((17, 18, 39, 19), fill=DARK)
        if with_logo:
            mark = fex_mark(6, fg=WHITE, bg=DARK)
            img.alpha_composite(mark, (28, 18))

    return img


# ------------------------------------------------------------------------------
# Wool blocks ("lans" = blocos de lã) — 1.8.9 PvP style
# ------------------------------------------------------------------------------
WOOL_KANJI = {
    "white": "雪",   # snow
    "orange": "橙",  # orange
    "magenta": "紫", # purple
    "light_blue": "空",  # sky
    "yellow": "陽",  # sun
    "lime": "緑",    # green
    "pink": "桃",    # peach
    "gray": "灰",    # ash
    "light_gray": "銀",  # silver
    "cyan": "海",    # sea
    "purple": "夜",  # night
    "blue": "蒼",    # blue (deep)
    "brown": "土",   # earth
    "green": "森",   # forest
    "red": "血",     # blood
    "black": "影",   # shadow
}


def wool_kanji(color_key: str) -> Image.Image:
    """Black wool with white border + glowing kanji in middle."""
    img = new_canvas(16)
    d = ImageDraw.Draw(img)
    # Background (black with wool texture noise)
    d.rectangle((0, 0, 15, 15), fill=BLACK)
    # White borders
    d.rectangle((0, 0, 15, 0), fill=WHITE)
    d.rectangle((0, 15, 15, 15), fill=WHITE)
    d.rectangle((0, 0, 0, 15), fill=WHITE)
    d.rectangle((15, 0, 15, 15), fill=WHITE)
    # Inner border (subtle gray)
    d.rectangle((1, 1, 14, 1), fill=MID)
    d.rectangle((1, 14, 14, 14), fill=MID)
    d.rectangle((1, 1, 1, 14), fill=MID)
    d.rectangle((14, 1, 14, 14), fill=MID)
    # Add wool noise
    img = noise_overlay(img, alpha=8, seed=hash(color_key) & 0xFFFF)
    # Kanji glyph — rendered larger then downscaled for crisp pixel look
    glyph = WOOL_KANJI.get(color_key, "影")
    big = Image.new("RGBA", (96, 96), TRANSPARENT)
    gd = ImageDraw.Draw(big)
    font = _load_font(72)
    # Glow halo
    halo = Image.new("RGBA", (96, 96), TRANSPARENT)
    hd = ImageDraw.Draw(halo)
    hd.text((48, 48), glyph, font=font, fill=(255, 255, 255, 180), anchor="mm")
    halo = halo.filter(ImageFilter.GaussianBlur(radius=4))
    big.alpha_composite(halo)
    gd.text((48, 48), glyph, font=font, fill=WHITE, anchor="mm")
    glyph_small = big.resize((10, 10), Image.LANCZOS)
    img.alpha_composite(glyph_small, (3, 3))
    # Subtle color tint accent in corners to identify dye color
    tints = {
        "white": (245, 245, 245, 255),
        "orange": (240, 130, 30, 255),
        "magenta": (200, 60, 200, 255),
        "light_blue": (90, 180, 230, 255),
        "yellow": (240, 220, 60, 255),
        "lime": (130, 230, 60, 255),
        "pink": (240, 160, 200, 255),
        "gray": (110, 110, 115, 255),
        "light_gray": (175, 175, 180, 255),
        "cyan": (50, 180, 200, 255),
        "purple": (130, 50, 200, 255),
        "blue": (50, 80, 220, 255),
        "brown": (130, 90, 50, 255),
        "green": (60, 160, 60, 255),
        "red": (210, 50, 50, 255),
        "black": (40, 40, 40, 255),
    }
    tint = tints.get(color_key, WHITE)
    # Tiny corner pip
    d2 = ImageDraw.Draw(img)
    d2.rectangle((1, 1, 2, 2), fill=tint)
    d2.rectangle((13, 1, 14, 2), fill=tint)
    d2.rectangle((1, 13, 2, 14), fill=tint)
    d2.rectangle((13, 13, 14, 14), fill=tint)
    return img


# ------------------------------------------------------------------------------
# Pack icons
# ------------------------------------------------------------------------------
def pack_icon(size: int = 128, label: str = "Fex Private") -> Image.Image:
    img = Image.new("RGBA", (size, size), BLACK)
    d = ImageDraw.Draw(img)
    # Diagonal split
    d.polygon([(0, 0), (size, 0), (0, size)], fill=DARK)
    # Centered Fex mark
    mark = fex_mark(size, fg=WHITE, bg=BLACK)
    img.alpha_composite(mark)
    # Footer text
    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            size // 12,
        )
    except OSError:
        font = ImageFont.load_default()
    d.text((size // 2, size - size // 10), label, font=font, fill=WHITE, anchor="mm")
    return img


# ------------------------------------------------------------------------------
# Master generator
# ------------------------------------------------------------------------------
SWORD_TIERS = ("wood", "stone", "iron", "gold", "diamond", "netherite")


def gen_bedrock() -> None:
    items_dir = BEDROCK_RP / "textures" / "items"
    armor_dir = BEDROCK_RP / "textures" / "models" / "armor"
    entity_dir = BEDROCK_RP / "textures" / "entity"

    # Swords
    name_map = {
        "wood": "wood_sword",
        "stone": "stone_sword",
        "iron": "iron_sword",
        "gold": "gold_sword",
        "diamond": "diamond_sword",
        "netherite": "netherite_sword",
    }
    for tier, fname in name_map.items():
        save(sword(tier), items_dir / f"{fname}.png")
    # Scythe (replaces mace)
    save(scythe(), items_dir / "mace.png")
    # Bow stages
    save(bow(0), items_dir / "bow_standby.png")
    save(bow(1), items_dir / "bow_pulling_0.png")
    save(bow(1), items_dir / "bow_pulling_1.png")
    save(bow(2), items_dir / "bow_pulling_2.png")
    save(arrow(), items_dir / "arrow.png")
    # Totem -> margarine
    save(totem_margarine(), items_dir / "totem.png")
    # Shield
    save(shield(), items_dir / "shield.png")

    # Armor layers — Bedrock uses one file per armor set per layer
    for tier in ("leather", "chain", "iron", "gold", "diamond", "netherite"):
        save(armor_layer(1), armor_dir / f"{tier}_1.png")
        save(armor_layer(2), armor_dir / f"{tier}_2.png")

    # Pack icon
    save(pack_icon(128), BEDROCK_RP / "pack_icon.png", BEDROCK_BP / "pack_icon.png")


def gen_java_modern() -> None:
    """Java 1.21.4 resource pack — modern asset layout."""
    items_dir = JAVA_1214 / "textures" / "item"
    armor_dir = JAVA_1214 / "textures" / "entity" / "equipment" / "humanoid"
    armor_dir_legacy = JAVA_1214 / "textures" / "models" / "armor"

    for tier in SWORD_TIERS:
        n = "wooden_sword" if tier == "wood" else f"{tier}en_sword" if tier == "gold" else f"{tier}_sword"
        # naming: wooden_sword, stone_sword, iron_sword, golden_sword, diamond_sword, netherite_sword
        nm = {
            "wood": "wooden_sword",
            "stone": "stone_sword",
            "iron": "iron_sword",
            "gold": "golden_sword",
            "diamond": "diamond_sword",
            "netherite": "netherite_sword",
        }[tier]
        save(sword(tier), items_dir / f"{nm}.png")
    save(scythe(), items_dir / "mace.png")
    save(bow(0), items_dir / "bow.png")
    save(bow(1), items_dir / "bow_pulling_0.png")
    save(bow(1), items_dir / "bow_pulling_1.png")
    save(bow(2), items_dir / "bow_pulling_2.png")
    save(arrow(), items_dir / "arrow.png")
    save(totem_margarine(), items_dir / "totem_of_undying.png")
    save(shield(), items_dir / "shield.png")

    # Armor — 1.21.4 uses both new equipment textures and legacy 64x32 layers
    for tier in ("leather", "chainmail", "iron", "golden", "diamond", "netherite"):
        save(armor_layer(1), armor_dir_legacy / f"{tier}_layer_1.png")
        save(armor_layer(2), armor_dir_legacy / f"{tier}_layer_2.png")

    # Pack icon
    save(pack_icon(128), JAVA_1214.parent.parent / "pack.png")


def gen_java_189() -> None:
    items_dir = JAVA_189 / "textures" / "items"
    armor_dir = JAVA_189 / "textures" / "models" / "armor"
    blocks_dir = JAVA_189 / "textures" / "blocks"

    for tier in SWORD_TIERS:
        nm = {
            "wood": "wood_sword",
            "stone": "stone_sword",
            "iron": "iron_sword",
            "gold": "gold_sword",
            "diamond": "diamond_sword",
            "netherite": "diamond_sword",  # 1.8.9 has no netherite, fallback
        }[tier]
        if tier == "netherite":
            continue
        save(sword(tier), items_dir / f"{nm}.png")
    save(bow(0), items_dir / "bow_standby.png")
    save(bow(1), items_dir / "bow_pulling_0.png")
    save(bow(1), items_dir / "bow_pulling_1.png")
    save(bow(2), items_dir / "bow_pulling_2.png")
    save(arrow(), items_dir / "arrow.png")
    save(totem_margarine(), items_dir / "totem.png")
    save(shield(), items_dir / "shield.png")

    # Armor
    for tier in ("leather", "chainmail", "iron", "gold", "diamond"):
        save(armor_layer(1), armor_dir / f"{tier}_layer_1.png")
        save(armor_layer(2), armor_dir / f"{tier}_layer_2.png")

    # Wool blocks ("lans") with kanji — 1.8.9 PvP signature
    for color in WOOL_KANJI:
        save(wool_kanji(color), blocks_dir / f"wool_colored_{color}.png")

    # Pack icon
    save(pack_icon(128), JAVA_189.parent.parent / "pack.png")


# Also output wool kanji to 1.21.4 (modern names) and Bedrock
def gen_wool_modern() -> None:
    items_dir = JAVA_1214 / "textures" / "block"
    for color in WOOL_KANJI:
        save(wool_kanji(color), items_dir / f"{color}_wool.png")
    blocks_dir = BEDROCK_RP / "textures" / "blocks"
    for color in WOOL_KANJI:
        save(wool_kanji(color), blocks_dir / f"wool_colored_{color}.png")


def main() -> None:
    gen_bedrock()
    gen_java_modern()
    gen_java_189()
    gen_wool_modern()
    print("Texture generation complete.")
    # Quick sanity count
    counts = {
        "bedrock items": len(list((BEDROCK_RP / "textures" / "items").glob("*.png"))),
        "bedrock armor": len(
            list((BEDROCK_RP / "textures" / "models" / "armor").glob("*.png"))
        ),
        "java 1.21.4 items": len(list((JAVA_1214 / "textures" / "item").glob("*.png"))),
        "java 1.8.9 items": len(list((JAVA_189 / "textures" / "items").glob("*.png"))),
        "java 1.8.9 blocks": len(list((JAVA_189 / "textures" / "blocks").glob("*.png"))),
    }
    for k, v in counts.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
