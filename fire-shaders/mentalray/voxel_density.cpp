#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDataset.h"

// TODO Min and max point should come from the transformation of the object
// this material is applied to
struct voxel_density {
	miTag filename_tag;
	miVector min_point;
	miVector max_point;
	miColor color;
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
		char* filename = miaux_tag_to_string(
				*mi_eval_tag(&params->filename_tag),
				NULL);
		if (filename) {
			mi_warning("\tReading voxel datase filename %s", filename);
			VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(
					state, sizeof(VoxelDataset));

			voxels->initialize_with_file(filename);

			mi_warning("\tDone with Voxel dataset: %dx%dx%d %s",
					voxels->getWidth(), voxels->getHeight(), voxels->getDepth(),
					filename);
		}
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean voxel_density_exit(miState *state,
		void *params) {
	return miaux_release_user_memory("voxel_density", state, params);
}

extern "C" DLLEXPORT miBoolean voxel_density(miScalar *result, miState *state,
		struct voxel_density *params) {
	switch ((Voxel_Return) state->type) {
	case WIDTH: {
		VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(state,
				0);
		*result = voxels->getWidth();
		break;
	}
	case HEIGHT: {
		VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(state,
				0);
		*result = voxels->getHeight();
		break;
	}
	case DEPTH: {
		VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(state,
				0);
		*result = voxels->getDepth();
		break;
	}
	case DENSITY_RAW: {
		VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(state,
				0);
		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z);
		break;
	}
	default: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDataset *voxels = (VoxelDataset *) miaux_user_memory_pointer(
					state, 0);
			*result = voxels->get_fitted_voxel_value(p, min_point, max_point);
		} else {
			*result = 0.0;
		}
		break;
	}
	}
	return miTRUE;
}
