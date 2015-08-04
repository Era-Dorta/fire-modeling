/*
 * VoxelDatasetFloat.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETFLOAT_H_
#define VOXELDATASETFLOAT_H_

#include <fstream>

#include "VoxelDataset.h"

template class VoxelDataset<float, openvdb::FloatTree> ;
class VoxelDatasetFloat: public VoxelDataset<float, openvdb::FloatTree> {
public:
	enum FILE_FORMAT {
		ASCII_SINGLE_VALUE, BIN_ONLY_RED, BIN_MAX, ASCII_UINTAH
	};

	VoxelDatasetFloat();
	VoxelDatasetFloat(const char* filename, FILE_FORMAT file_format =
			BIN_ONLY_RED);
	void initialize_with_file(const char* filename, FILE_FORMAT file_format =
			BIN_ONLY_RED);
	void apply_sin_perturbation();
protected:
	virtual float bilinear_interp(float tx, float ty, const float& c00,
			const float& c01, const float& c10, const float& c11) const;
	virtual float linear_interp(float t, const float& c0,
			const float& c1) const;
private:
	void initialize_with_file_acii_single(const char* filename);
	void initialize_with_file_acii_uintah(const char* filename);
	void initialize_with_file_bin_only_red(const char* filename);
	void initialize_with_file_bin_max(const char* filename);
	void read_bin_xyz(std::ifstream& fp, unsigned& x, unsigned& y, unsigned& z);
	void read_bin_rgba(std::ifstream& fp, double& r, double& g, double& b,
			double& a);
	void safe_binary_read(std::ifstream& fp, char *output, long int byte_size);
	template<typename T>
	void safe_ascii_read(std::ifstream& fp, T &output);
	void check_index_range(unsigned x, unsigned y, unsigned z,
			std::ifstream& fp, const char* filename);
	float bilinear_interp(float tx, float ty, float c00, float c01, float c10,
			float c11) const;
};

#endif /* VOXELDATASETFLOAT_H_ */
