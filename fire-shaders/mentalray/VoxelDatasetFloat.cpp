/*
 * VoxelDatasetFloat.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetFloat.h"
#include <fstream>

VoxelDatasetFloat::VoxelDatasetFloat(const char* filename) {
	clear();
	initialize_with_file(filename);
}

void VoxelDatasetFloat::initialize_with_file(const char* filename) {
	int count;
	std::fstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Read width heifht and depth
	fp >> width;
	fp >> height;
	fp >> depth;

	count = width * height * depth;

	for (int i = 0; i < count; i++) {
		if (fp.eof()) {
			mi_fatal("Error, file \"%s\" has less data that declared.",
					filename);
		}
		fp >> block[i];
		block[i] = block[i] * 4.15;
	}
}
