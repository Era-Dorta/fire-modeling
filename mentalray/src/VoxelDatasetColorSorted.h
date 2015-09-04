/*
 * VoxelDatasetColorSorted.h
 *
 *  Created on: 3 Jul 2015
 *      Author: gdp24
 */

#ifndef VOXELDATASETCOLORSORTED_H_
#define VOXELDATASETCOLORSORTED_H_

#include "VoxelDatasetColor.h"

class VoxelDatasetColorSorted: public VoxelDatasetColor {
public:
	VoxelDatasetColorSorted();
	VoxelDatasetColorSorted(const miColor& background);
	virtual void resize(unsigned width, unsigned height, unsigned depth)
			override;
	void sort();
	virtual bool compute_black_body_emission_threaded(
			float visual_adaptation_factor) override;
	virtual bool compute_soot_absorption_threaded(const std::string& filename)
			override;
	virtual bool compute_chemical_absorption_threaded(
			float visual_adaptation_factor, const std::string& filename)
					override;
	miColor get_sorted_voxel_value(unsigned index) const;
	miColor get_sorted_voxel_value(unsigned index,
			const Accessor& accessor) const;
	void get_i_j_k_from_sorted(miVector &ijk, const unsigned &index) const;
	virtual void compute_max_voxel_value() override;
	virtual unsigned getTotal() const override;
	openvdb::Vec3SGrid::ValueOnIter get_on_values_iter() const;
	float get_inv_width_1_by_2() const;
private:
	void set_inv_width_1_by_2();
private:
	std::vector<openvdb::Coord> sorted_ind;
	float inv_width_1_by_2;
};

#endif /* VOXELDATASETCOLORSORTED_H_ */
