# Word reference document and Quarto layout tables

- `inst/rmarkdown/resources/phw-reference.docx` is not a clean output of `data-raw/build-reference-docx.py`: #266 emptied its body by hand. Rerunning the script brings pandoc's sample text back. To change a style, run the script into a scratch copy (python-docx in a scratch venv), then splice the changed `<w:style>` into the shipped file's `word/styles.xml` with Python's `zipfile`, and change the script too.
- Quarto puts every captioned figure or table in a Word document inside a full-width layout table. Pandoc writes it with the `Table` style unless the table has a `custom-style` attribute (honoured by Quarto 1.11's pandoc). `inst/quarto/ext/phw-layout-tables.lua` runs after Quarto's filters and gives those tables the `LayoutTable` style. It finds them by the `ImageCaption` raw OpenXML that Quarto writes into their captions.
- Pandoc shrinks a picture to the text width, not the cell width, so any cell padding crops a full-width picture (#421).
- Rendering `.docx` to images: [[codebase/render-pptx-with-libreoffice]] (the `phw-lo-writer` image).
