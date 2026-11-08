#show: doc => phw-report(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  authors: ($for(by-author)$"$it.name.literal$",$endfor$),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(phw-team)$
  team: [$phw-team$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-title)$
  toc_title: [$toc-title$],
$endif$
$if(toc-depth)$
  toc_depth: $toc-depth$,
$endif$
$if(phw-org)$
  org: "$phw-org$",
$endif$
$if(phw-page-label)$
  page-label: "$phw-page-label$",
$endif$
$if(phw-of-label)$
  of-label: "$phw-of-label$",
$endif$
$if(phw-no-cover)$
  cover: false,
$endif$
  doc,
)
