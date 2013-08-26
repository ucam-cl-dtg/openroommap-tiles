#!/bin/bash

set -e

PORT=$1
FLOOR=$2
GENERATE_OPS=$3
PREFIX=$4

SVGFILE=$PREFIX-$FLOOR-$GENERATE_OPS.svg

echo "Generating SVG for floor $FLOOR: $GENERATE_OPS"
perl generate-tiles.pl $PORT $FLOOR $GENERATE_OPS > $SVGFILE
mkdir -p tile
echo "Generating tiles from SVG"
python svgToTile.py $SVGFILE temp tile/$PREFIX-$FLOOR
