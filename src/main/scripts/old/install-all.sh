#!/bin/bash

scp tile/* open-room-map.cl.cam.ac.uk:/var/www/research/dtg/openroommap/static/tile/
scp floor*-allocation.pdf open-room-map.cl.cam.ac.uk:/var/www/research/dtg/openroommap/static/
ssh open-room-map.cl.cam.ac.uk -f -n -N -L 5432:localhost:5432
SSH=$!
perl clean-db.pl 5432
kill $SHH
