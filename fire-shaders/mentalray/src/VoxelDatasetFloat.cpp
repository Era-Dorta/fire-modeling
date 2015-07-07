/*
 * VoxelDatasetFloat.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetFloat.h"
#include <fstream>
#include <algorithm>

VoxelDatasetFloat::VoxelDatasetFloat(const char* filename,
		FILE_FORMAT file_format) {
	clear();
	initialize_with_file(filename, file_format);
}

void VoxelDatasetFloat::initialize_with_file(const char* filename,
		FILE_FORMAT file_format) {
	switch (file_format) {
	case ASCII_SINGLE_VALUE: {
		initialize_with_file_acii_single(filename);
		break;
	}
	case BIN_ONLY_RED: {
		initialize_with_file_bin_only_red(filename);
		break;
	}
	case BIN_MAX: {
		initialize_with_file_bin_max(filename);
		break;
	}
	}
}

void VoxelDatasetFloat::initialize_with_file_acii_single(const char* filename) {
	std::fstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Read width height and depth
	fp >> width;
	fp >> height;
	fp >> depth;

	count = width * height * depth;

	try {
		for (unsigned i = 0; i < count; i++) {
			if (fp.eof()) {
				mi_fatal("Error, file \"%s\" has less data that declared.",
						filename);
			}
			fp >> block[i];
		}
	} catch (int e) {
		fp.close();
		throw;
	}
}

void VoxelDatasetFloat::set_all_voxels_to(float val) {
	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	for (unsigned i = 0; i < count; i++) {
		block[i] = val;
	}
}

void VoxelDatasetFloat::read_bin_xyz(std::fstream& fp, int& x, int& y, int& z) {
	// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
	fp.read(reinterpret_cast<char*>(&x), 4);
	fp.read(reinterpret_cast<char*>(&y), 4);
	fp.read(reinterpret_cast<char*>(&z), 4);
}

void VoxelDatasetFloat::initialize_with_file_bin_only_red(
		const char* filename) {
	std::fstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Voxel is 128x128x128
	resize(128, 128, 128);

	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	set_all_voxels_to(0);

	int count;
	// Number of points in the file, integer, 4 bytes
	fp.read(reinterpret_cast<char*>(&count), 4);

	int x, y, z;
	double r, g, b, a;
	try {
		for (int i = 0; i < count; i++) {
			if (fp.eof()) {
				mi_fatal("Error, file \"%s\" has less data that declared.",
						filename);
			}
			// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
			read_bin_xyz(fp, x, z, y);

			// RGBA components, double, 8 bytes
			read_bin_rgba(fp, r, g, b, a);
			// For the moment assume the red component is the density
			set_voxel_value((unsigned) x, (unsigned) y, (unsigned) z, r);
		}
	} catch (int e) {
		fp.close();
		throw;
	}

}

void VoxelDatasetFloat::read_bin_rgba(std::fstream& fp, double& r, double& g,
		double& b, double& a) {
	// RGBA components, double, 8 bytes
	fp.read(reinterpret_cast<char*>(&r), 8);
	fp.read(reinterpret_cast<char*>(&g), 8);
	fp.read(reinterpret_cast<char*>(&b), 8);
	fp.read(reinterpret_cast<char*>(&a), 8);
}

void VoxelDatasetFloat::initialize_with_file_bin_max(const char* filename) {
	std::fstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Voxel is 128x128x128
	resize(128, 128, 128);

	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	set_all_voxels_to(0);

	int count;
	// Number of points in the file, integer, 4 bytes
	fp.read(reinterpret_cast<char*>(&count), 4);

	int x, y, z;
	double r, g, b, a;
	try {
		for (int i = 0; i < count; i++) {
			if (fp.eof()) {
				mi_fatal("Error, file \"%s\" has less data that declared.",
						filename);
			}
			// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
			read_bin_xyz(fp, x, z, y);

			// RGBA components, double, 8 bytes
			read_bin_rgba(fp, r, g, b, a);

			// For the temperature, use the channel with maximum intensity
			set_voxel_value((unsigned) x, (unsigned) y, (unsigned) z,
					std::max(std::max(r, g), b));
		}
	} catch (int e) {
		fp.close();
		throw;
	}
}
