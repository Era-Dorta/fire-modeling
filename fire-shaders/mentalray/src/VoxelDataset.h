/*
 * VoxelDataset.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASET_H_
#define VOXELDATASET_H_

#include <array>
#include <functional>
#include <openvdb/openvdb.h>

#include "shader.h"

#define MAX_DATASET_DIM 200
#define MAX_DATASET_SIZE (MAX_DATASET_DIM * MAX_DATASET_DIM * MAX_DATASET_DIM)

template<typename DataT, typename TreeT>
class VoxelDataset {
public:
	enum InterpolationMode {
		TRUNCATE, TRILINEAR
	};

	VoxelDataset();
	VoxelDataset(unsigned width, unsigned height, unsigned depth);
	VoxelDataset(const VoxelDataset &other);
	virtual ~VoxelDataset() = default;

	VoxelDataset<DataT, TreeT>& operator=(
			const VoxelDataset<DataT, TreeT> &other);

	void clear();
	void resize(unsigned width, unsigned height, unsigned depth);

	DataT get_voxel_value(float x, float y, float z) const;
	DataT get_fitted_voxel_value(const miVector *p, const miVector *min_point,
			const miVector *max_point) const;
	const DataT& get_voxel_value(unsigned x, unsigned y, unsigned z) const;
	void set_voxel_value(unsigned x, unsigned y, unsigned z, const DataT& val);

	int getWidth() const;
	int getHeight() const;
	int getDepth() const;
	int getTotal() const;

	InterpolationMode getInterpolationMode() const;
	void setInterpolationMode(InterpolationMode interpolation_mode);
protected:
	virtual DataT bilinear_interp(float tx, float ty, const DataT& c00,
			const DataT& c01, const DataT& c10, const DataT& c11) const = 0;
	virtual DataT linear_interp(float t, const DataT& c0,
			const DataT& c1) const = 0;
private:
	double fit(double v, double oldmin, double oldmax, double newmin,
			double newmax) const;
	DataT trilinear_interpolation(float x, float y, float z) const;
	DataT no_interpolation(float x, float y, float z) const;
protected:
	unsigned width, height, depth, count;

	typename openvdb::Grid<TreeT>::Ptr block;
	typename openvdb::Grid<TreeT>::Accessor accessor;
private:
	InterpolationMode interpolation_mode;
	std::_Mem_fn<
			DataT (VoxelDataset<DataT, TreeT>::*)(float, float, float) const> interpolate_function;
};

// The compiler needs direct access to the template class implementation or
// it will give symbol lookup errors. The solution is to have the code in an
// impl file and include such file in the .h
#include "VoxelDataset.impl"

#endif /* VOXELDATASET_H_ */
