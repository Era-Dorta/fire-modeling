#!/bin/bash

if [ "$#" -le 0 ]; then
	echo ""
	echo "Missing data size"
	echo ""
	echo "Usage: save_data <max_size> [background_density] [background_temperature]"
	echo ""
	exit 0 
fi

size=$1 # Voxel max size on x,y,z, change if working with bigger datasets

if [ "$#" -gt 1 ]; then # Background temperatures
	background_density=$2
	if [ "$#" -gt 2 ]; then
		background_temperature=$3
	else
		background_temperature=0
	fi
else
	background_density=0
	background_temperature=0
fi

if [ ! -d ascii_data ]; then
	mkdir ascii_data # Create dir if it does not exits
else
	if [ "$(ls -A ascii_data)" ]; then
		read -r -p "ascii_data is not empty, overwrite?[y/n]" response
		response=${response,,}    # tolower
		if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then # Response is no
			exit 0
		fi
	fi
fi

current_dir=${PWD##*/} # Current dir name
dir_name_s="${current_dir%.*}" # Take the .uda out of the dir name
let size1=size-1
i=0

for j in `echo t0*`; # For all the timestep folders
do
	suffix=$(printf "%03d" $i) # Add three zeros to the name
	
	# Save the data
	../tools/extractors/lineextract -v density -istart 0 0 0 -iend $size1 $size1 $size1 -tlow $i -thigh $i -o ascii_data/"$dir_name_s"_density_$suffix.uintah -uda $PWD
	../tools/extractors/lineextract -v temperature -istart 0 0 0 -iend $size1 $size1 $size1 -tlow $i -thigh $i -o ascii_data/"$dir_name_s"_temperature_$suffix.uintah  -uda $PWD
	
	# Add the maximum voxel size and background temperatures at the beginning of the file 
	sed -i "1i$size $size $size $background_density" ascii_data/"$dir_name_s"_density_"$suffix".uintah
	sed -i "1i$size $size $size $background_temperature" ascii_data/"$dir_name_s"_temperature_"$suffix".uintah	
	
	let i=i+1
done 
