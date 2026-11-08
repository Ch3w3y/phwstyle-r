"""Build inst/css/phw-fonts-embedded.css: the Ubuntu fonts subset to Latin
and Welsh characters, converted to WOFF2 and embedded as data URIs, so Quarto
HTML, slides and dashboards show Ubuntu from any folder and offline.

Subsetting and format conversion make a "Modified Version" under the Ubuntu
Font Licence 1.0 (section 2c), so the subset fonts are renamed
"Ubuntu derivative phwstyle". CSS font stacks list "Ubuntu" first (an
installed copy) and then this derivative.

Run from the package root:  python3 data-raw/build-web-fonts.py
Needs: pip install fonttools brotli
"""
import base64
import io

from fontTools import subset
from fontTools.ttLib import TTFont

FAMILY = "Ubuntu derivative phwstyle"
UNICODES = (list(range(0x20, 0x7F)) + list(range(0xA0, 0x250)) +
            list(range(0x1E80, 0x1E86)) + list(range(0x1EF2, 0x1EF4)) +   # Welsh w/y accents
            list(range(0x2000, 0x2070)) +
            [0x20AC, 0x2122, 0x2212, 0x2264, 0x2265, 0x2190, 0x2191, 0x2192, 0x2193, 0x2022])

rows = []
for style, weight, css_style in [("Regular", 400, "normal"), ("Italic", 400, "italic"),
                                 ("Medium", 500, "normal"), ("Bold", 700, "normal"),
                                 ("BoldItalic", 700, "italic"), ("Light", 300, "normal")]:
    font = TTFont(f"inst/fonts/Ubuntu-{style}.ttf")
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=UNICODES)
    sub.subset(font)
    name = font["name"]
    sub_family = {"Regular": "Regular", "Italic": "Italic", "Medium": "Medium", "Bold": "Bold",
                  "BoldItalic": "Bold Italic", "Light": "Light"}[style]
    for rec in name.names:
        if rec.nameID in (1, 16):
            rec.string = FAMILY
        elif rec.nameID == 4:
            rec.string = f"{FAMILY} {sub_family}"
        elif rec.nameID == 6:
            rec.string = f"UbuntuDerivativePhwstyle-{style}"
        elif rec.nameID == 3:
            rec.string = f"{FAMILY} {sub_family}; subset for phwstyle"
    font.flavor = "woff2"
    buf = io.BytesIO()
    font.save(buf)
    data = base64.b64encode(buf.getvalue()).decode()
    rows.append(f'@font-face {{ font-family: "{FAMILY}"; font-style: {css_style}; '
                f'font-weight: {weight}; font-display: swap; '
                f'src: local("Ubuntu {sub_family}"), url(data:font/woff2;base64,{data}) format("woff2"); }}')

with open("inst/css/phw-fonts-embedded.css", "w") as f:
    f.write("/* Ubuntu derivative phwstyle: Ubuntu (c) Canonical Ltd, Ubuntu Font Licence 1.0.\n"
            "   Subset to Latin and Welsh and converted to WOFF2 by phwstyle. */\n")
    f.write("\n".join(rows) + "\n")
print("done")
