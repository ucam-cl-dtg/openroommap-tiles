#!/bin/bash
ssh open-room-map.dtg.cl.cam.ac.uk -f -L 5433:localhost:5432 sleep 10
export PGPASSWORD=openroommap
pg_dump -p 5433 -h localhost -U orm openroommap > openroommap-`date +%Y-%m-%d-%H:%M:%S`.sql
export PGPASSWORD=


