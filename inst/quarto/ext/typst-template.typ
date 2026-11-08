// Public Health Wales Typst template (phwstyle Quarto extension)
#let phw-navy = rgb("#285087")
#let phw-text = rgb("#212B32")
#let phw-grey = rgb("#4C6272")
#let phw-border = rgb("#D8DDE0")
#let phw-bg = rgb("#F0F4F5")
#let phw-gradient = gradient.linear(rgb("#325082"), rgb("#326791"), rgb("#2A8DAC"), rgb("#2BADC5"), rgb("#27B8CD"))

#let phw-report(
  title: none,
  subtitle: none,
  authors: (),
  date: none,
  team: none,
  abstract: none,
  lang: "en",
  paper: "a4",
  font: ("Ubuntu", "Arial", "Liberation Sans", "DejaVu Sans"),
  fontsize: 11pt,
  sectionnumbering: "1.1",
  toc: false,
  toc_title: none,
  toc_depth: 3,
  cover: true,
  org: "Public Health Wales",
  page-label: "Page",
  of-label: "of",
  doc,
) = {
  let base = lang.split("-").at(0)
  let region = if lang.contains("-") { lang.split("-").at(1) } else { "GB" }

  set document(title: if title != none { title } else { "" })
  set text(font: font, size: fontsize, fill: phw-text, lang: base, region: region)
  set par(justify: false, leading: 0.68em, spacing: 0.9em)
  set heading(numbering: sectionnumbering)
  show heading: set text(fill: phw-navy, weight: "bold")
  show heading.where(level: 1): set text(size: 16pt)
  show heading.where(level: 2): set text(size: 13pt)
  show heading.where(level: 3): set text(size: 11.5pt)
  show heading: it => block(above: 1.3em, below: 0.7em, it)
  show link: set text(fill: rgb("#2D78A0"))
  show figure.caption: set text(fill: phw-navy, weight: "bold", size: 10pt)
  show figure.caption: set align(left)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: "quarto-float-tbl"): set figure.caption(position: top)
  show quote: it => block(fill: phw-bg, stroke: (left: 3pt + phw-navy), inset: 10pt, width: 100%, it.body)
  set table(
    stroke: (x, y) => if y == 0 { (top: 1.5pt + phw-navy, bottom: 1.5pt + phw-navy) } else { (bottom: 0.5pt + phw-border) },
    inset: (x: 6pt, y: 5pt),
  )
  show table.cell.where(y: 0): set text(weight: "bold", fill: phw-navy)
  show table: it => block(stroke: (bottom: 1.5pt + phw-navy), it)
  set list(marker: text(fill: phw-navy)[•])

  if cover and title != none {
    page(paper: paper, margin: 0pt, header: none, footer: none,
         background: image("cover-a4.jpg", width: 100%, height: 100%))[
      #place(top + left, dx: 1.8cm, dy: 1.8cm, image("phw-logo-white.svg", height: 2.3cm))
      #place(bottom + left, dx: 1.8cm, dy: -6.5cm, block(width: 16.5cm)[
        #set text(fill: white)
        #set par(leading: 0.5em)
        #text(size: 30pt, weight: "bold", title)
        #if subtitle != none { v(0.4em); text(size: 16pt, subtitle) }
        #v(1.4em)
        #text(size: 13pt, org)
        #if team != none { linebreak(); text(size: 11pt, team) }
        #for a in authors { linebreak(); text(size: 11pt, a) }
        #if date != none { v(0.4em); text(size: 11pt, date) }
      ])
    ]
  }

  set page(
    paper: paper,
    margin: (top: 3.2cm, bottom: 2.6cm, x: 2cm),
    background: place(top + left, block(width: 100%, height: 2.2cm, fill: phw-gradient,
      inset: (left: 1.8cm), align(horizon, image("phw-logo-white.svg", height: 1.45cm)))),
    footer: context [
      #line(length: 100%, stroke: 0.6pt + phw-navy)
      #v(-0.4em)
      #set text(size: 9pt, fill: phw-navy)
      #org #h(1fr) #page-label #strong(counter(page).display()) #of-label #strong[#counter(page).final().first()]
    ],
  )

  if not cover and title != none {
    block(below: 1.2em)[
      #text(size: 26pt, weight: "bold", fill: phw-navy, title)
      #if subtitle != none { linebreak(); text(size: 15pt, fill: phw-grey, subtitle) }
      #if date != none { linebreak(); text(size: 11pt, fill: phw-grey, date) }
      #line(length: 100%, stroke: 2pt + phw-navy)
    ]
  }
  if abstract != none {
    block(fill: phw-bg, inset: 12pt, width: 100%, abstract)
  }
  if toc {
    let t = if toc_title != none { toc_title } else { "Contents" }
    outline(title: t, depth: toc_depth, indent: auto)
    pagebreak()
  }
  doc
}
