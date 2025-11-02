#!/usr/bin/env bash
set -euo pipefail

# pdf2svg-batch.sh — convert all PDFs in a folder to SVG(s)
# Single-page PDFs -> name.svg
# Multi-page PDFs  -> name-1.svg, name-2.svg, ...
#
# Usage:
#   ./pdf2svg-batch.sh [input_dir] [output_dir]
# Defaults:
#   input_dir  = current directory
#   output_dir = input_dir/svg

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-"$INPUT_DIR/svg"}"

command -v pdf2svg >/dev/null 2>&1 || {
  echo "Error: pdf2svg not found. Install it (e.g., sudo apt-get install pdf2svg) and retry." >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR"
shopt -s nullglob
found_any=false

while IFS= read -r -d '' pdf; do
  found_any=true
  base="$(basename "$pdf")"
  stem="${base%.*}"

  # 1) Convert all pages to stem-%d.svg
  out_pattern="$OUTPUT_DIR/$stem-%d.svg"
  echo "Converting: $pdf -> $out_pattern"
  pdf2svg "$pdf" "$out_pattern" all

  # 2) If only page 1 exists (no page 2), rename to stem.svg
  first="$OUTPUT_DIR/$stem-1.svg"
  second="$OUTPUT_DIR/$stem-2.svg"
  single="$OUTPUT_DIR/$stem.svg"

  if [[ -f "$first" && ! -f "$second" ]]; then
    # Overwrite any existing stem.svg
    mv -f "$first" "$single"
    echo "Single-page: renamed to $single"
  fi

done < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname '*.pdf' \) -print0)

if ! $found_any; then
  echo "No PDFs found in: $INPUT_DIR"
else
  echo "Done. SVGs are in: $OUTPUT_DIR"
fi
