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

template class VoxelDataset<miColor> ;
class VoxelDatasetColor: public VoxelDataset<miColor> {
public:
	void compute_sigma_a_threaded();
	void compute_bb_radiation_threaded();
	miColor get_max_voxel_value();
private:
	void compute_function_threaded(
			void (VoxelDatasetColor::*foo)(unsigned, unsigned, unsigned,
					unsigned, unsigned, unsigned));
	void compute_soot_coefficients();
	void compute_sigma_a(unsigned i_width, unsigned i_height, unsigned i_depth,
			unsigned e_width, unsigned e_height, unsigned e_depth);
	void compute_bb_radiation(unsigned i_width, unsigned i_height,
			unsigned i_depth, unsigned e_width, unsigned e_height,
			unsigned e_depth);
	void normalize_bb_radiation();
	unsigned get_maximum_voxel_index();
	void compute_wavelengths();

	std::vector<miScalar> sootCoefficients;
	std::vector<float> lambdas;
	miColor max_color;
};

#endif /* VOXELDATASETCOLOR_H_ */
