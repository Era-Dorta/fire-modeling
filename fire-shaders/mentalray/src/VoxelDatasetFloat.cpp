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
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Read width height and depth
	safe_ascii_read(fp, width);
	safe_ascii_read(fp, height);
	safe_ascii_read(fp, depth);

	resize(width, height, depth);

	for (unsigned i = 0; i < count; i++) {
		safe_ascii_read(fp, block[i]);
	}

	fp.close();
}

void VoxelDatasetFloat::set_all_voxels_to(float val) {
	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	for (unsigned i = 0; i < count; i++) {
		block[i] = val;
	}
}

void VoxelDatasetFloat::initialize_with_file_bin_only_red(
		const char* filename) {

	std::ifstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Voxel is MAX_DATASET_DIMxMAX_DATASET_DIMxMAX_DATASET_DIM
	resize(MAX_DATASET_DIM, MAX_DATASET_DIM, MAX_DATASET_DIM);

	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	set_all_voxels_to(0);

	int count;
	// Number of points in the file, integer, 4 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&count), 4);

	int x, y, z;
	double r, g, b, a;

	for (int i = 0; i < count; i++) {
		// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
		read_bin_xyz(fp, x, z, y);

		// RGBA components, double, 8 bytes
		read_bin_rgba(fp, r, g, b, a);

		// Make sure the indices are in a valid range
		check_index_range(x, y, z, fp, filename);

		// For the moment assume the red component is the density
		set_voxel_value((unsigned) x, (unsigned) y, (unsigned) z, r);
	}

	fp.close();
}

void VoxelDatasetFloat::initialize_with_file_bin_max(const char* filename) {
	std::ifstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Voxel is MAX_DATASET_DIMxMAX_DATASET_DIMxMAX_DATASET_DIM
	resize(MAX_DATASET_DIM, MAX_DATASET_DIM, MAX_DATASET_DIM);

	// Initialise all densities to 0, because the data comes in as a sparse
	// matrix
	set_all_voxels_to(0);

	int count;
	// Number of points in the file, integer, 4 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&count), 4);

	int x, y, z;
	double r, g, b, a;

	for (int i = 0; i < count; i++) {
		// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
		read_bin_xyz(fp, x, z, y);

		// RGBA components, double, 8 bytes
		read_bin_rgba(fp, r, g, b, a);

		// Make sure the indices are in a valid range
		check_index_range(x, y, z, fp, filename);

		// For the temperature, use the channel with maximum intensity
		set_voxel_value((unsigned) x, (unsigned) y, (unsigned) z,
				std::max(std::max(r, g), b));
	}

	fp.close();
}

void VoxelDatasetFloat::read_bin_xyz(std::ifstream& fp, int& x, int& y,
		int& z) {
	// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
	safe_binary_read(fp, reinterpret_cast<char*>(&x), 4);
	safe_binary_read(fp, reinterpret_cast<char*>(&y), 4);
	safe_binary_read(fp, reinterpret_cast<char*>(&z), 4);
}

void VoxelDatasetFloat::read_bin_rgba(std::ifstream& fp, double& r, double& g,
		double& b, double& a) {
	// RGBA components, double, 8 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&r), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&g), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&b), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&a), 8);
}

void VoxelDatasetFloat::safe_binary_read(std::ifstream& fp, char *output,
		long int byte_size) {
	fp.read(output, byte_size);
	if (!fp) {
		fp.close();
		mi_fatal("Error reading file");
	}
}

void VoxelDatasetFloat::safe_ascii_read(std::ifstream& fp, float &output) {
	fp >> output;
	if (!fp) {
		fp.close();
		mi_fatal("Error reading file");
	}
}
void VoxelDatasetFloat::safe_ascii_read(std::ifstream& fp, unsigned &output) {
	fp >> output;
	if (!fp) {
		fp.close();
		mi_fatal("Error reading file");
	}
}

void VoxelDatasetFloat::check_index_range(int x, int y, int z,
		std::ifstream& fp, const char* filename) {
	if (x < 0 || x >= width || y < 0 || y >= height || z < 0 || z >= depth) {
		fp.close();
		mi_fatal("Invalid voxel index %d, %d, %d when reading file %s", x, y, z,
				filename);
	}
}
