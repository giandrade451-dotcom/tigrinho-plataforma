"""Generate Bedrock RP subpack texture variants (red / blue / gold accents)."""
from __future__ import annotations
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import gen_textures as gt  # noqa: E402

VARIANT_COLORS = {
    "red": ((220, 40, 40, 255), (255, 100, 100, 255)),
    "blue": ((50, 130, 240, 255), (140, 200, 255, 255)),
    "gold": ((230, 180, 30, 255), (255, 220, 80, 255)),
}

SUBPACKS = ROOT / "bedrock" / "resource_pack" / "subpacks"


def variant_sword(tier: str, dark, light):
    img = gt.sword(tier)
    # Recolor the "white" inner highlight pixels to the variant light color
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # White pixels -> variant light
            if (r, g, b) == gt.WHITE[:3]:
                px[x, y] = light
    return img


def variant_scythe(dark, light):
    img = gt.scythe()
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if (r, g, b) == gt.WHITE[:3]:
                px[x, y] = light
    return img


def main():
    for name, (dark, light) in VARIANT_COLORS.items():
        out = SUBPACKS / name / "textures" / "items"
        out.mkdir(parents=True, exist_ok=True)
        for tier in ("wood", "stone", "iron", "gold", "diamond", "netherite"):
            gt.save(variant_sword(tier, dark, light), out / f"{tier}_sword.png")
        gt.save(variant_scythe(dark, light), out / "mace.png")
    # Default subpack — copy the base sword textures verbatim
    out = SUBPACKS / "default" / "textures" / "items"
    out.mkdir(parents=True, exist_ok=True)
    for tier in ("wood", "stone", "iron", "gold", "diamond", "netherite"):
        gt.save(gt.sword(tier), out / f"{tier}_sword.png")
    gt.save(gt.scythe(), out / "mace.png")
    print("Subpacks generated.")


if __name__ == "__main__":
    main()
