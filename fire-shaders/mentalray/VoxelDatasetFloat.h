/*
 * VoxelDatasetFloat.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETFLOAT_H_
#define VOXELDATASETFLOAT_H_

#include "VoxelDataset.h"

template class VoxelDataset<float> ;
class VoxelDatasetFloat: public VoxelDataset<float> {
public:
	VoxelDatasetFloat(const char* filename);
	void initialize_with_file(const char* filename);
};

#endif /* VOXELDATASETFLOAT_H_ */
