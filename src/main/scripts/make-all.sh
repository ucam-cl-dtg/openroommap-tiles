#!/bin/bash

set -e

HOST=$1

ssh $HOST -f -L 5433:localhost:5432 sleep 3
touch lastupdateid.txt
perl get-last-update-id.pl > temp.txt
if [ `diff temp.txt lastupdateid.txt >/dev/null 2>&1`]; then
    echo "Last update id has changed"
    for floor in `seq 0 1 2`; do 
	ssh $HOST -f -L 5433:localhost:5432 sleep 3
	bash ./make-tiles.sh $floor rooms,objects subtile
    done
    for floor in `seq 0 1 2`; do 
	ssh $HOST -f -L 5433:localhost:5432 sleep 3
	bash ./make-tiles.sh $floor people subpeople
    done

    for floor in `seq 0 1 2`; do
	ssh $HOST -f -L 5433:localhost:5432 sleep 3
	perl generate-tiles.pl $floor people,rooms,objects,desksOnly > temp.svg
	touch floor$floor-allocation.svg
	if [ ! `diff floor$floor-allocation.svg temp.svg >/dev/null 2>&1`]; then 
	    mv temp.svg floor$floor-allocation.svg
	    inkscape floor$floor-allocation.svg -A floor$floor-allocation.pdf
	fi
    done

    cp temp.txt lastupdateid.txt
fi

# for floor in `seq 0 1 2`; do ./make-files floor$$floor-labels.svg temp sublabel-$$floor; done