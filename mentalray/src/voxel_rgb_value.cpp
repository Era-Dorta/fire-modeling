/*
 * voxel_rgb_value.cpp
 *
 *  Created on: 19 Aug 2015
 *      Author: gdp24
 */

#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "FuelTypes.h"
#include "miaux.h"
#include "VoxelDatasetColor.h"

struct voxel_rgb_value {
	miTag temperature_shader;
	miTag density_shader;

	// 0 black body radiation, 1 absorption
	miInteger compute_mode;

	miInteger interpolation_mode; // 0 none, 1 trilinear
	miScalar visual_adaptation_factor;
	miInteger fuel_type;

	miVector min_point;
	miVector max_point;
};

enum ComputeMode {
	BB_RADIATION, ABSORPTION
};

extern "C" DLLEXPORT int voxel_rgb_value_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean voxel_rgb_value_init(miState *state,
		struct voxel_rgb_value *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
		miaux_initialize_external_libs();
	} else {
		/* Instance initialization: */
		miTag temperature_shader = *mi_eval_tag(&params->temperature_shader);

		ComputeMode compute_mode = static_cast<ComputeMode>(*mi_eval_integer(
				&params->compute_mode));
		miInteger interpolation_mode = *mi_eval_integer(
				&params->interpolation_mode);
		miScalar visual_adaptation_factor = *mi_eval_scalar(
				&params->visual_adaptation_factor);

		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_alloc_user_memory(state,
						sizeof(VoxelDatasetColor));

		// Placement new, initialisation of malloc memory block
		voxels = new (voxels) VoxelDatasetColor();

		voxels->setInterpolationMode(
				(VoxelDatasetColor::InterpolationMode) interpolation_mode);

		// Get the data file path
		miInteger fuel_type = *mi_eval_integer(&params->fuel_type);
		VoxelDatasetColor::BB_TYPE bb_type = VoxelDatasetColor::BB_ONLY;
		std::string data_file;
		if (fuel_type != FuelType::BlackBody) {
			data_file = LIBRARY_DATA_PATH;
			assert(static_cast<unsigned>(fuel_type) < FuelTypeStr.size());
			if (fuel_type <= FuelType::SootMax) {
				data_file += "/" + FuelTypeStr[fuel_type] + ".optconst";
				bb_type = VoxelDatasetColor::BB_SOOT;
			} else {
				data_file += "/" + FuelTypeStr[fuel_type] + ".specline";
				bb_type = VoxelDatasetColor::BB_CHEM;
			}
		}

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width = 0, height = 0, depth = 0;

		switch (compute_mode) {
		case BB_RADIATION: {
			miTag density_shader = *mi_eval_tag(&params->density_shader);
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					temperature_shader);

			mi_info("Precomputing bb radiation with dataset size %dx%dx%d",
					width, height, depth);

			/*
			 * Copy the temperatures in the y dimension and the densities on the
			 * x, so we can compute the values in the VoxelDataset class
			 */
			miaux_copy_sparse_voxel_dataset(voxels, state, density_shader,
					temperature_shader, width, height, depth);

			if (!voxels->compute_black_body_emission_threaded(
					visual_adaptation_factor, bb_type, data_file)) {
				// If there was an error clear all for early exit
				voxels->clear();
			}
			mi_info("Done precomputing bb radiation with dataset size %dx%dx%d",
					width, height, depth);
			break;
		}
		case ABSORPTION: {
			if (fuel_type == FuelType::BlackBody) {
				break;
			}

			// Soot absorption
			if (fuel_type <= FuelType::SootMax) {
				miTag density_shader = *mi_eval_tag(&params->density_shader);

				miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
						density_shader);

				mi_info(
						"Precomputing soot absorption with dataset size %dx%dx%d",
						width, height, depth);

				miaux_copy_sparse_voxel_dataset(voxels, state, density_shader,
						width, height, depth, 1, 0);

				if (!voxels->compute_soot_absorption_threaded(data_file)) {
					// If there was an error clear all for early exit
					voxels->clear();
				}
			} else {
				miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
						temperature_shader);

				mi_info(
						"Precomputing chem absorption with dataset size %dx%dx%d",
						width, height, depth);

				miaux_copy_sparse_voxel_dataset(voxels, state,
						temperature_shader, width, height, depth, 1, 0);

				if (!voxels->compute_chemical_absorption_threaded(
						visual_adaptation_factor, data_file)) {
					// If there was an error clear all for early exit
					voxels->clear();
				}
			}
			mi_info("Done precomputing absorption with dataset size %dx%dx%d",
					width, height, depth);
			break;
		}
		}

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean voxel_rgb_value_exit(miState *state,
		void *params) {
	if (params != NULL) {
		// Call the destructor manually because we had to use placement new
		void *user_pointer = miaux_get_user_memory_pointer(state);
		((VoxelDatasetColor *) user_pointer)->~VoxelDatasetColor();
		mi_mem_release(user_pointer);

		VoxelDatasetColor::Accessor **accessors = nullptr;
		int num = 0;
		// Delete all the accessor variables that were allocated during run time
		mi_query(miQ_FUNC_TLS_GETALL, state, miNULLTAG, &accessors, &num);
		for (int i = 0; i < num; i++) {
			accessors[i]->~ValueAccessor();
			mi_mem_release(accessors[i]);
		}
	}
	return miTRUE;
}

// As we need to modify the pointers, the input are references to pointers
void get_stored_data(VoxelDatasetColor*& voxels,
		VoxelDatasetColor::Accessor*& accessor, miState *state) {

	voxels = (VoxelDatasetColor *) miaux_get_user_memory_pointer(state);

	accessor = nullptr;
	mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

	if (accessor != nullptr) {
		return;
	}

	// Allocate memory
	accessor = static_cast<VoxelDatasetColor::Accessor *>(mi_mem_allocate(
			sizeof(VoxelDatasetColor::Accessor)));

	// Initialise the memory
	accessor = new (accessor) VoxelDatasetColor::Accessor(
			voxels->get_accessor());

	// Save the thread pointer
	mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);

}

extern "C" DLLEXPORT miBoolean voxel_rgb_value(miColor *result, miState *state,
		struct voxel_rgb_value *params) {

	switch ((Voxel_Return) state->type) {
	case WIDTH: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		result->r = voxels->getWidth();
		break;
	}
	case HEIGHT: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		result->r = voxels->getHeight();
		break;
	}
	case DEPTH: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		result->r = voxels->getDepth();
		break;
	}
	case BACKGROUND: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		openvdb::Vec3f res_vec3 = voxels->getBackground();
		result->r = res_vec3.x();
		result->g = res_vec3.y();
		result->b = res_vec3.z();
		break;
	}
	case VOXEL_DATA_COPY: {
		VoxelDatasetColor *voxels = nullptr;
		VoxelDatasetColor::Accessor *accessor = nullptr;
		get_stored_data(voxels, accessor, state);

		openvdb::Vec3f res_vec3 = voxels->get_voxel_value(
				(unsigned) state->point.x, (unsigned) state->point.y,
				(unsigned) state->point.z, *accessor);
		result->r = res_vec3.x();
		result->g = res_vec3.y();
		result->b = res_vec3.z();

		break;
	}
	case VOXEL_DATA: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetColor *voxels = nullptr;
			VoxelDatasetColor::Accessor *accessor = nullptr;
			get_stored_data(voxels, accessor, state);

			openvdb::Vec3f res_vec3 = voxels->get_fitted_voxel_value(p,
					min_point, max_point, *accessor);
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		} else {
			miaux_set_rgb(result, 0);
		}
		break;
	}
	}
	return miTRUE;
}

