/*
 * VoxelDatasetColor.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETCOLOR_H_
#define VOXELDATASETCOLOR_H_

#include "VoxelDataset.h"

template class VoxelDataset<miColor> ;
class VoxelDatasetColor: public VoxelDataset<miColor> {
public:
	void compute_sigma_a_threaded();
private:
	void compute_sigma_a(unsigned i_width, unsigned i_height, unsigned i_depth,
			unsigned e_width, unsigned e_height, unsigned e_depth);
};

#endif /* VOXELDATASETCOLOR_H_ */
