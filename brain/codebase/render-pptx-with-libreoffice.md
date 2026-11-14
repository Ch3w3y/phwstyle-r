# Render PowerPoint output to images

This machine has no LibreOffice, Quarto or Chromium. To see what `phw_pptx()` / `phw_add_slide()` produce, render the .pptx in Docker:

1. Build the image once (Debian trixie has no `fonts-ubuntu`, so mount the package's own fonts instead):
   `FROM debian:trixie` + `apt-get install -y --no-install-recommends libreoffice-impress poppler-utils`, tagged `phw-lo`.
2. Convert, mounting `inst/fonts` so Ubuntu is used and giving LibreOffice a writable profile (without `-env:UserInstallation` it fails with "User installation could not be completed"):
   `docker run --rm -u $(id -u):$(id -g) -e HOME=/work/.home -v <repo>/inst/fonts:/usr/share/fonts/truetype/ubuntu:ro -v <dir>:/work phw-lo sh -c 'mkdir -p /work/.home && cd /work && soffice -env:UserInstallation=file:///work/.home/lo --headless --convert-to pdf deck.pptx; pdftoppm -r 64 -png deck.pdf slide'`
3. `magick montage slide-*.png -tile 2x3 -geometry +6+6 sheet.png` gives one contact sheet to look at.

LibreOffice stands in for PowerPoint; check a release deck in PowerPoint once.

Word and Excel output: `phw-lo` has Impress only, so it cannot convert .docx or .xlsx. Build `phw-lo-writer` from `FROM phw-lo` + `USER root` + `apt-get install -y --no-install-recommends libreoffice-writer libreoffice-calc`, then run the same command on it.

HTML widgets (reactable, DT, gt): `htmltools::save_html()` then `firefox --headless --screenshot out.png --window-size=900,600 file:///abs/path.html`.
