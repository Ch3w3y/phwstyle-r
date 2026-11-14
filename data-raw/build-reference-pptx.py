"""Build the PHW PowerPoint template used by phw_pptx() and the Quarto pptx
format.

In R terms: this is a one-off script like the ones in data-raw/ that build
package data. Run it from the package root with
    python3 data-raw/build-reference-pptx.py
It needs the python-pptx library (pip install python-pptx), which is the
Python equivalent of officer.

Everything the slides inherit lives here: the 16:9 size, the theme colours
and fonts, the master text styles and a small set of layouts. The font is
named, not embedded, so PowerPoint uses Ubuntu where it is installed and
falls back to its default elsewhere.
"""
from pathlib import Path

from lxml import etree
from pptx import Presentation
from pptx.oxml import parse_xml
from pptx.dml.color import RGBColor
from pptx.util import Emu, Inches, Pt

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "inst" / "rmarkdown" / "resources" / "phw-reference.pptx"

NAVY = "285087"
NAVY_DARK = "1B3660"
TEXT = "212B32"
GREY = "4C6272"
FONT = "Ubuntu"
THEME_NAME = "PHW"
KEEP = ["Title Slide", "Title and Content", "Section Header", "Two Content", "Title Only", "Blank"]

A = "http://schemas.openxmlformats.org/drawingml/2006/main"
P = "http://schemas.openxmlformats.org/presentationml/2006/main"
NS = {"a": A, "p": P}

W, H = Inches(13.333), Inches(7.5)
MARGIN = Inches(0.6)
CONTENT_W = W - 2 * MARGIN

prs = Presentation()
prs.slide_width, prs.slide_height = W, H

for layout in list(prs.slide_layouts):
    if layout.name not in KEEP:
        prs.slide_layouts.remove(layout)

master = prs.slide_master

# Theme: name, colours and fonts.
theme_part = next(r.target_part for r in master.part.rels.values() if r.reltype.endswith("/theme"))
theme = etree.fromstring(theme_part.blob)
theme.set("name", THEME_NAME)
colours = {
    "dk1": TEXT, "lt1": "FFFFFF", "dk2": NAVY, "lt2": "F0F4F5",
    "accent1": NAVY, "accent2": "24A2B5", "accent3": "CFAB7A", "accent4": "FF5D0C",
    "accent5": "338276", "accent6": "846AA4", "hlink": "2D78A0", "folHlink": "846AA4",
}
scheme = theme.find(".//a:clrScheme", NS)
scheme.set("name", THEME_NAME)
for tag, value in colours.items():
    el = scheme.find(f"a:{tag}", NS)
    for child in list(el):
        el.remove(child)
    etree.SubElement(el, f"{{{A}}}srgbClr").set("val", value)
fonts = theme.find(".//a:fontScheme", NS)
fonts.set("name", THEME_NAME)
for group in ("majorFont", "minorFont"):
    g = fonts.find(f"a:{group}", NS)
    g.find("a:latin", NS).set("typeface", FONT)
    for script in g.findall("a:font", NS):
        g.remove(script)
theme_part._blob = etree.tostring(theme, xml_declaration=True, encoding="UTF-8", standalone=True)


def place(shape, left, top, width, height):
    shape.left, shape.top, shape.width, shape.height = Emu(left), Emu(top), Emu(width), Emu(height)


def style_levels(tx_body_style, sizes, colour, bold_first=False):
    """Set font, size and colour on each outline level of a master text style."""
    for i, size in enumerate(sizes, start=1):
        lvl = tx_body_style.find(f"a:lvl{i}pPr", NS)
        if lvl is None:
            continue
        rpr = lvl.find("a:defRPr", NS)
        rpr.set("sz", str(int(size * 100)))
        rpr.set("b", "1" if bold_first and i == 1 else "0")
        for child in list(rpr):
            rpr.remove(child)
        fill = etree.SubElement(rpr, f"{{{A}}}solidFill")
        etree.SubElement(fill, f"{{{A}}}srgbClr").set("val", colour)
        for tag, face in (("latin", "+mj-lt" if bold_first else "+mn-lt"), ("ea", "+mn-ea"), ("cs", "+mn-cs")):
            etree.SubElement(rpr, f"{{{A}}}{tag}").set("typeface", face)


tx = master._element.find("p:txStyles", NS)
style_levels(tx.find("p:titleStyle", NS), [30], NAVY, bold_first=True)
style_levels(tx.find("p:bodyStyle", NS), [22, 20, 18, 16, 16, 16, 16, 16, 16], TEXT)
tx.find("p:titleStyle/a:lvl1pPr", NS).set("algn", "l")

# Master: navy bar across the top, placeholders sized for 16:9.
bar = parse_xml(
    f'<p:sp xmlns:p="{P}" xmlns:a="{A}"><p:nvSpPr><p:cNvPr id="90" name="PHW bar"/><p:cNvSpPr/><p:nvPr userDrawn="1"/></p:nvSpPr>'
    f'<p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{int(W)}" cy="{int(Inches(0.14))}"/></a:xfrm>'
    f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="{NAVY}"/></a:solidFill><a:ln><a:noFill/></a:ln></p:spPr>'
    f'<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-GB"/></a:p></p:txBody></p:sp>')
master.shapes._spTree.insert(2, bar)

geometry = {
    "title": (MARGIN, Inches(0.4), CONTENT_W, Inches(1.0)),
    "body": (MARGIN, Inches(1.65), CONTENT_W, Inches(4.9)),
    "dt": (MARGIN, Inches(6.95), Inches(2.5), Inches(0.35)),
    "ftr": (Inches(4.2), Inches(6.95), Inches(4.9), Inches(0.35)),
    "sldNum": (W - MARGIN - Inches(2.5), Inches(6.95), Inches(2.5), Inches(0.35)),
}
for ph in master.placeholders:
    kind = ph.placeholder_format.type
    key = {1: "title", 2: "body", 16: "dt", 15: "ftr", 13: "sldNum"}.get(int(kind))
    if key:
        place(ph, *geometry[key])
        if key in ("dt", "ftr", "sldNum"):
            for para in ph.text_frame.paragraphs:
                para.font.size = Pt(10)
                para.font.color.rgb = RGBColor.from_string(GREY)
        if key == "title":
            ph.text_frame.vertical_anchor = 3  # middle

layouts = {l.name: l for l in prs.slide_layouts}


def clear_geometry(layout):
    """Let layout placeholders inherit from the master unless set below."""
    for ph in layout.placeholders:
        sp_pr = ph._element.spPr
        for child in list(sp_pr):
            sp_pr.remove(child)


for layout in layouts.values():
    clear_geometry(layout)

half = (CONTENT_W - Inches(0.4)) // 2
for ph in layouts["Two Content"].placeholders:
    idx = ph.placeholder_format.idx
    if idx == 1:
        place(ph, MARGIN, Inches(1.65), half, Inches(4.9))
    elif idx == 2:
        place(ph, MARGIN + half + Inches(0.4), Inches(1.65), half, Inches(4.9))

# Title slide and section header: navy background, white title.
for name in ("Title Slide", "Section Header"):
    layout = layouts[name]
    bg = layout.background.fill
    bg.solid()
    bg.fore_color.rgb = RGBColor.from_string(NAVY)
    for ph in layout.placeholders:
        kind = int(ph.placeholder_format.type)
        if kind in (1, 3):
            place(ph, MARGIN, Inches(2.3), CONTENT_W, Inches(1.6))
            ph.text_frame.vertical_anchor = 4  # bottom
            lst = ph._element.find(".//a:lstStyle", NS)
            for child in list(lst):
                lst.remove(child)
            lvl = etree.SubElement(lst, f"{{{A}}}lvl1pPr")
            lvl.set("algn", "l")
            rpr = etree.SubElement(lvl, f"{{{A}}}defRPr")
            rpr.set("sz", "4000")
            rpr.set("b", "1")
            fill = etree.SubElement(rpr, f"{{{A}}}solidFill")
            etree.SubElement(fill, f"{{{A}}}srgbClr").set("val", "FFFFFF")
        elif kind in (4, 2):
            place(ph, MARGIN, Inches(4.1), CONTENT_W, Inches(1.2))
            lst = ph._element.find(".//a:lstStyle", NS)
            for child in list(lst):
                lst.remove(child)
            lvl = etree.SubElement(lst, f"{{{A}}}lvl1pPr")
            lvl.set("marL", "0")
            lvl.set("indent", "0")
            lvl.set("algn", "l")
            etree.SubElement(lvl, f"{{{A}}}buNone")
            rpr = etree.SubElement(lvl, f"{{{A}}}defRPr")
            rpr.set("sz", "2200")
            fill = etree.SubElement(rpr, f"{{{A}}}solidFill")
            etree.SubElement(fill, f"{{{A}}}srgbClr").set("val", "F0F4F5")
    # The master's top bar disappears into the navy background.
    layout._element.set("showMasterSp", "0")

OUT.parent.mkdir(parents=True, exist_ok=True)
prs.save(str(OUT))
print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")
