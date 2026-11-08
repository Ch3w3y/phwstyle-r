"""Build the PHW Word reference document used by phw_word_document() and the
Quarto docx format.

In R terms: this is a one-off script like the ones in data-raw/ that build
package data. Run it from the package root with
    python3 data-raw/build-reference-docx.py
It needs pandoc on the PATH and the python-docx library
(pip install python-docx), which is the Python equivalent of officer.

Pandoc copies the styles, header and footer from the reference document
into every Word file it writes, so all the branding lives here.
"""
import copy
import subprocess
from pathlib import Path

from docx import Document
from docx.enum.text import WD_TAB_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "inst" / "rmarkdown" / "resources" / "phw-reference.docx"
BAND = ROOT / "inst" / "graphics" / "band.png"  # the logo is added at run time

NAVY = "285087"
TEXT = "212B32"
GREY = "4C6272"
BORDER = "D8DDE0"
FONT = "Ubuntu"

# 1. Start from pandoc's own reference.docx so every style pandoc uses exists.
#    (subprocess.run is Python's system2().)
OUT.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(["pandoc", "-o", str(OUT), "--print-default-data-file", "reference.docx"], check=True)
doc = Document(str(OUT))


def hex_rgb(h):
    return RGBColor.from_string(h)


def set_font(style, size=None, bold=None, colour=None, italic=None):
    f = style.font
    f.name = FONT
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rfonts.set(qn(attr), FONT)
    for attr in ("w:asciiTheme", "w:hAnsiTheme", "w:cstheme", "w:eastAsiaTheme"):
        if rfonts.get(qn(attr)) is not None:
            del rfonts.attrib[qn(attr)]
    if size is not None:
        f.size = Pt(size)
    if bold is not None:
        f.bold = bold
    if italic is not None:
        f.italic = italic
    if colour is not None:
        f.color.rgb = hex_rgb(colour)


def para(style, before=None, after=None, line=None, keep_next=None):
    pf = style.paragraph_format
    if before is not None:
        pf.space_before = Pt(before)
    if after is not None:
        pf.space_after = Pt(after)
    if line is not None:
        pf.line_spacing = line
    if keep_next is not None:
        pf.keep_with_next = keep_next


styles = doc.styles


def get(name):
    try:
        return {st.name: st for st in styles}.get(name) or styles[name]
    except KeyError:
        return None


# Document defaults (docDefaults) so unstyled runs use Ubuntu too.
rpr_default = doc.styles.element.find(qn("w:docDefaults")).find(qn("w:rPrDefault")).find(qn("w:rPr"))
rf = rpr_default.find(qn("w:rFonts"))
if rf is None:
    rf = OxmlElement("w:rFonts")
    rpr_default.insert(0, rf)
for k in list(rf.attrib):
    del rf.attrib[k]
for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
    rf.set(qn(attr), FONT)

for name in ["Normal", "Body Text", "First Paragraph", "Compact"]:
    s = get(name)
    if s is not None:
        set_font(s, size=11, colour=TEXT)
        para(s, before=0, after=6, line=1.15)

for name, size, colour, before, after in [
    ("Heading 1", 16, NAVY, 18, 6),
    ("Heading 2", 13, NAVY, 14, 4),
    ("Heading 3", 11.5, NAVY, 12, 3),
    ("Heading 4", 11, GREY, 10, 2),
    ("Heading 5", 11, GREY, 8, 2),
    ("Heading 6", 11, GREY, 8, 2),
]:
    s = get(name)
    if s is not None:
        set_font(s, size=size, bold=True, colour=colour, italic=False)
        para(s, before=before, after=after, keep_next=True)

for name, size, bold, colour, before, after in [
    ("Title", 28, True, NAVY, 24, 6),
    ("Subtitle", 15, False, GREY, 0, 12),
    ("Author", 11, False, TEXT, 0, 2),
    ("Date", 11, False, GREY, 0, 18),
    ("Abstract", 11, False, TEXT, 6, 12),
]:
    s = get(name)
    if s is not None:
        set_font(s, size=size, bold=bold, colour=colour, italic=False)
        para(s, before=before, after=after)
        s.paragraph_format.alignment = 0  # left, like PHW covers

for name in ["Table Caption", "Image Caption", "Caption"]:
    s = get(name)
    if s is not None:
        set_font(s, size=10, bold=True, colour=NAVY, italic=False)
        para(s, before=6, after=4, keep_next=(name == "Table Caption"))

for name in ["Footnote Text"]:
    s = get(name)
    if s is not None:
        set_font(s, size=9, colour=GREY)

s = get("Block Text")
if s is not None:
    set_font(s, size=11, colour=TEXT, italic=False)
    ppr = s.element.get_or_add_pPr()
    pbdr = OxmlElement("w:pBdr")
    left = OxmlElement("w:left")
    for k, v in {"w:val": "single", "w:sz": "24", "w:space": "8", "w:color": NAVY}.items():
        left.set(qn(k), v)
    pbdr.append(left)
    ppr.append(pbdr)
    shd = OxmlElement("w:shd")
    for k, v in {"w:val": "clear", "w:color": "auto", "w:fill": "F0F4F5"}.items():
        shd.set(qn(k), v)
    ppr.append(shd)

s = get("Hyperlink")
if s is not None:
    s.font.color.rgb = hex_rgb("2D78A0")

for name in ["Source Code", "Verbatim Char"]:
    s = get(name)
    if s is not None:
        s.font.size = Pt(9.5)

# TOC heading
s = get("TOC Heading")
if s is not None:
    set_font(s, size=16, bold=True, colour=NAVY)


# Table style used by pandoc ("Table"): booktabs-like navy rules.
def border(tag, val="single", sz="12", color=NAVY):
    el = OxmlElement(tag)
    el.set(qn("w:val"), val)
    el.set(qn("w:sz"), sz)
    el.set(qn("w:space"), "0")
    el.set(qn("w:color"), color)
    return el


tbl = get("Table")
if tbl is not None:
    el = tbl.element
    tblpr = el.find(qn("w:tblPr"))
    if tblpr is None:
        tblpr = OxmlElement("w:tblPr")
        el.append(tblpr)
    for old in tblpr.findall(qn("w:tblBorders")):
        tblpr.remove(old)
    b = OxmlElement("w:tblBorders")
    b.append(border("w:top"))
    b.append(border("w:bottom"))
    b.append(border("w:insideH", sz="4", color=BORDER))
    tblpr.append(b)
    mar = OxmlElement("w:tblCellMar")
    for side, w in (("w:left", "100"), ("w:right", "100"), ("w:top", "40"), ("w:bottom", "40")):
        m = OxmlElement(side)
        m.set(qn("w:w"), w)
        m.set(qn("w:type"), "dxa")
        mar.append(m)
    tblpr.append(mar)
    rpr = el.find(qn("w:rPr"))
    if rpr is None:
        rpr = OxmlElement("w:rPr")
        el.append(rpr)
    sz = OxmlElement("w:sz")
    sz.set(qn("w:val"), "20")
    rpr.append(sz)
    for old in el.findall(qn("w:tblStylePr")):
        if old.get(qn("w:type")) == "firstRow":
            el.remove(old)
    fr = OxmlElement("w:tblStylePr")
    fr.set(qn("w:type"), "firstRow")
    frp = OxmlElement("w:rPr")
    frp.append(OxmlElement("w:b"))
    c = OxmlElement("w:color")
    c.set(qn("w:val"), NAVY)
    frp.append(c)
    fr.append(frp)
    tcpr = OxmlElement("w:tcPr")
    tcb = OxmlElement("w:tcBorders")
    tcb.append(border("w:top"))
    tcb.append(border("w:bottom"))
    tcpr.append(tcb)
    fr.append(tcpr)
    el.append(fr)

# Pandoc's styles tie colours to the Office theme (w:themeColor), which
# overrides the explicit hex value. Strip those so our colours win.
for c in doc.styles.element.iter(qn("w:color")):
    for attr in ("w:themeColor", "w:themeShade", "w:themeTint"):
        if c.get(qn(attr)) is not None:
            del c.attrib[qn(attr)]

# 2. Page setup: A4, 2 cm margins, room for the header band.
for section in doc.sections:
    section.page_width = Cm(21)
    section.page_height = Cm(29.7)
    section.left_margin = section.right_margin = Cm(2)
    section.top_margin = Cm(3.2)
    section.bottom_margin = Cm(2.2)
    section.header_distance = Cm(0)
    section.footer_distance = Cm(1)

    # Header: full-width gradient band with the white logo, anchored to the
    # top-left corner of the page and placed behind the text.
    header = section.header
    header.is_linked_to_previous = False
    hp = header.paragraphs[0]
    run = hp.add_run()
    run.add_picture(str(BAND), width=Cm(21))
    inline = run._r.find(".//" + qn("wp:inline"))
    anchor_xml = inline.xml.replace("<wp:inline", "<wp:anchor").replace("</wp:inline>", "</wp:anchor>")
    from docx.oxml import parse_xml
    anchor = parse_xml(anchor_xml)
    for k, v in {"behindDoc": "1", "distT": "0", "distB": "0", "distL": "0", "distR": "0",
                 "simplePos": "0", "relativeHeight": "0", "locked": "1",
                 "layoutInCell": "1", "allowOverlap": "1"}.items():
        anchor.set(k, v)
    ns_wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    simple = OxmlElement("wp:simplePos")
    simple.set("x", "0")
    simple.set("y", "0")
    posh = parse_xml(f'<wp:positionH xmlns:wp="{ns_wp}" relativeFrom="page"><wp:posOffset>0</wp:posOffset></wp:positionH>')
    posv = parse_xml(f'<wp:positionV xmlns:wp="{ns_wp}" relativeFrom="page"><wp:posOffset>0</wp:posOffset></wp:positionV>')
    wrap = parse_xml(f'<wp:wrapNone xmlns:wp="{ns_wp}"/>')
    extent = anchor.find(qn("wp:extent"))
    idx = list(anchor).index(extent)
    anchor.insert(idx, posv)
    anchor.insert(idx, posh)
    anchor.insert(idx, simple)
    effect = anchor.find(qn("wp:effectExtent"))
    insert_at = list(anchor).index(effect) + 1 if effect is not None else list(anchor).index(extent) + 1
    anchor.insert(insert_at, wrap)
    inline.getparent().replace(inline, anchor)

    # Footer: organisation on the left, "Page X of Y" on the right, in navy.
    footer = section.footer
    footer.is_linked_to_previous = False
    fp = footer.paragraphs[0]
    fp.paragraph_format.tab_stops.add_tab_stop(Cm(17), WD_TAB_ALIGNMENT.RIGHT)
    pbdr = OxmlElement("w:pBdr")
    pbdr.append(border("w:top", sz="8"))
    fp._p.get_or_add_pPr().append(pbdr)

    def add_text(p, text, bold=False):
        r = p.add_run(text)
        r.font.name = FONT
        r.font.size = Pt(9)
        r.font.bold = bold
        r.font.color.rgb = hex_rgb(NAVY)
        return r

    def add_field(p, instr, bold=True):
        for kind, txt in (("begin", None), ("instr", instr), ("separate", None), ("text", "1"), ("end", None)):
            r = p.add_run()
            r.font.name = FONT
            r.font.size = Pt(9)
            r.font.bold = bold
            r.font.color.rgb = hex_rgb(NAVY)
            if kind == "instr":
                it = OxmlElement("w:instrText")
                it.set(qn("xml:space"), "preserve")
                it.text = f" {instr} "
                r._r.append(it)
            elif kind == "text":
                r.text = txt
            else:
                fc = OxmlElement("w:fldChar")
                fc.set(qn("w:fldCharType"), kind)
                r._r.append(fc)

    add_text(fp, "Iechyd Cyhoeddus Cymru | Public Health Wales")
    add_text(fp, "\tPage ")
    add_field(fp, "PAGE")
    add_text(fp, " of ")
    add_field(fp, "NUMPAGES")

doc.save(str(OUT))
print(f"Wrote {OUT}")
