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
#include "AbsorptionSpectrum.h"

template class VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> ;
class VoxelDatasetColor: public VoxelDataset<openvdb::Vec3f, openvdb::Vec3STree> {
public:
	VoxelDatasetColor();
	VoxelDatasetColor(const miColor& background);
	enum BB_TYPE {
		BB_ONLY, BB_SOOT, BB_CHEM
	};
	virtual bool compute_black_body_emission_threaded(
			float visual_adaptation_factor, FuelType fuel_type);
	virtual bool compute_soot_absorption_threaded(
			float visual_adaptation_factor, FuelType fuel_type);
	virtual bool compute_chemical_absorption_threaded(
			float visual_adaptation_factor, FuelType fuel_type);
	const miColor& get_max_voxel_value();
	virtual void compute_max_voxel_value();
	bool isToneMapped() const;
	void setToneMapped(bool tone_mapped);

private:
	openvdb::Vec3f linear_interp(float t, const openvdb::Vec3f& c0,
			const openvdb::Vec3f& c1) const;
	void compute_function_threaded(
			void (VoxelDatasetColor::*foo)(unsigned, unsigned));
	void compute_soot_absorption(unsigned start_offset, unsigned end_offset);
	void compute_chemical_absorption(unsigned start_offset,
			unsigned end_offset);
	void compute_black_body_emission(unsigned start_offset,
			unsigned end_offset);
	void apply_visual_adaptation(float visual_adaptation_factor);
	void fix_chem_absorption();
	void fill_absorption_spec(FuelType fuel_type);
	openvdb::Coord get_maximum_voxel_index();
	static void clamp(openvdb::Vec3f& v, float min = 0, float max = 0);
	static void clamp(float &v, float min = 0, float max = 0);
	static void remove_specials(openvdb::Vec3f& v);
	static void remove_specials(float &v);
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
	std::vector<float> densities;
	std::vector<AbsorptionSpectrum> absorption_spec;

	BB_TYPE bb_type;
	bool tone_mapped;
};

#endif /* VOXELDATASETCOLOR_H_ */
