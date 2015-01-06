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
