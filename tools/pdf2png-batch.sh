#!/usr/bin/env bash
set -euo pipefail

# pdf2png-batch.sh — convert all PDFs in a folder to PNG(s)
#
# Usage:
#   ./pdf2png-batch.sh [input_dir] [output_dir]
#
# Defaults:
#   input_dir  = current directory
#   output_dir = input_dir/png
#
# Env options:
#   DPI=<int>              # rasterization DPI (default: 300)
#   BG_TRANSPARENT=true    # use pdftocairo with transparent background (if available)
#   RANGE="f:l"            # optional page range, e.g. "2:5" (first:last)

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-"$INPUT_DIR/png"}"
DPI="${DPI:-300}"
BG_TRANSPARENT="${BG_TRANSPARENT:-false}"
RANGE="${RANGE:-}"

mkdir -p "$OUTPUT_DIR"
shopt -s nullglob

# Prefer pdftocairo when transparency requested, else pdftoppm
use_pdftocairo=false
if [[ "$BG_TRANSPARENT" == "true" ]] && command -v pdftocairo >/dev/null 2>&1; then
  use_pdftocairo=true
elif ! command -v pdftoppm >/dev/null 2>&1 && command -v pdftocairo >/dev/null 2>&1; then
  # Fallback to pdftocairo if pdftoppm missing
  use_pdftocairo=true
fi

# Helper: build page range flags for both tools
page_flags_ppm=()
page_flags_cairo=()
if [[ -n "$RANGE" ]]; then
  IFS=':' read -r first last <<<"$RANGE"
  [[ -n "${first:-}" ]] && page_flags_ppm+=( -f "$first" ) && page_flags_cairo+=( -f "$first" )
  [[ -n "${last:-}"  ]] && page_flags_ppm+=( -l "$last"  ) && page_flags_cairo+=( -l "$last"  )
fi

convert_with_pdftoppm() {
  local pdf="$1" stem="$2"
  # This creates "$stem-1.png", "$stem-2.png", ...
  pdftoppm -png -r "$DPI" "${page_flags_ppm[@]}" "$pdf" "$OUTPUT_DIR/$stem"
}

convert_with_pdftocairo() {
  local pdf="$1" stem="$2"
  # This creates "$stem-1.png", "$stem-2.png", ...
  pdftocairo -png -r "$DPI" -transp "${page_flags_cairo[@]}" "$pdf" "$OUTPUT_DIR/$stem"
}

for pdf in "$INPUT_DIR"/*.pdf "$INPUT_DIR"/*.PDF; do
  [[ -e "$pdf" ]] || continue
  base="$(basename "$pdf")"
  stem="${base%.*}"

  echo "Converting: $pdf -> $OUTPUT_DIR/$stem-<n>.png  (DPI=$DPI, transparent=$BG_TRANSPARENT)"
  if $use_pdftocairo; then
    convert_with_pdftocairo "$pdf" "$stem"
  else
    command -v pdftoppm >/dev/null 2>&1 || { echo "Error: need pdftoppm or pdftocairo installed." >&2; exit 1; }
    convert_with_pdftoppm "$pdf" "$stem"
  fi

  # If only page 1 exists (no page 2), rename to "name.png"
  first="$OUTPUT_DIR/$stem-1.png"
  second="$OUTPUT_DIR/$stem-2.png"
  single="$OUTPUT_DIR/$stem.png"
  if [[ -f "$first" && ! -f "$second" ]]; then
    mv -f "$first" "$single"
    echo "Single-page → $single"
  fi
done

echo "Done. PNGs are in: $OUTPUT_DIR"
