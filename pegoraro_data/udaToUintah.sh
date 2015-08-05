#!/bin/bash

if [ "$#" -le 0 ]; then
	echo ""
	echo "Missing data size"
	echo ""
	echo "Usage: udaToUintah <max_size>"
	echo ""
	exit 0 
fi

size=$1 # Voxel max size on x,y,z, change if working with bigger datasets

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
	
	# Save the dense data
	../tools/extractors/lineextract -v density -istart 0 0 0 -iend $size1 $size1 $size1 -tlow $i -thigh $i -o ascii_data/"$dir_name_s"_density_$suffix.tmp -uda $PWD
	../tools/extractors/lineextract -v temperature -istart 0 0 0 -iend $size1 $size1 $size1 -tlow $i -thigh $i -o ascii_data/"$dir_name_s"_temperature_$suffix.tmp  -uda $PWD
		
	# Convert to sparse
	./uintahToSparse "$size" "$size" "$size" ascii_data/"$dir_name_s"_density_$suffix.tmp ascii_data/"$dir_name_s"_density_$suffix.uintah
	./uintahToSparse "$size" "$size" "$size" ascii_data/"$dir_name_s"_temperature_$suffix.tmp ascii_data/"$dir_name_s"_temperature_$suffix.uintah
	
	# Delete dense data files
	rm ascii_data/"$dir_name_s"_density_$suffix.tmp
	rm ascii_data/"$dir_name_s"_temperature_$suffix.tmp
	
	let i=i+1
done 
