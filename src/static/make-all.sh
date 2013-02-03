#!/bin/bash
ssh open-room-map.cl.cam.ac.uk -f -n -N -L 5432:localhost:5432
SSH=$!
for floor in `seq 0 1 2`; do bash ./make-tiles.sh $floor rooms,objects subtile; done
for floor in `seq 0 1 2`; do bash ./make-tiles.sh $floor people subpeople; done

for floor in `seq 0 1 2`; do
    perl generate-tiles.pl $floor people,rooms,objects,desksOnly > temp.svg
    touch floor$floor-allocation.svg
    if [ ! `diff floor$floor-allocation.svg temp.svg >/dev/null 2>&1`]; then mv temp.svg floor$floor-allocation.svg; inkscape floor$floor-allocation.svg -A floor$floor-allocation.pdf; fi

kill $SHH

# for floor in `seq 0 1 2`; do ./make-files floor$$floor-labels.svg temp sublabel-$$floor; done

