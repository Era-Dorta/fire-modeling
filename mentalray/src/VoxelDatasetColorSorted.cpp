/*
 * VoxelDatasetColorSorted.cpp
 *
 *  Created on: 3 Jul 2015
 *      Author: gdp24
 */

#include <algorithm>    // std::sort

#include "VoxelDatasetColorSorted.h"

VoxelDatasetColorSorted::VoxelDatasetColorSorted() :
		VoxelDatasetColor() {
	sample_step = 0;
	set_inv_width_1_by_2();
}

VoxelDatasetColorSorted::VoxelDatasetColorSorted(const miColor& background) :
		VoxelDatasetColor(background) {
	sample_step = 0;
	set_inv_width_1_by_2();
}

void VoxelDatasetColorSorted::resize(unsigned width, unsigned height,
		unsigned depth) {
	VoxelDatasetColor::resize(width, height, depth);
	set_inv_width_1_by_2();
}

bool VoxelDatasetColorSorted::compute_soot_absorption_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {
	if (!VoxelDatasetColor::compute_soot_absorption_threaded(
			visual_adaptation_factor, fuel_type)) {
		return false;
	}
	sort();
	return true;
}

bool VoxelDatasetColorSorted::compute_black_body_emission_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {
	if (!VoxelDatasetColor::compute_black_body_emission_threaded(
			visual_adaptation_factor, fuel_type)) {
		return false;
	}
	sort();
	return true;
}

bool VoxelDatasetColorSorted::compute_chemical_absorption_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {
	if (!VoxelDatasetColor::compute_chemical_absorption_threaded(
			visual_adaptation_factor, fuel_type)) {
		return false;
	}
	sort();
	return true;
}

void VoxelDatasetColorSorted::get_i_j_k_from_sorted(miVector &ijk,
		const unsigned &index) const {
	assert(index < sorted_ind.size());
	ijk.x = sorted_ind[index].x();
	ijk.y = sorted_ind[index].y();
	ijk.z = sorted_ind[index].z();
}

void VoxelDatasetColorSorted::sort() {
	// If there are no active voxels, initialise to 0,0,0
	if (block->activeVoxelCount() == 0) {
		sorted_ind.resize(1);
		sorted_ind[0] = openvdb::Coord();
		mi_warning("Maximum value in voxel dataset is background, check scale");
		return;
	}

	// initialise original index locations
	sorted_ind.resize(block->activeVoxelCount());
	unsigned i = 0;
	for (openvdb::Vec3SGrid::ValueOnCIter iter = block->cbeginValueOn(); iter;
			++iter) {
		sorted_ind[i] = iter.getCoord();
		i++;
	}

	// sort indexes based on comparing values in v
	//auto foo_member = std::mem_fn(&VoxelDatasetColorSorted::comp);
	std::sort(sorted_ind.begin(), sorted_ind.end(),
			[&](const openvdb::Coord& i1, const openvdb::Coord& i2) {
				return accessor.getValue(i1).x() + accessor.getValue(i1).y() +
				accessor.getValue(i1).z() > accessor.getValue(i2).x() +
				accessor.getValue(i2).y() + accessor.getValue(i2).z();});
}

miColor VoxelDatasetColorSorted::get_sorted_voxel_value(unsigned index) const {
	return get_sorted_voxel_value(index, accessor);
}

miColor VoxelDatasetColorSorted::get_sorted_voxel_value(unsigned index,
		const Accessor& accessor) const {
	miColor res;
	assert(index < sorted_ind.size());
	res.r = accessor.getValue(sorted_ind[index]).x();
	res.g = accessor.getValue(sorted_ind[index]).y();
	res.b = accessor.getValue(sorted_ind[index]).z();
	return res;
}

void VoxelDatasetColorSorted::compute_max_voxel_value() {
	assert(0 < sorted_ind.size());
	max_color.r = accessor.getValue(sorted_ind[0]).x();
	max_color.g = accessor.getValue(sorted_ind[0]).y();
	max_color.b = accessor.getValue(sorted_ind[0]).z();
}

unsigned VoxelDatasetColorSorted::getTotal() const {
	return sorted_ind.size();
}

openvdb::Vec3SGrid::ValueOnIter VoxelDatasetColorSorted::get_on_values_iter() const {
	return block->beginValueOn();
}

float VoxelDatasetColorSorted::get_inv_width_1_by_2() const {
	return inv_width_1_by_2;
}

void VoxelDatasetColorSorted::set_inv_width_1_by_2() {
	if (width > 0) {
		inv_width_1_by_2 = (1.0 / (width - 1.0)) * 2;
	} else {
		inv_width_1_by_2 = 0;
	}
}

void VoxelDatasetColorSorted::compute_sample_step(unsigned high_samples) {
	if (high_samples > 0) {
		if (getTotal() > high_samples) {
			sample_step = getTotal() / high_samples;
		} else {
			// If there are not enough voxel samples, set it to 1
			sample_step = 1;
		}

	} else {
		sample_step = 0;
	}
}

unsigned VoxelDatasetColorSorted::get_sample_step() const {
	return sample_step;
}
