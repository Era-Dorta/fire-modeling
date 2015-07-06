/*
 * VoxelDatasetColorSorted.cpp
 *
 *  Created on: 3 Jul 2015
 *      Author: gdp24
 */

#include <algorithm>    // std::sort

#include "VoxelDatasetColorSorted.h"

void VoxelDatasetColorSorted::compute_bb_radiation_threaded() {
	VoxelDatasetColor::compute_bb_radiation_threaded();
	sort();
}

void VoxelDatasetColorSorted::get_i_j_k_from_sorted(miVector &ijk,
		const unsigned &index) const {
	unsigned index_block = sorted_ind[index];

	ijk.x = index_block % height;
	ijk.y = ((index_block - (unsigned) ijk.x) / height) % depth;
	ijk.z = ((index_block - (unsigned) ijk.x) / height - (unsigned) ijk.y)
			/ depth;
}

void VoxelDatasetColorSorted::sort() {

	unsigned count = width * height * depth;
	// initialise original index locations
	for (unsigned i = 0; i < count; i++) {
		sorted_ind[i] = i;
	}

	// sort indexes based on comparing values in v
	//auto foo_member = std::mem_fn(&VoxelDatasetColorSorted::comp);
	std::sort(sorted_ind.begin(), sorted_ind.begin() + count - 1,
			[&](int i1, int i2) {return block[i1].r + block[i1].g +
				block[i1].b > block[i2].r + block[i2].g +
				block[i2].b;});
}

const miColor& VoxelDatasetColorSorted::get_sorted_voxel_value(
		unsigned index) const {
	return block[sorted_ind[index]];
}
