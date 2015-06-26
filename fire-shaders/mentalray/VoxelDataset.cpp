/*
 * VoxelDataset.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDataset.h"

#include <fstream>
#include <thread>
#include <vector>

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

void VoxelDataset::compute_sigma_a_threaded() {
	// Get thread hint, i.e. number of cores
	unsigned num_threads = std::thread::hardware_concurrency();
	// Get are at least able to run one thread
	if (num_threads == 0) {
		num_threads = 1;
	}
	// Cap the number of threads if there is not enough work for each one
	if ((unsigned) (depth) < num_threads) {
		num_threads = depth;
	}
	mi_warning("\tStart computation with %d threads", num_threads);
	unsigned thread_chunk = depth / num_threads;
	std::vector<std::thread> threads;
	unsigned i_depth = 0, e_depth = thread_chunk;
	// Launch each thread with its chunk of work
	for (unsigned i = 0; i < num_threads - 1; i++) {
		threads.push_back(
				std::thread(&VoxelDataset::compute_sigma_a, this, 0, 0, i_depth,
						width, height, e_depth));
		i_depth = e_depth + 1;
		e_depth = e_depth + thread_chunk;
	}
	// The remaining will be handled by the current thread
	compute_sigma_a(0, 0, i_depth, width, height, depth - 1);
	// Wait for the other threads to finish
	for (auto& thread : threads) {
		thread.join();
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
	x = (float) fit(p->x, min_point->x, max_point->x, 0, width - 1);
	y = (float) fit(p->y, min_point->y, max_point->y, 0, height - 1);
	z = (float) fit(p->z, min_point->z, max_point->z, 0, depth - 1);
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

double VoxelDataset::fit(double v, double oldmin, double oldmax, double newmin,
		double newmax) const {
	return newmin + ((v - oldmin) / (oldmax - oldmin)) * (newmax - newmin);
}

void VoxelDataset::compute_sigma_a(unsigned i_width, unsigned i_height,
		unsigned i_depth, unsigned e_width, unsigned e_height,
		unsigned e_depth) {
	float density = 0.0;
	for (unsigned i = i_width; i <= e_width; i++) {
		for (unsigned j = i_height; j <= e_height; j++) {
			for (unsigned k = i_depth; k <= e_depth; k++) {
				density = get_voxel_value(i, j, k);
				if (density > 0.0) {
					set_voxel_value(i, j, k, density + 0.5);
				}
			}
		}
	}
}
