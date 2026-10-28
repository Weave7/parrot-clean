#!/usr/bin/env python3
"""
Dynamic template renderer for Parrot-Clean theme switcher.
Stdlib only (Python 3.11+ tomllib with fallback parser).
"""

import sys
import re
from pathlib import Path

try:
    import tomllib
except ImportError:
    tomllib = None

def parse_toml(filepath):
    if tomllib:
        try:
            with open(filepath, "rb") as f:
                data = tomllib.load(f)
                return {k: str(v) for k, v in data.items() if not isinstance(v, (dict, list))}
        except Exception:
            pass

    # Simple line-by-line fallback
    colors = {}
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                k = k.strip().replace('"', '').replace("'", "")
                v = v.split("#")[0].strip().replace('"', '').replace("'", "")
                if k and v:
                    colors[k] = v
    return colors

def mix(c1, c2, pct):
    c1 = c1.lstrip("#")
    c2 = c2.lstrip("#")
    if len(c1) < 6 or len(c2) < 6:
        return f"#{c1}"
    try:
        r1, g1, b1 = int(c1[0:2], 16), int(c1[2:4], 16), int(c1[4:6], 16)
        r2, g2, b2 = int(c2[0:2], 16), int(c2[2:4], 16), int(c2[4:6], 16)
        amount = float(pct.rstrip("%")) / 100.0 if "%" in pct else float(pct)
        if amount > 1.0:
            amount /= 100.0
        amount = max(0.0, min(1.0, amount))
        r = int(r1 * (1 - amount) + r2 * amount + 0.5)
        g = int(g1 * (1 - amount) + g2 * amount + 0.5)
        b = int(b1 * (1 - amount) + b2 * amount + 0.5)
        return f"#{r:02x}{g:02x}{b:02x}"
    except Exception:
        return f"#{c1}"

def resolve_palette(colors):
    # Aliases
    bg = colors.get("background", colors.get("bg", colors.get("color0", "#060606")))
    fg = colors.get("foreground", colors.get("fg", colors.get("color7", "#ededed")))

    # Mode detection
    mode = colors.get("mode", colors.get("theme_type", ""))
    if not mode:
        if bg.startswith("#") and len(bg) >= 7:
            lum = int(bg[1:3], 16) + int(bg[3:5], 16) + int(bg[5:7], 16)
            mode = "light" if lum > 382 else "dark"
        else:
            mode = "dark"

    palette = dict(colors)
    palette["mode"] = mode
    palette["background"] = bg
    palette["foreground"] = fg

    accent = palette.get("accent", palette.get("blue", palette.get("color4", "#7aa2f7")))
    palette["accent"] = accent

    palette.setdefault("dark_background", mix(bg, "#000000", "25%"))
    palette.setdefault("darker_background", mix(bg, "#000000", "50%"))
    palette.setdefault("lighter_background", mix(bg, "#ffffff", "10%"))

    palette.setdefault("bright_foreground", palette.get("color15", fg))
    palette.setdefault("dark_foreground", palette.get("color8", mix(fg, bg, "50%")))
    palette.setdefault("light_foreground", fg)
    palette.setdefault("muted", palette.get("dark_foreground"))

    palette.setdefault("cursor", palette["bright_foreground"])
    palette.setdefault("selection", palette.get("selection_background", mix(bg, fg, "20%")))
    palette.setdefault("selection_foreground", palette["bright_foreground"])
    palette.setdefault("hairline", mix(bg, fg, "15%"))

    # ANSI accents
    palette.setdefault("red", palette.get("color1", "#f7768e"))
    palette.setdefault("green", palette.get("color2", "#9ece6a"))
    palette.setdefault("yellow", palette.get("color3", "#e0af68"))
    palette.setdefault("blue", palette.get("color4", "#7aa2f7"))
    palette.setdefault("magenta", palette.get("color5", palette.get("purple", "#ad8ee6")))
    palette.setdefault("cyan", palette.get("color6", "#449dab"))
    palette.setdefault("orange", palette.get("yellow"))
    palette.setdefault("brown", mix(palette["orange"], "#000000", "50%"))

    palette.setdefault("bright_red", palette.get("color9", mix(palette["red"], "#ffffff", "20%")))
    palette.setdefault("bright_green", palette.get("color10", mix(palette["green"], "#ffffff", "20%")))
    palette.setdefault("bright_yellow", palette.get("color11", mix(palette["yellow"], "#ffffff", "20%")))
    palette.setdefault("bright_blue", palette.get("color12", mix(palette["blue"], "#ffffff", "20%")))
    palette.setdefault("bright_magenta", palette.get("color13", mix(palette["magenta"], "#ffffff", "20%")))
    palette.setdefault("bright_cyan", palette.get("color14", mix(palette["cyan"], "#ffffff", "20%")))

    return palette

def render(colors_file, template_file):
    raw_colors = parse_toml(colors_file)
    colors = resolve_palette(raw_colors)

    with open(template_file, "r", encoding="utf-8") as f:
        content = f.read()

    def mix_replacer(match):
        c1_name = match.group(1).strip()
        c2_name = match.group(2).strip()
        pct = match.group(3).strip()
        c1 = colors.get(c1_name, c1_name)
        c2 = colors.get(c2_name, c2_name)
        return mix(c1, c2, pct)

    content = re.sub(r'\{\{\s*mix\s+([A-Za-z0-9_#]+)\s+([A-Za-z0-9_#]+)\s+([0-9.]+%?)\s*\}\}', mix_replacer, content)

    for k, v in colors.items():
        content = re.sub(r'\{\{\s*' + re.escape(k) + r'\s*\}\}', str(v), content)

    return content

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: render_template.py <colors.toml> <template_file>", file=sys.stderr)
        sys.exit(1)
    output = render(sys.argv[1], sys.argv[2])
    sys.stdout.write(output)
