/*
 * VoxelDatasetColorSorted.h
 *
 *  Created on: 3 Jul 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETCOLORSORTED_H_
#define VOXELDATASETCOLORSORTED_H_

#include "VoxelDatasetColor.h"

class VoxelDatasetColorSorted: public VoxelDatasetColor {
public:
	void compute_bb_radiation_threaded();
	const miColor& get_sorted_voxel_value(unsigned index) const;
	void get_i_j_k_from_sorted(miVector &ijk, const unsigned &index) const;
private:
	void sort();
	std::array<unsigned, MAX_DATASET_SIZE> sorted_ind;
};

#endif /* VOXELDATASETCOLORSORTED_H_ */
