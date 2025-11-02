#!/usr/bin/env bash
set -euo pipefail

# inkscape-pdf2svg.sh — convert PDFs to SVG(s) with Inkscape
# Usage:
#   ./inkscape-pdf2svg.sh [input_dir] [output_dir]
# Defaults:
#   input_dir  = .
#   output_dir = <input_dir>/svg
#
# Env:
#   TEXT_TO_PATH=true|false   (default true)
#   PLAIN_SVG=true|false      (default true)

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-"$INPUT_DIR/svg"}"
TEXT_TO_PATH="${TEXT_TO_PATH:-true}"
PLAIN_SVG="${PLAIN_SVG:-true}"

command -v inkscape >/dev/null 2>&1 || {
  echo "Error: inkscape not found." >&2; exit 1;
}

mkdir -p "$OUTPUT_DIR"
shopt -s nullglob

warned_no_pdfinfo=false
get_pages() {
  local pdf="$1"
  if command -v pdfinfo >/dev/null 2>&1; then
    pdfinfo "$pdf" | awk -F': *' '/^Pages/ {print $2; exit}'
  else
    if ! $warned_no_pdfinfo; then
      echo "Note: 'pdfinfo' not found. Assuming PDFs are single-page." >&2
      warned_no_pdfinfo=true
    fi
    echo 1
  fi
}

for pdf in "$INPUT_DIR"/*.pdf "$INPUT_DIR"/*.PDF; do
  [[ -e "$pdf" ]] || continue
  base="$(basename "$pdf")"
  stem="${base%.*}"

  pages=$(get_pages "$pdf")
  [[ "$pages" =~ ^[0-9]+$ && "$pages" -ge 1 ]] || { echo "Could not determine page count for $pdf"; continue; }

  flags=( --pdf-poppler --export-type=svg )
  $PLAIN_SVG && flags+=( --export-plain-svg )
  $TEXT_TO_PATH && flags+=( --export-text-to-path )

  if [[ "$pages" -eq 1 ]]; then
    out="$OUTPUT_DIR/$stem.svg"
    echo "Exporting 1 page: $pdf -> $out"
    inkscape "${flags[@]}" --pdf-page=1 "$pdf" -o "$out"
  else
    echo "Exporting $pages pages: $pdf -> $OUTPUT_DIR/$stem-<n>.svg"
    for ((p=1; p<=pages; p++)); do
      out="$OUTPUT_DIR/$stem-$p.svg"
      inkscape "${flags[@]}" --pdf-page="$p" "$pdf" -o "$out"
    done
  fi
done

echo "Done. SVGs are in: $OUTPUT_DIR"
