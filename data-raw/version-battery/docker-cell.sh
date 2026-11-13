#!/usr/bin/env bash
# One dated cell of the battery, inside a rocker/r-ver container. Started by
# battery.sh, which mounts the package at /pkg and the battery folder at /bat.
# Usage: docker-cell.sh <cell> <snapshot> <uid:gid> [pins...]
set -u
name=$1; snap=$2; owner=$3; shift 3
cell=/bat/cells/$name
mkdir -p "$cell/pkg"
export DEBIAN_FRONTEND=noninteractive
{
  apt-get update -qq
  # Libraries the R packages load or build against (sf, ragg, xml2, V8, rsvg...).
  apt-get install -y -qq --no-install-recommends \
    libgdal-dev libgeos-dev libproj-dev libudunits2-dev libcurl4-openssl-dev libssl-dev \
    libxml2-dev libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
    libpng-dev libtiff-dev libjpeg-dev libcairo2-dev librsvg2-dev libnode-dev zlib1g-dev \
    libicu-dev make g++ gfortran
} > "$cell/apt.log" 2>&1
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
export PHW_BATTERY_REPO="https://packagemanager.posit.co/cran/__linux__/$codename/%s"
export RSTUDIO_PANDOC=${PHW_BATTERY_PANDOC_DIR:-}
if [ -n "${PHW_BATTERY_QUARTO_DIR:-}" ]; then
  export PATH=$PHW_BATTERY_QUARTO_DIR:$PATH QUARTO_PATH=$PHW_BATTERY_QUARTO_DIR/quarto
fi
if [ -n "${PHW_BATTERY_REBUILD:-}" ] || ! grep -q "^installed:" "$cell/deps.log" 2>/dev/null; then
  Rscript /pkg/data-raw/version-battery/install-deps.R /pkg "$cell/lib" "$snap" "$@" > "$cell/deps.log" 2>&1
fi
export R_LIBS="$cell/pkg:$cell/lib-pins:$cell/lib"
if R CMD INSTALL --no-docs --library="$cell/pkg" /pkg > "$cell/install.log" 2>&1; then
  Rscript /pkg/data-raw/version-battery/run-tests.R /pkg "$name" /bat/results.csv 2> "$cell/tests.log"
else
  echo "$name: phwstyle did not install (see cells/$name/install.log)"
fi
grep -h "not installed:" "$cell/deps.log" | sed "s/^/  /"
chown -R "$owner" "$cell" /bat/results.csv /bat/results.csv.* 2>/dev/null
exit 0
