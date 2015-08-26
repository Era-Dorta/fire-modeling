#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetFloat.h"

struct voxel_density {
	miTag filename;
	miInteger read_mode; // 0 ascii, 1 binary red, 2 binary max, 3 ascii unintah
	miInteger interpolation_mode; // 0 none, 1 trilinear
	miScalar scale;
	miScalar offset;
	miVector min_point;
	miVector max_point;
};

extern "C" DLLEXPORT int voxel_density_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean voxel_density_init(miState *state,
		struct voxel_density *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
		miaux_initialize_external_libs();
	} else {
		/* Instance initialization: */
		std::string filename;
		miaux_tag_to_string(filename, *mi_eval_tag(&params->filename));
		miScalar scale = *mi_eval_scalar(&params->scale);
		miScalar offset = *mi_eval_scalar(&params->offset);

		miInteger interpolation_mode = *mi_eval_integer(
				&params->interpolation_mode);

		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_alloc_user_memory(state,
						sizeof(VoxelDatasetFloat));

		// Placement new, initialisation of malloc memory block
		voxels = new (voxels) VoxelDatasetFloat(scale, offset);

		voxels->setInterpolationMode(
				(VoxelDatasetFloat::InterpolationMode) interpolation_mode);

		if (!filename.empty()) {
			int mode = *mi_eval_integer(&params->read_mode);
			mi_info("\tReading voxel datase mode %d, filename %s", mode,
					filename.c_str());
			voxels->initialize_with_file(filename,
					(VoxelDatasetFloat::FILE_FORMAT) mode);

			//voxels->apply_sin_perturbation();

			mi_info("\tDone reading voxel dataset: %dx%dx%d %s",
					voxels->getWidth(), voxels->getHeight(), voxels->getDepth(),
					filename.c_str());
		} else {
			mi_fatal("Voxel density needs a filename, current is %s",
					filename.c_str());
		}
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean voxel_density_exit(miState *state,
		void *params) {
	if (params != NULL) {
		// Call the destructor manually because we had to use placement new
		void *user_pointer = miaux_get_user_memory_pointer(state);
		((VoxelDatasetFloat *) user_pointer)->~VoxelDatasetFloat();
		mi_mem_release(user_pointer);

		VoxelDatasetFloat::Accessor **accessors = nullptr;
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

extern "C" DLLEXPORT miBoolean voxel_density(miScalar *result, miState *state,
		struct voxel_density *params) {

	switch ((Voxel_Return) state->type) {
	case WIDTH: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		*result = voxels->getWidth();
		break;
	}
	case HEIGHT: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		*result = voxels->getHeight();
		break;
	}
	case DEPTH: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		*result = voxels->getDepth();
		break;
	}
	case BACKGROUND: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		*result = voxels->getBackground();
		break;
	}
	case DENSITY_RAW: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		VoxelDatasetFloat::Accessor accessor = voxels->get_accessor();
		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z, accessor);
		break;
	}
	case DENSITY_RAW_CACHE: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		// Get previously allocated accessor
		VoxelDatasetFloat::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

		assert(accessor != nullptr);

		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z,
				*accessor);
		break;
	}
	case DENSITY: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
			VoxelDatasetFloat::Accessor accessor = voxels->get_accessor();
			*result = voxels->get_fitted_voxel_value(p, min_point, max_point,
					accessor);
		} else {
			*result = 0.0;
		}
		break;
	}
	case DENSITY_CACHE: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);

			// Get previously allocated accessor
			VoxelDatasetFloat::Accessor *accessor = nullptr;
			mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

			assert(accessor != nullptr);

			*result = voxels->get_fitted_voxel_value(p, min_point, max_point,
					*accessor);
		} else {
			*result = 0.0;
		}
		break;
	}
	case ALLOC_CACHE: {
		// Get thread pointer
		VoxelDatasetFloat::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);

		if (accessor == nullptr) {
			// Allocate memory
			accessor =
					static_cast<VoxelDatasetFloat::Accessor *>(mi_mem_allocate(
							sizeof(VoxelDatasetFloat::Accessor)));

			// Initialise the memory
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
			accessor = new (accessor) VoxelDatasetFloat::Accessor(
					voxels->get_accessor());

			// Save the thread pointer
			mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);
			*result = 1;
		} else {
			*result = 0;
		}
		break;
	}
	case FREE_CACHE: {
		// Get thread pointer
		VoxelDatasetFloat::Accessor *accessor = nullptr;
		mi_query(miQ_FUNC_TLS_GET, state, miNULLTAG, &accessor);
		if (accessor == nullptr) {
			mi_warning(
					"Tried to free accessor but not memory found, possible\
					memory leak");
			break;
		}

		accessor->clear();

		// See comments on voxel_rgb_value FREE_CACHE
		break;
	}
	}
	return miTRUE;
}
