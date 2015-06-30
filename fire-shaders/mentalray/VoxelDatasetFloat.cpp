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
	std::fstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Number of points in the file, integer, 4 bytes
	fp.read(reinterpret_cast<char*>(&count), 4);

	// Voxel is 128x128x128
	height = depth = width = 128;

	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	for (unsigned i = 0; i < height * depth * width; i++) {
		block[i] = 0;
	}

	int x, y, z;
	double r, g, b, a;
	for (int i = 0; i < count; i++) {
		if (fp.eof()) {
			mi_fatal("Error, file \"%s\" has less data that declared.",
					filename);
		}
		// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
		fp.read(reinterpret_cast<char*>(&x), 4);
		fp.read(reinterpret_cast<char*>(&z), 4);
		fp.read(reinterpret_cast<char*>(&y), 4);

		// RGBA components, double, 8 bytes
		fp.read(reinterpret_cast<char*>(&r), 8);
		fp.read(reinterpret_cast<char*>(&g), 8);
		fp.read(reinterpret_cast<char*>(&b), 8);
		fp.read(reinterpret_cast<char*>(&a), 8);

		// For the moment assume the red componet is the density
		set_voxel_value((unsigned) x, (unsigned) y, (unsigned) z, r);
	}
}
