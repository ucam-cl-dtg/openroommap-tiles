#!/bin/bash

set -e

FLOOR=$1
GENERATE_OPS=$2
PREFIX=$3

SVGFILE=$PREFIX-$FLOOR-$GENERATE_OPS.svg

echo "Generating SVG for floor $FLOOR: $GENERATE_OPS"
perl generate-tiles.pl $FLOOR $GENERATE_OPS > $SVGFILE
mkdir -p tile
python svgToTile.py $SVGFILE temp tile/$PREFIX-$FLOOR
