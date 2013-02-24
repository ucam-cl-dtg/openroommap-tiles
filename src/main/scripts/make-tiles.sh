#!/bin/bash

FLOOR=$1
GENERATE_OPS=$2
PREFIX=$3

SVGFILE=$PREFIX-$FLOOR-$GENERATE_OPS.svg

echo "Generating SVG for floor $FLOOR: $GENERATE_OPS"
ssh open-room-map.dtg.cl.cam.ac.uk -f -L 5433:localhost:5432 sleep 3
perl generate-tiles.pl $FLOOR $GENERATE_OPS > temp.svg
touch $SVGFILE
if `diff $SVGFILE temp.svg >/dev/null 2>&1`; then
    echo "File has not changed"
    rm temp.svg
else
    echo "File has changed"
    mv temp.svg $SVGFILE
    mkdir -p tile
    python svgToTile.py $SVGFILE temp tile/$PREFIX-$FLOOR
fi
