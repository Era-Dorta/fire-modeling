/*
 * VoxelDataset.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASET_H_
#define VOXELDATASET_H_

#include <array>

#include "shader.h"

#define MAX_DATASET_DIM 200
#define MAX_DATASET_SIZE (MAX_DATASET_DIM * MAX_DATASET_DIM * MAX_DATASET_DIM)

template<typename T>
class VoxelDataset {
public:
	VoxelDataset();
	VoxelDataset(unsigned width, unsigned height, unsigned depth);
	VoxelDataset(const VoxelDataset &other);
	virtual ~VoxelDataset() = default;

	VoxelDataset<T>& operator=(const VoxelDataset<T> &other);

	void clear();
	void resize(unsigned width, unsigned height, unsigned depth);

	T get_voxel_value(float x, float y, float z) const;
	T get_fitted_voxel_value(const miVector *p, const miVector *min_point,
			const miVector *max_point) const;
	const T& get_voxel_value(unsigned x, unsigned y, unsigned z) const;
	void set_voxel_value(unsigned x, unsigned y, unsigned z, const T& val);

	int getWidth() const;
	int getHeight() const;
	int getDepth() const;
	int getTotal() const;
protected:
	virtual T bilinear_interp(float tx, float ty, const T&c00, const T&c01,
			const T&c10, const T&c11) const = 0;
	virtual T linear_interp(float t, const T&c0, const T&c1) const = 0;
private:
	double fit(double v, double oldmin, double oldmax, double newmin,
			double newmax) const;
protected:
	unsigned width, height, depth, count;
	std::array<T, MAX_DATASET_SIZE> block;
};

// The compiler needs direct access to the template class implementation or
// it will give symbol lookup errors. The solution is to have the code in an
// impl file and include such file in the .h
#include "VoxelDataset.impl"

#endif /* VOXELDATASET_H_ */
