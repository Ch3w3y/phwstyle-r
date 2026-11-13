#!/usr/bin/env bash
# Run phwstyle's tests across versions of R, of its dependencies, and of the
# document tools (Pandoc, Quarto, LaTeX). CI covers part of this on every
# push (.github/workflows/R-CMD-check.yaml); this script covers the rest and
# can be run on one Linux machine before a release.
#
#   data-raw/version-battery/battery.sh              # every cell
#   data-raw/version-battery/battery.sh r44-latest   # named cells only
#   data-raw/version-battery/battery.sh tools        # Pandoc, Quarto and LaTeX only
#
# Needs: curl; uvr (https://nbafrank.github.io/uvr/) to install R versions
# for the "latest" cells; Docker for the dated cells. Everything is written
# under $PHW_BATTERY_DIR (default ~/.cache/phwstyle-battery).
# Results: $PHW_BATTERY_DIR/results.csv, one row per cell.
set -u
here=$(cd "$(dirname "$0")" && pwd)
pkg=$(cd "$here/../.." && pwd)
bat=${PHW_BATTERY_DIR:-$HOME/.cache/phwstyle-battery}
rdir=${PHW_BATTERY_R:-$bat/r}
results=$bat/results.csv
mkdir -p "$bat/cells" "$bat/tools" "$rdir"
export TAR=${TAR:-$(command -v tar)}

# cell | R version | CRAN snapshot | pins (package@snapshot ...) | Quarto
#
# "latest" cells: every supported version of R with today's packages, run on
# this machine with Linux binaries from Posit Package Manager.
#
# Dated cells: a version of R with CRAN as it was on a day when that R was
# current, which is what a machine set up then and not updated since has.
# They run in a rocker/r-ver container of the matching Ubuntu release, where
# the binaries for a date were built on that date.
# * r43-2025-04 and r44-2026-04 are what Windows users of an old R get:
#   CRAN stops building Windows binaries for a version of R when the
#   release two after it comes out, so their packages are frozen then.
#   R 4.3 is the minimum in DESCRIPTION because it is the oldest R whose
#   frozen packages meet every minimum version declared there.
# * r43-2024-06 is the declared minimum of every package; keep it in step
#   with DESCRIPTION.
cells='
r43-latest      | 4.3.3 | latest     |                    |
r44-latest      | 4.4.3 | latest     |                    |
r45-latest      | 4.5.3 | latest     |                    |
r46-latest      | 4.6.0 | latest     |                    |
r45-ggplot2-3.5 | 4.5.3 | latest     | ggplot2@2025-06-02 |
r43-2025-04     | 4.3.3 | 2025-04-10 |                    | 1.6.43
r44-2026-04     | 4.4.3 | 2026-04-15 |                    | 1.8.26
r43-2024-06     | 4.3.3 | 2024-06-03 | ggplot2@2024-03-01 | 1.5.57
r44-2024-12     | 4.4.2 | 2024-12-02 |                    | 1.6.43
r45-2025-06     | 4.5.0 | 2025-06-02 |                    | 1.7.34
r45-2025-12     | 4.5.2 | 2025-12-01 |                    | 1.8.26
'
# Document tools, each tried with the r45-latest library.
pandocs=${PHW_BATTERY_PANDOCS:-"2.11.4 2.19.2 3.1.11 3.6.4"}
quartos=${PHW_BATTERY_QUARTOS:-"1.5.57 1.6.43 1.7.34 1.8.26"}
pandoc_default=3.6.4

r_bin() {  # install R <version> if needed and print its bin directory
  if [ ! -x "$rdir/$1/bin/Rscript" ]; then
    uvr r install "$1" --install-dir "$rdir" --no-companion >&2 || return 1
  fi
  echo "$rdir/$1/bin"
}
get_pandoc() {
  local d=$bat/tools/pandoc-$1
  if [ ! -x "$d/bin/pandoc" ]; then
    mkdir -p "$d" && curl -fsSL "https://github.com/jgm/pandoc/releases/download/$1/pandoc-$1-linux-amd64.tar.gz" \
      | tar xz -C "$d" --strip-components=1 || return 1
  fi
  echo "$d/bin"
}
get_quarto() {
  local d=$bat/tools/quarto-$1
  if [ ! -x "$d/bin/quarto" ]; then
    mkdir -p "$d" && curl -fsSL "https://github.com/quarto-dev/quarto-cli/releases/download/v$1/quarto-$1-linux-amd64.tar.gz" \
      | tar xz -C "$d" --strip-components=1 || return 1
  fi
  echo "$d/bin"
}

run_native() {
  local name=$1 rver=$2 snap=$3 pins=$4 bin lib p
  bin=$(r_bin "$rver") || { echo "$name: could not install R $rver"; return; }
  p=$(get_pandoc $pandoc_default) || { echo "$name: could not download pandoc"; return; }
  lib=$bat/cells/$name/lib
  mkdir -p "$bat/cells/$name/pkg"
  # A library that is already built is reused. PHW_BATTERY_REBUILD=1 tries
  # again to install whatever is missing from it.
  if [ -n "${PHW_BATTERY_REBUILD:-}" ] || ! grep -q "^installed:" "$bat/cells/$name/deps.log" 2>/dev/null; then
    # shellcheck disable=SC2086
    "$bin/Rscript" "$here/install-deps.R" "$pkg" "$lib" "$snap" $pins > "$bat/cells/$name/deps.log" 2>&1
  fi
  export R_LIBS="$bat/cells/$name/pkg:$lib-pins:$lib"
  "$bin/R" CMD INSTALL --no-docs --library="$bat/cells/$name/pkg" "$pkg" > "$bat/cells/$name/install.log" 2>&1 \
    || { echo "$name: phwstyle did not install (see $bat/cells/$name/install.log)"; return; }
  RSTUDIO_PANDOC=$p "$bin/Rscript" "$here/run-tests.R" "$pkg" "$name" "$results" 2> "$bat/cells/$name/tests.log"
  grep -h "not installed:" "$bat/cells/$name/deps.log" | sed "s/^/  /"
}

run_docker() {
  local name=$1 rver=$2 snap=$3 pins=$4 quarto=$5 p q qenv=()
  p=$(get_pandoc $pandoc_default) || { echo "$name: could not download pandoc"; return; }
  if [ -n "$quarto" ]; then
    q=$(get_quarto "$quarto") || { echo "$name: could not download quarto $quarto"; return; }
    qenv=(-e "PHW_BATTERY_QUARTO_DIR=/bat/tools/quarto-$quarto/bin")
  fi
  mkdir -p "$bat/cells/$name"
  # shellcheck disable=SC2086
  docker run --rm -v "$pkg:/pkg:ro" -v "$bat:/bat" \
    -e "PHW_BATTERY_PANDOC_DIR=/bat/tools/pandoc-$pandoc_default/bin" "${qenv[@]}" \
    -e "PHW_BATTERY_NCPUS=${PHW_BATTERY_NCPUS:-4}" -e "PHW_BATTERY_REBUILD=${PHW_BATTERY_REBUILD:-}" \
    "rocker/r-ver:$rver" bash /pkg/data-raw/version-battery/docker-cell.sh "$name" "$snap" "$(id -u):$(id -g)" $pins
}

run_tools() {
  local base=r45-latest bin p q v
  [ -d "$bat/cells/$base/pkg/phwstyle" ] || run_native $base 4.5.3 latest ""
  bin=$(r_bin 4.5.3)
  export R_LIBS="$bat/cells/$base/pkg:$bat/cells/$base/lib-pins:$bat/cells/$base/lib"
  "$bin/R" CMD INSTALL --no-docs --library="$bat/cells/$base/pkg" "$pkg" > "$bat/cells/$base/install.log" 2>&1
  for v in $pandocs; do
    p=$(get_pandoc "$v") || { echo "pandoc $v: download failed"; continue; }
    RSTUDIO_PANDOC=$p "$bin/Rscript" "$here/run-tests.R" "$pkg" "pandoc-$v" "$results" formats 2> "$bat/tools/pandoc-$v.log"
  done
  p=$(get_pandoc $pandoc_default)
  for v in $quartos; do
    q=$(get_quarto "$v") || { echo "quarto $v: download failed"; continue; }
    PATH=$q:$PATH QUARTO_PATH=$q/quarto RSTUDIO_PANDOC=$p "$bin/Rscript" "$here/run-tests.R" "$pkg" "quarto-$v" "$results" formats 2> "$bat/tools/quarto-$v.log"
  done
  # PDF through LaTeX: TinyTeX, installed once into the battery folder.
  if [ ! -x "$bat/tools/tinytex/bin/x86_64-linux/xelatex" ]; then
    TINYTEX_DIR=$bat/tools/tinytex "$bin/Rscript" -e 'tinytex::install_tinytex(force = TRUE, dir = Sys.getenv("TINYTEX_DIR"), add_path = FALSE)' > "$bat/tools/tinytex.log" 2>&1
  fi
  PATH=$bat/tools/tinytex/bin/x86_64-linux:$PATH RSTUDIO_PANDOC=$p "$bin/Rscript" "$here/run-tests.R" "$pkg" "latex-tinytex" "$results" formats 2> "$bat/tools/latex.log"
}

want=" $* "
echo "$cells" | while IFS='|' read -r name rver snap pins quarto; do
  name=$(echo "$name" | xargs); [ -z "$name" ] && continue
  rver=$(echo "$rver" | xargs); snap=$(echo "$snap" | xargs); pins=$(echo "$pins" | xargs); quarto=$(echo "$quarto" | xargs)
  if [ $# -eq 0 ] || [[ "$want" == *" $name "* ]]; then
    if [ "$snap" = latest ]; then run_native "$name" "$rver" "$snap" "$pins"
    else run_docker "$name" "$rver" "$snap" "$pins" "$quarto"; fi
  fi
done
if [ $# -eq 0 ] || [[ "$want" == *" tools "* ]]; then run_tools; fi
echo "Results: $results"
