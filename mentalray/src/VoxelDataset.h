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

template<typename DataT, typename TreeT>
class VoxelDataset {
public:
	enum InterpolationMode {
		TRUNCATE, TRILINEAR, TRIQUADRATIC
	};

	typedef typename openvdb::Grid<TreeT>::Accessor Accessor;

	VoxelDataset(const DataT& background);
	VoxelDataset(unsigned width, unsigned height, unsigned depth,
			const DataT& background);
	VoxelDataset(const VoxelDataset &other);
	virtual ~VoxelDataset() = default;

	VoxelDataset<DataT, TreeT>& operator=(
			const VoxelDataset<DataT, TreeT> &other);

	void clear();
	virtual void resize(unsigned width, unsigned height, unsigned depth);
	float getMemFootPrint() const;
	void pre_cach_all();
	Accessor get_accessor() const;

	DataT get_voxel_value(float x, float y, float z) const;
	DataT get_voxel_value(float x, float y, float z,
			const Accessor& accessor) const;
	DataT get_fitted_voxel_value(const miVector *p, const miVector *min_point,
			const miVector *max_point) const;
	DataT get_fitted_voxel_value(const miVector *p, const miVector *min_point,
			const miVector *max_point, const Accessor& accessor) const;
	const DataT& get_voxel_value(unsigned x, unsigned y, unsigned z) const;
	const DataT& get_voxel_value(unsigned x, unsigned y, unsigned z,
			const Accessor& accessor) const;
	void set_voxel_value(unsigned x, unsigned y, unsigned z, const DataT& val);

	int getWidth() const;
	int getHeight() const;
	int getDepth() const;
	virtual unsigned getTotal() const;
	const DataT& getBackground() const;

	InterpolationMode getInterpolationMode() const;
	void setInterpolationMode(InterpolationMode interpolation_mode);
protected:
	double fit(double v, double oldmin, double oldmax, double newmin,
			double newmax) const;
private:
	DataT trilinear_interpolation(float x, float y, float z,
			const Accessor& accessor) const;
	DataT triquadratic_interpolation(float x, float y, float z,
			const Accessor& accessor) const;
	DataT no_interpolation(float x, float y, float z,
			const Accessor& accessor) const;
protected:
	unsigned width, height, depth, count;

	typename openvdb::Grid<TreeT>::Ptr block;
	typename openvdb::Grid<TreeT>::Accessor accessor;
private:
	InterpolationMode interpolation_mode;
	std::function<
			DataT(const VoxelDataset<DataT, TreeT>&, float, float, float,
					const Accessor&)> interpolate_function;
};

// The compiler needs direct access to the template class implementation or
// it will give symbol lookup errors. The solution is to have the code in an
// impl file and include such file in the .h
#include "VoxelDataset.impl"

#endif /* VOXELDATASET_H_ */
