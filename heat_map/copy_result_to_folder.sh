#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters, <num frames> <input dir> <output dir>"
fi

TOTAL_FRAMES=$1
INPUT_FOLDER=$2
OUTPUT_FOLDER=$3

DO_ECHO=1

while true; do
	read -p "Move $INPUT_FOLDER[*]/optimized-Cam1.tif to $OUTPUT_FOLDER/optimized-Cam1-[*].tif ?[y/n]" yn
	case $yn in
	    [Yy]* ) break;;
	    [Nn]* ) exit;;
	    * ) echo "Please answer yes or no.";;
	esac
done

for i in `seq 0 $TOTAL_FRAMES`;
do
	NUM_FRAME=$(printf "%04d" $i)
	if [ "$DO_ECHO" -eq 1 ]; then
		echo "cp $INPUT_FOLDER$i/optimized-Cam1.tif $OUTPUT_FOLDER/optimized-Cam1-$NUM_FRAME.tif"
	fi
	cp $INPUT_FOLDER$i/optimized-Cam1.tif $OUTPUT_FOLDER/optimized-Cam1-$NUM_FRAME.tif
done
