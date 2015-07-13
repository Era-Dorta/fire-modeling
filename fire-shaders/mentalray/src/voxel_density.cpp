#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetFloat.h"

struct voxel_density {
	miTag filename_tag;
	miInteger read_mode; // 0 ascii, 1 binary red, 2 binary max
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
		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z);
		break;
	}
	case DENSITY: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_get_user_memory_pointer(state);
			*result = voxels->get_fitted_voxel_value(p, min_point, max_point);
		} else {
			*result = 0.0;
		}
		break;
	}
	}
	return miTRUE;
}
