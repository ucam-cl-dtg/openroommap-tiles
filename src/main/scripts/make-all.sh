#!/bin/bash

set -e

HOST=$1

ssh $HOST -f -L 5433:localhost:5432 sleep 3
touch lastupdateid.txt
POLLED_UPDATE=`perl get-last-update-id.pl`
STORED_UPDATE=`cat lastupdateid.txt`
if [ "$POLLED_UPDATE" != "$STORED_UPDATE" ]; then
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
	perl generate-tiles.pl $floor people,rooms,objects,desksOnly > floor$floor-allocation.svg
	inkscape floor$floor-allocation.svg -A tile/floor$floor-allocation.pdf
    done

    `echo $POLLED_UPDATE > lastupdateid.txt`
fi

# for floor in `seq 0 1 2`; do ./make-files floor$$floor-labels.svg temp sublabel-$$floor; done