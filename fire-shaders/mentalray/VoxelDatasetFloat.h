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
	enum FILE_FORMAT {
		ASCII_SINGLE_VALUE, BIN_ONLY_RED, BIN_MAX
	};

	VoxelDatasetFloat(const char* filename, FILE_FORMAT file_format =
			BIN_ONLY_RED);
	void initialize_with_file(const char* filename, FILE_FORMAT file_format =
			BIN_ONLY_RED);
private:
	void initialize_with_file_acii_single(const char* filename);
	void initialize_with_file_bin_only_red(const char* filename);
	void initialize_with_file_bin_max(const char* filename);
};

#endif /* VOXELDATASETFLOAT_H_ */
