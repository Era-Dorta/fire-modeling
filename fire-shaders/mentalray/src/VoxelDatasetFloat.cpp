/*
 * VoxelDatasetFloat.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetFloat.h"
#include <fstream>
#include <algorithm>

VoxelDatasetFloat::VoxelDatasetFloat() :
		VoxelDataset<float, openvdb::FloatTree>() {
}

VoxelDatasetFloat::VoxelDatasetFloat(const char* filename,
		FILE_FORMAT file_format) :
		VoxelDataset<float, openvdb::FloatTree>() {
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

void VoxelDatasetFloat::apply_sin_perturbation() {
	float density;
	float chunks_w = 20;
	const float scale_w = (chunks_w * 2.0 * M_PI) / width;
	float chunks_h = 20;
	const float scale_h = (chunks_h * 2.0 * M_PI) / height;
	for (unsigned k = 0; k < depth; k++) {
		for (unsigned j = 0; j < height; j++) {
			for (unsigned i = 0; i < width; i++) {
				density = get_voxel_value(i, j, k);
				if (density > 0) {
					density += sin(j * scale_h) + sin(i * scale_w);
					if (density < 0) {
						density = 0;
					}
					set_voxel_value(i, j, k, density);
				}
			}
		}
	}
}

float VoxelDatasetFloat::bilinear_interp(float tx, float ty, const float&c00,
		const float&c01, const float&c10, const float&c11) const {
	float c0 = linear_interp(tx, c00, c10);
	float c1 = linear_interp(tx, c01, c11);
	return linear_interp(ty, c0, c1);
}

float VoxelDatasetFloat::linear_interp(float t, const float&c0,
		const float&c1) const {
	return c0 * (1 - t) + c1 * t;
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

	for (unsigned i = 0; i < width; i++) {
		for (unsigned j = 0; j < width; j++) {
			for (unsigned k = 0; k < width; k++) {
				float read_val;
				safe_ascii_read(fp, read_val);
				accessor.setValueOn(openvdb::Coord(i, j, k), read_val);
			}
		}
	}

	fp.close();
}

void VoxelDatasetFloat::initialize_with_file_bin_only_red(
		const char* filename) {

	std::ifstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}

	// Voxel is MAX_DATASET_DIMxMAX_DATASET_DIMxMAX_DATASET_DIM
	resize(MAX_DATASET_DIM, MAX_DATASET_DIM, MAX_DATASET_DIM);

	int count;
	// Number of points in the file, integer, 4 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&count), 4);

	unsigned x, y, z;
	double r, g, b, a;

	for (int i = 0; i < count; i++) {
		// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
		read_bin_xyz(fp, x, z, y);

		// RGBA components, double, 8 bytes
		read_bin_rgba(fp, r, g, b, a);

		// Make sure the indices are in a valid range
		check_index_range(x, y, z, fp, filename);

		// For the moment assume the red component is the density
		set_voxel_value(x, y, z, r);
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

	int count;
	// Number of points in the file, integer, 4 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&count), 4);

	unsigned x, y, z;
	double r, g, b, a;

	for (int i = 0; i < count; i++) {
		// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
		read_bin_xyz(fp, x, z, y);

		// RGBA components, double, 8 bytes
		read_bin_rgba(fp, r, g, b, a);

		// Make sure the indices are in a valid range
		check_index_range(x, y, z, fp, filename);

		// For the temperature, use the channel with maximum intensity
		set_voxel_value(x, y, z, std::max(std::max(r, g), b));
	}

	fp.close();
}

void VoxelDatasetFloat::read_bin_xyz(std::ifstream& fp, unsigned& x,
		unsigned& y, unsigned& z) {
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

void VoxelDatasetFloat::check_index_range(unsigned x, unsigned y, unsigned z,
		std::ifstream& fp, const char* filename) {
	if (x >= width || y >= height || z >= depth) {
		fp.close();
		mi_fatal("Invalid voxel index %d, %d, %d when reading file %s", x, y, z,
				filename);
	}
}
