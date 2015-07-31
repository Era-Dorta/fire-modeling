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
	virtual void compute_black_body_emission_threaded(
			float visual_adaptation_factor) override;
	virtual void compute_soot_absorption_threaded(const char* filename)
			override;
	virtual void compute_chemical_emission_threaded(
			float visual_adaptation_factor, const char* filename) override;
	miColor get_sorted_voxel_value(unsigned index) const;
	miColor get_sorted_voxel_value(unsigned index,
			const Accessor& accessor) const;
	void get_i_j_k_from_sorted(miVector &ijk, const unsigned &index) const;
private:
	void sort();
	std::vector<openvdb::Coord> sorted_ind;
};

#endif /* VOXELDATASETCOLORSORTED_H_ */