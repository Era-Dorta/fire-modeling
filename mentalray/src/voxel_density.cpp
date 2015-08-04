#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetFloat.h"

struct voxel_density {
	miTag filename_tag;
	miInteger read_mode; // 0 ascii, 1 binary red, 2 binary max, 3 ascii unintah
	miInteger interpolation_mode; // 0 none, 1 trilinear
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
		const char* filename = miaux_tag_to_string(
				*mi_eval_tag(&params->filename_tag),
				NULL);

		miInteger interpolation_mode = *mi_eval_integer(
				&params->interpolation_mode);

		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_alloc_user_memory(state,
						sizeof(VoxelDatasetFloat));

		// Placement new, initialisation of malloc memory block
		voxels = new (voxels) VoxelDatasetFloat();

		voxels->setInterpolationMode(
				(VoxelDatasetFloat::InterpolationMode) interpolation_mode);

		if (filename) {
			int mode = *mi_eval_integer(&params->read_mode);
			mi_info("\tReading voxel datase mode %d, filename %s", mode,
					filename);
			voxels->initialize_with_file(filename,
					(VoxelDatasetFloat::FILE_FORMAT) mode);

			//voxels->apply_sin_perturbation();

			mi_info("\tDone with Voxel dataset: %dx%dx%d %s",
					voxels->getWidth(), voxels->getHeight(), voxels->getDepth(),
					filename);
		} else {
			mi_fatal("Voxel density needs a filename, current is %s", filename);
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
	case DENSITY_RAW: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		VoxelDatasetFloat::Accessor accessor = voxels->get_accessor();
		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z, accessor);
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

		// Allocate memory
		accessor = static_cast<VoxelDatasetFloat::Accessor *>(mi_mem_allocate(
				sizeof(VoxelDatasetFloat::Accessor)));

		// Initialise the memory
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
		accessor = new (accessor) VoxelDatasetFloat::Accessor(
				voxels->get_accessor());

		// Save the thread pointer
		mi_query(miQ_FUNC_TLS_SET, state, miNULLTAG, &accessor);

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
