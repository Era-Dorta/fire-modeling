/*
 * VoxelDataset.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASET_H_
#define VOXELDATASET_H_

#include "shader.h"

#define MAX_DATASET_SIZE 128*128*128

class VoxelDataset {
public:
	VoxelDataset();
	VoxelDataset(unsigned width, unsigned height, unsigned depth);
	VoxelDataset(const VoxelDataset &other);
	VoxelDataset(const char* filename);

	VoxelDataset& operator=(const VoxelDataset &other);

	void initialize_with_file(const char* filename);

	void clear();
	void resize(unsigned width, unsigned height, unsigned depth);

	void compute_sigma_a_threaded();

	float get_voxel_value(float x, float y, float z) const;
	void set_voxel_value(float x, float y, float z, float val);
	float get_fitted_voxel_value(miVector *p, miVector *min_point,
			miVector *max_point) const;
	float get_voxel_value(unsigned x, unsigned y, unsigned z) const;
	void set_voxel_value(unsigned x, unsigned y, unsigned z, float val);

	int getWidth() const;
	int getHeight() const;
	int getDepth() const;
private:
	double fit(double v, double oldmin, double oldmax, double newmin,
			double newmax) const;
	void compute_sigma_a(unsigned i_width, unsigned i_height, unsigned i_depth,
			unsigned e_width, unsigned e_height, unsigned e_depth);
private:
	unsigned width, height, depth;
	float block[MAX_DATASET_SIZE];
};

#endif /* VOXELDATASET_H_ */
