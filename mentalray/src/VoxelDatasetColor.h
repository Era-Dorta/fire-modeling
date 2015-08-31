/*
 * VoxelDatasetColor.h
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETCOLOR_H_
#define VOXELDATASETCOLOR_H_

#include <vector>
#include <fstream>

#include "VoxelDataset.h"

template class VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> ;
class VoxelDatasetColor: public VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> {
public:
	VoxelDatasetColor();
	VoxelDatasetColor(const miColor& background);
	virtual bool compute_black_body_emission_threaded(
			float visual_adaptation_factor);
	virtual bool compute_soot_absorption_threaded(const char* filename);
	virtual bool compute_chemical_absorption_threaded(
			float visual_adaptation_factor, const char* filename);
	const miColor& get_max_voxel_value();
	virtual void compute_max_voxel_value();
protected:
	virtual openvdb::Vec3f bilinear_interp(float tx, float ty,
			const openvdb::Vec3f& c00, const openvdb::Vec3f& c01,
			const openvdb::Vec3f& c10, const openvdb::Vec3f& c11) const;
	virtual openvdb::Vec3f linear_interp(float t, const openvdb::Vec3f& c0,
			const openvdb::Vec3f& c1) const;
private:
	void compute_function_threaded(
			void (VoxelDatasetColor::*foo)(unsigned, unsigned));
	void compute_soot_constant_coefficients();
	void compute_soot_absorption(unsigned start_offset, unsigned end_offset);
	void compute_chemical_absorption(unsigned start_offset,
			unsigned end_offset);
	void compute_black_body_emission(unsigned start_offset,
			unsigned end_offset);
	void normalize_bb_radiation(float visual_adaptation_factor);
	openvdb::Coord get_maximum_voxel_index();
	void fill_lambda_vector();
	static void clamp_0_1(openvdb::Vec3f& v);
	static void clamp_0_1(float &v);
	bool read_spectral_line_file(const char* filename);
	bool read_optical_constants_file(const char* filename);
	template<typename T>
	void safe_ascii_read(std::ifstream& fp, T &output);

protected:
	miColor max_color;
private:
	std::vector<float> lambdas;
	std::vector<float> input_data;
	std::vector<float> extra_data;
	miScalar soot_radius;
	miScalar alpha_lambda;
};

#endif /* VOXELDATASETCOLOR_H_ */
