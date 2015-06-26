/*
 * VoxelDataset.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDataset.h"

#include <fstream>

VoxelDataset::VoxelDataset() {
	clear();
}

VoxelDataset::VoxelDataset(unsigned width, unsigned height, unsigned depth) {
	resize(width, height, depth);
}

VoxelDataset::VoxelDataset(const VoxelDataset& other) {
	width = other.width;
	height = other.height;
	depth = other.depth;

	unsigned total = width * height * depth;
	for (unsigned i = 0; i < total; i++) {
		block[i] = other.block[i];
	}
}

VoxelDataset::VoxelDataset(const char* filename) {
	clear();
	initialize_with_file(filename);
}

VoxelDataset& VoxelDataset::VoxelDataset::operator =(
		const VoxelDataset& other) {

	if (this == &other) {
		return *this;
	}

	width = other.width;
	height = other.height;
	depth = other.depth;

	unsigned total = width * height * depth;
	for (unsigned i = 0; i < total; i++) {
		block[i] = other.block[i];
	}

	return *this;
}

void VoxelDataset::initialize_with_file(const char* filename) {
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

void VoxelDataset::clear() {
	width = 0;
	height = 0;
	depth = 0;
}

void VoxelDataset::resize(unsigned width, unsigned height, unsigned depth) {
	this->width = width;
	this->height = height;
	this->depth = depth;
	if (width * height * depth > MAX_DATASET_SIZE) {
		mi_fatal(
				"Voxel dataset, max size is %d but tried to initialise with %d",
				MAX_DATASET_SIZE, width * height * depth);
	}
}

float VoxelDataset::get_voxel_value(float x, float y, float z) const {
	return block[((int) (z + .5)) * depth * height + ((int) (y + .5)) * height
			+ ((int) (x + .5))];
}

void VoxelDataset::set_voxel_value(float x, float y, float z, float val) {
	block[((int) (z + .5)) * depth * height + ((int) (y + .5)) * height
			+ ((int) (x + .5))] = val;
}

float VoxelDataset::get_fitted_voxel_value(miVector *p, miVector *min_point,
		miVector *max_point) const {
	float x, y, z;
	x = (float) miaux_fit(p->x, min_point->x, max_point->x, 0, width - 1);
	y = (float) miaux_fit(p->y, min_point->y, max_point->y, 0, height - 1);
	z = (float) miaux_fit(p->z, min_point->z, max_point->z, 0, depth - 1);
	return get_voxel_value(x, y, z);
}

float VoxelDataset::get_voxel_value(unsigned x, unsigned y, unsigned z) const {
	return block[z * depth * height + y * height + x];
}

void VoxelDataset::set_voxel_value(unsigned x, unsigned y, unsigned z,
		float val) {
	block[z * depth * height + y * height + x] = val;
}

int VoxelDataset::getWidth() const {
	return width;
}

int VoxelDataset::getDepth() const {
	return depth;
}

int VoxelDataset::getHeight() const {
	return height;
}

double VoxelDataset::miaux_fit(double v, double oldmin, double oldmax,
		double newmin, double newmax) const {
	return newmin + ((v - oldmin) / (oldmax - oldmin)) * (newmax - newmin);
}
