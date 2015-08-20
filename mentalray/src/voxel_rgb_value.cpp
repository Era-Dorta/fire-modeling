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
		miInteger fuel_type = *mi_eval_integer(&params->fuel_type);

		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_alloc_user_memory(state,
						sizeof(VoxelDatasetColor));

		// Placement new, initialisation of malloc memory block
		voxels = new (voxels) VoxelDatasetColor();

		voxels->setInterpolationMode(
				(VoxelDatasetColor::InterpolationMode) interpolation_mode);

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width = 0, height = 0, depth = 0;

		switch (compute_mode) {
		case BB_RADIATION: {
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					temperature_shader);

			// TODO It should set the background of voxels to the black body rgb
			// of the background value of the temperature shader, and the same
			// with the density shaders
			miaux_copy_sparse_voxel_dataset(voxels, state, temperature_shader,
					width, height, depth, 1, 0);

			voxels->compute_black_body_emission_threaded(
					visual_adaptation_factor);
			break;
		}
		case ABSORPTION: {
			if (fuel_type == BlackBody) {
				break;
			}

			std::string data_file(LIBRARY_DATA_PATH);
			assert(static_cast<unsigned>(fuel_type) < FuelTypeStr.size());

			// Soot absorption
			if (fuel_type <= SootMax) {
				miTag density_shader = *mi_eval_tag(&params->density_shader);

				miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
						density_shader);

				miaux_copy_sparse_voxel_dataset(voxels, state, density_shader,
						width, height, depth, 1, 0);

				data_file = data_file + "/" + FuelTypeStr[fuel_type]
						+ ".optconst";
				voxels->compute_soot_absorption_threaded(data_file.c_str());
			} else {
				miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
						temperature_shader);

				miaux_copy_sparse_voxel_dataset(voxels, state,
						temperature_shader, width, height, depth, 1, 0);

				data_file = data_file + "/" + FuelTypeStr[fuel_type]
						+ ".specline";
				voxels->compute_chemical_absorption_threaded(
						visual_adaptation_factor, data_file.c_str());
			}
			break;
		}
		}

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
		mi_info("Done precomputing bb radiation with dataset size %dx%dx%d",
				width, height, depth);
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
	}
	return miTRUE;
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
	case DENSITY_RAW: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		VoxelDatasetColor::Accessor accessor = voxels->get_accessor();
		openvdb::Vec3f res_vec3 = voxels->get_voxel_value(
				(unsigned) state->point.x, (unsigned) state->point.y,
				(unsigned) state->point.z, accessor);
		result->r = res_vec3.x();
		result->g = res_vec3.y();
		result->b = res_vec3.z();
		break;
	}
	case DENSITY_RAW_CACHE: {
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		VoxelDatasetColor::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

		assert(accessor != nullptr);
		openvdb::Vec3f res_vec3 = voxels->get_voxel_value(
				(unsigned) state->point.x, (unsigned) state->point.y,
				(unsigned) state->point.z, *accessor);
		result->r = res_vec3.x();
		result->g = res_vec3.y();
		result->b = res_vec3.z();

		break;
	}
	case DENSITY: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetColor::Accessor accessor = voxels->get_accessor();
			openvdb::Vec3f res_vec3 = voxels->get_fitted_voxel_value(p,
					min_point, max_point, accessor);
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		} else {
			openvdb::Vec3f res_vec3 = voxels->getBackground();
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		}
		break;
	}
	case DENSITY_CACHE: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		if (miaux_point_inside(p, min_point, max_point)) {
			// Get previously allocated accessor
			VoxelDatasetColor::Accessor *accessor = nullptr;
			mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

			assert(accessor != nullptr);

			openvdb::Vec3f res_vec3 = voxels->get_fitted_voxel_value(p,
					min_point, max_point, *accessor);
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		} else {
			openvdb::Vec3f res_vec3 = voxels->getBackground();
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		}
		break;
	}
	case ALLOC_CACHE: {
		// Get thread pointer
		VoxelDatasetColor::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

		// Allocate memory
		accessor = static_cast<VoxelDatasetColor::Accessor *>(mi_mem_allocate(
				sizeof(VoxelDatasetColor::Accessor)));

		// Initialise the memory
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		accessor = new (accessor) VoxelDatasetColor::Accessor(
				voxels->get_accessor());

		// Save the thread pointer
		mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);

		break;
	}
	case FREE_CACHE: {
		// Get thread pointer
		VoxelDatasetColor::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);
		if (accessor == nullptr) {
			mi_warning(
					"Tried to free accessor but not memory found, possible\
					memory leak");
			break;
		}

		// Call destructor manually because we used placement new
		accessor->~ValueAccessor();
		mi_mem_release(accessor);

		// For some reason miQ_FUNC_TLS_SET does not set the pointer to null,
		// only changes the address, so we will have to trust that the user
		// will call alloc and free responsibly
		accessor = nullptr;
		mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);
		break;
	}
	}
	return miTRUE;
}

