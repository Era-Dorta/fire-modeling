#!/bin/bash

if [ ! -d ascii_data/sparse ]; then
	mkdir ascii_data/sparse # Create dir if it does not exits
else
	if [ "$(ls -A ascii_data/sparse)" ]; then
		read -r -p "ascii_data/sparse is not empty, overwrite?[y/n]" response
		response=${response,,}    # tolower
		if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then # Response is no
			exit 0
		fi
	fi
fi

cd ascii_data

for currentFile in `ls *.uintah`; # For all the files
do
	# Add the maximum voxel size and background temperatures at the beginning of the file 
	fileName="${currentFile%.*}"
	echo "ascii_data/${currentFile} to ascii_data/sparse/${fileName}.suintah"
	../uintahToSparse "$currentFile" sparse/"$fileName".suintah
done

cd ../
