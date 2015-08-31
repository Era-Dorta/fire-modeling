/*
 * VoxelDatasetFloat.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetFloat.h"

#include <fstream>
#include <algorithm>

VoxelDatasetFloat::VoxelDatasetFloat(float scale, float offset) :
		VoxelDataset<float, openvdb::FloatTree>(0) {
	this->scale = scale;
	this->offset = offset;
}

VoxelDatasetFloat::VoxelDatasetFloat(const std::string& filename, float scale,
		float offset, FILE_FORMAT file_format) :
		VoxelDataset<float, openvdb::FloatTree>(0) {
	this->scale = scale;
	this->offset = offset;
	initialize_with_file(filename, file_format);
}

bool VoxelDatasetFloat::initialize_with_file(const std::string& filename,
		FILE_FORMAT file_format) {
	switch (file_format) {
	case FILE_FORMAT::ASCII_SINGLE_VALUE: {
		return initialize_with_file_acii_single(filename);
	}
	case FILE_FORMAT::BIN_ONLY_RED: {
		return initialize_with_file_bin_only_red(filename);
	}
	case FILE_FORMAT::BIN_MAX: {
		return initialize_with_file_bin_max(filename);
	}
	case FILE_FORMAT::ASCII_UINTAH: {
		return initialize_with_file_acii_uintah(filename);
	}
	}
	return false;
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
					if (density != block->background()) {
						set_voxel_value(i, j, k, density);
					} else {
						accessor.setValueOff(openvdb::Coord(i, j, k),
								block->background());
					}
				}
			}
		}
	}
	// Free the memory in case some values were set to off
	block->pruneGrid();
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

bool VoxelDatasetFloat::initialize_with_file_acii_single(
		const std::string& filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_error("Could not open file \"%s\".", filename.c_str());
		return false;
	}

	// Read width height and depth
	unsigned width, height, depth;
	try {
		safe_ascii_read(fp, width);
		safe_ascii_read(fp, height);
		safe_ascii_read(fp, depth);

		clear();
		resize(width, height, depth);

		for (unsigned i = 0; i < width; i++) {
			for (unsigned j = 0; j < height; j++) {
				for (unsigned k = 0; k < depth; k++) {
					float read_val;
					safe_ascii_read(fp, read_val);

					// Ignore zeros
					if (read_val != 0) {
						read_val = read_val * scale + offset;
						if (read_val != block->background()) {
							accessor.setValue(openvdb::Coord(i, j, k),
									read_val);
						}
					}
				}
			}
		}

		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
}

bool VoxelDatasetFloat::initialize_with_file_acii_uintah(
		const std::string& filename) {

	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_error("Could not open file \"%s\".", filename.c_str());
		return false;
	}

	try {
		// Read width height and depth
		unsigned width, height, depth;
		safe_ascii_read(fp, width);
		safe_ascii_read(fp, height);
		safe_ascii_read(fp, depth);

		resize(width, height, depth);

		int count;
		// Number of points in the file
		safe_ascii_read(fp, count);

		float background;
		safe_ascii_read(fp, background);

		// TODO Add GUI option to ignore the background
		//block->setBackground(background * scale + offset);

		for (int i = 0; i < count; i++) {
			openvdb::Coord coord;
			safe_ascii_read(fp, coord.x());
			safe_ascii_read(fp, coord.y());
			safe_ascii_read(fp, coord.z());

			float read_val;
			safe_ascii_read(fp, read_val);

			read_val = read_val * scale + offset;
			if (read_val != block->background()) {
				accessor.setValue(coord, read_val);
			}
		}

		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
}

bool VoxelDatasetFloat::initialize_with_file_bin_only_red(
		const std::string& filename) {

	std::ifstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_error("Could not open file \"%s\".", filename.c_str());
		return false;
	}

	// Voxel is MAX_DATASET_DIMxMAX_DATASET_DIMxMAX_DATASET_DIM
	resize(MAX_DATASET_DIM, MAX_DATASET_DIM, MAX_DATASET_DIM);

	try {
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

			r = r * scale + offset;
			// For the moment assume the red component is the density
			if (r != block->background()) {
				set_voxel_value(x, y, z, r);
			}
		}

		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
}

bool VoxelDatasetFloat::initialize_with_file_bin_max(
		const std::string& filename) {
	std::ifstream fp(filename, std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		mi_error("Could not open file \"%s\".", filename.c_str());
		return false;
	}

	// Voxel is MAX_DATASET_DIMxMAX_DATASET_DIMxMAX_DATASET_DIM
	resize(MAX_DATASET_DIM, MAX_DATASET_DIM, MAX_DATASET_DIM);

	try {
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

			float max_val = std::max(std::max(r, g), b);

			max_val = max_val * scale + offset;
			// For the temperature, use the channel with maximum intensity
			if (r != block->background()) {
				set_voxel_value(x, y, z, max_val);
			}
		}

		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
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
		fp.exceptions(fp.failbit);
	}
}

template<typename T>
void VoxelDatasetFloat::safe_ascii_read(std::ifstream& fp, T &output) {
	fp >> output;
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}

void VoxelDatasetFloat::check_index_range(unsigned x, unsigned y, unsigned z,
		std::ifstream& fp, const std::string& filename) {
	if (x >= width || y >= height || z >= depth) {
		mi_error("Invalid voxel index %d, %d, %d when reading file %s", x, y, z,
				filename.c_str());
		throw std::ios_base::failure("Invalid voxel index");
	}
}
