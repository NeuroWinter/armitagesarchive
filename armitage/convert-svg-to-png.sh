#!/bin/bash
set -euo pipefail

FONT_DIR="/tmp/resvg_fonts/"
SVG_DIR="priv/static/og/quotes"
OUT_DIR="${SVG_DIR}/png"

mkdir -p "$OUT_DIR"

echo "Rendering SVGs with resvg using fonts from: $FONT_DIR"

# Loop over SVGs
for svg in "$SVG_DIR"/*.svg; do
  base=$(basename "$svg" .svg)
  out="${OUT_DIR}/${base}.png"

  echo "Rendering $svg → $out"

  # Run resvg with custom font directory
  resvg "$svg" "$out" \
    --font-db "$FONT_DIR"
done
