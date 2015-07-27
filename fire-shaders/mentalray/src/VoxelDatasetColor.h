/*
 * VoxelDatasetColor.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETCOLOR_H_
#define VOXELDATASETCOLOR_H_

#include <vector>

#include "VoxelDataset.h"

template class VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> ;
class VoxelDatasetColor: public VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> {
public:
	VoxelDatasetColor();
	virtual void compute_sigma_a_threaded();
	virtual void compute_bb_radiation_threaded(float visual_adaptation_factor);
	const miColor& get_max_voxel_value();
protected:
	virtual openvdb::Vec3f bilinear_interp(float tx, float ty,
			const openvdb::Vec3f& c00, const openvdb::Vec3f& c01,
			const openvdb::Vec3f& c10, const openvdb::Vec3f& c11) const;
	virtual openvdb::Vec3f linear_interp(float t, const openvdb::Vec3f& c0,
			const openvdb::Vec3f& c1) const;
private:
	void compute_function_threaded(
			void (VoxelDatasetColor::*foo)(unsigned, unsigned));
	void compute_soot_coefficients();
	void compute_sigma_a(unsigned start_offset, unsigned end_offset);
	void compute_bb_radiation(unsigned start_offset, unsigned end_offset);
	void normalize_bb_radiation(float visual_adaptation_factor);
	openvdb::Coord get_maximum_voxel_index();
	void compute_wavelengths();
	static void clamp_0_1(openvdb::Vec3f& v);
	static void clamp_0_1(float &v);

	std::vector<miScalar> sootCoefficients;
	std::vector<float> lambdas;
	miColor max_color;
};

#endif /* VOXELDATASETCOLOR_H_ */
