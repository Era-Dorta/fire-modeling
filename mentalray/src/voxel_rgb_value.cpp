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

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width = 0, height = 0, depth = 0;

		switch (compute_mode) {
		case BB_RADIATION: {
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					temperature_shader);

			mi_info("Precomputing bb radiation with dataset size %dx%dx%d",
					width, height, depth);

			// TODO It should set the background of voxels to the black body rgb
			// of the background value of the temperature shader, and the same
			// with the density shaders
			miaux_copy_sparse_voxel_dataset(voxels, state, temperature_shader,
					width, height, depth, 1, 0);

			voxels->compute_black_body_emission_threaded(
					visual_adaptation_factor);
			mi_info("Done precomputing bb radiation with dataset size %dx%dx%d",
					width, height, depth);
			break;
		}
		case ABSORPTION: {
			miInteger fuel_type = *mi_eval_integer(&params->fuel_type);

			if (fuel_type == FuelType::BlackBody) {
				break;
			}

			std::string data_file(LIBRARY_DATA_PATH);
			assert(static_cast<unsigned>(fuel_type) < FuelTypeStr.size());

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

				data_file = data_file + "/" + FuelTypeStr[fuel_type]
						+ ".optconst";
				voxels->compute_soot_absorption_threaded(data_file.c_str());
			} else {
				miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
						temperature_shader);

				mi_info(
						"Precomputing chem absorption with dataset size %dx%dx%d",
						width, height, depth);

				miaux_copy_sparse_voxel_dataset(voxels, state,
						temperature_shader, width, height, depth, 1, 0);

				data_file = data_file + "/" + FuelTypeStr[fuel_type]
						+ ".specline";
				voxels->compute_chemical_absorption_threaded(
						visual_adaptation_factor, data_file.c_str());
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
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetColor *voxels =
					(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
			VoxelDatasetColor::Accessor accessor = voxels->get_accessor();
			openvdb::Vec3f res_vec3 = voxels->get_fitted_voxel_value(p,
					min_point, max_point, accessor);
			result->r = res_vec3.x();
			result->g = res_vec3.y();
			result->b = res_vec3.z();
		} else {
			miaux_set_rgb(result, 0);
		}
		break;
	}
	case DENSITY_CACHE: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetColor *voxels =
					(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
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
			miaux_set_rgb(result, 0);
		}
		break;
	}
	case ALLOC_CACHE: {
		// Get thread pointer
		VoxelDatasetColor::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

		if (accessor == nullptr) {
			// Allocate memory
			accessor =
					static_cast<VoxelDatasetColor::Accessor *>(mi_mem_allocate(
							sizeof(VoxelDatasetColor::Accessor)));

			// Initialise the memory
			VoxelDatasetColor *voxels =
					(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
			accessor = new (accessor) VoxelDatasetColor::Accessor(
					voxels->get_accessor());

			// Save the thread pointer
			mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);

			// Allocation success, caller is responsible of free the mem now
			result->r = 1;
		} else {
			// Memory was already allocated for this thread, caller should not
			// free the memory, as it will be by whoever allocated it before
			result->r = 0;
		}
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

		accessor->clear();

		// Ideally we would call the destructor here and free the whole memory
		// but for some reason miQ_FUNC_TLS_SET does not set the pointer to null,
		// only changes the address, so we only free the cache internal memory,
		// and let the exit function free the rest
		break;
	}
	}
	return miTRUE;
}

