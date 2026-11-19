# Rebuilding the reference PowerPoint deck

`inst/rmarkdown/resources/phw-reference.pptx` comes from `data-raw/build-reference-pptx.py`.

- python-pptx is not installed system-wide. Make a venv in a scratch folder (`python3 -m venv <scratch>/venv && <scratch>/venv/bin/pip install python-pptx`) and run the script from the package root with that Python.
- The build is reproducible: rebuilding an unchanged script gives byte-identical XML parts. Unzip the old and new decks and `diff -r` them to prove a change touches only what you meant.
- A slide inherits placeholder text styles from the layout's and master's `a:lstStyle`, not from the master's sample paragraph. python-pptx `para.font` writes into the sample paragraph's `a:pPr/a:defRPr`, which slides ignore. For example, the master's `dt`, `ftr` and `sldNum` look 10pt `#4C6272` in the master but give slides 12pt `tx1` at a 75% tint. Set colours on a layout through `a:lstStyle/a:lvl1pPr/a:defRPr`, as the navy layouts do (#377).
- To see a knitted deck, render it as in [[codebase/render-pptx-with-libreoffice]].
