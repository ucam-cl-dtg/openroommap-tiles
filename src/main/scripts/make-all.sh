#*******************************************************************************
# Copyright 2014 Digital Technology Group, Computer Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#*******************************************************************************
#!/bin/bash

get_port() {
   # strip out username if there
   HOST=`echo $1 | sed -e "s/^.*@//"`
   echo $(( `dig +short $HOST | tail -n1 | sed -e "s/\.//g"` % 55535 + 10000 ))
}

set -e

HOST=$1
PORT=`get_port $HOST`

ssh $HOST -f -L $PORT:localhost:5432 sleep 3
touch lastupdateid.txt
POLLED_UPDATE=`perl get-last-update-id.pl $PORT`
STORED_UPDATE=`cat lastupdateid.txt`
if [ "$POLLED_UPDATE" != "$STORED_UPDATE" ]; then
    echo "Last update id has changed"
    for floor in `seq 0 1 2`; do 
	ssh $HOST -f -L $PORT:localhost:5432 sleep 3
	bash ./make-tiles.sh $PORT $floor rooms,objects subtile
    done
    for floor in `seq 0 1 2`; do 
	ssh $HOST -f -L $PORT:localhost:5432 sleep 3
	bash ./make-tiles.sh $PORT $floor people subpeople
    done

    for floor in `seq 0 1 2`; do
	ssh $HOST -f -L $PORT:localhost:5432 sleep 3
	perl generate-tiles.pl $PORT $floor people,rooms,objects,desksOnly > floor$floor-allocation.svg
	inkscape floor$floor-allocation.svg -A allocation.pdf
	gs -o tile/floor$floor-allocation.pdf  -sDEVICE=pdfwrite  -sPAPERSIZE=a4  -dFIXEDMEDIA  -dPDFFitPage  -dCompatibilityLevel=1.4 allocation.pdf

	python svgToTile.py floor$floor-labels.svg temp tile/sublabel-$floor
    done



    `echo $POLLED_UPDATE > lastupdateid.txt`
fi

# for floor in `seq 0 1 2`; do ./make-files floor$$floor-labels.svg temp sublabel-$$floor; done