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
	enum BB_TYPE {
		BB_ONLY, BB_SOOT, BB_CHEM
	};
	virtual bool compute_black_body_emission_threaded(
			float visual_adaptation_factor, BB_TYPE bb_type,
			const std::string& filename = "");
	virtual bool compute_soot_absorption_threaded(const std::string& filename);
	virtual bool compute_chemical_absorption_threaded(
			float visual_adaptation_factor, const std::string& filename);
	const miColor& get_max_voxel_value();
	virtual void compute_max_voxel_value();
	bool isToneMapped() const;
	void setToneMapped(bool tone_mapped);

private:
	openvdb::Vec3f linear_interp(float t, const openvdb::Vec3f& c0,
			const openvdb::Vec3f& c1) const;
	void compute_function_threaded(
			void (VoxelDatasetColor::*foo)(unsigned, unsigned));
	void compute_soot_constant_coefficients();
	void compute_soot_absorption(unsigned start_offset, unsigned end_offset);
	void compute_chemical_absorption(unsigned start_offset,
			unsigned end_offset);
	void compute_black_body_emission(unsigned start_offset,
			unsigned end_offset);
	void apply_visual_adaptation(float visual_adaptation_factor);
	void fix_chem_absorption();
	openvdb::Coord get_maximum_voxel_index();
	static void clamp(openvdb::Vec3f& v, float min = 0, float max = 0);
	static void clamp(float &v, float min = 0, float max = 0);
	static void remove_specials(openvdb::Vec3f& v);
	static void remove_specials(float &v);
	bool read_spectral_line_file(const std::string& filename);
	bool read_optical_constants_file(const std::string& filename);
	template<typename T>
	void safe_ascii_read(std::ifstream& fp, T &output);
	void scale_coefficients_to_custom_range();
	void clear_coefficients();

protected:
	miColor max_color;
	openvdb::Coord max_ind;
private:
	/*
	 * TODO Use separate classes to store the data
	 * Since the class will not compute chemical and soot absorption at the same
	 * time, use variable references for better naming in the code
	 */
	std::vector<float> lambdas;
	std::vector<float> phi;
	std::vector<float>& n = phi;
	std::vector<float> A21;
	std::vector<float>& nk = A21;
	std::vector<float> E1;
	std::vector<float>& soot_coef = E1;
	std::vector<float> E2;
	std::vector<int> g1;
	std::vector<int> g2;
	std::vector<float> densities;
	miScalar soot_radius;
	miScalar alpha_lambda;
	BB_TYPE bb_type;
	bool tone_mapped;
};

#endif /* VOXELDATASETCOLOR_H_ */
