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
	void sort();
	const miColor& get_sorted_voxel_value(unsigned index) const;
private:
	std::array<unsigned, MAX_DATASET_SIZE> sorted_ind;
};

#endif /* VOXELDATASETCOLORSORTED_H_ */
