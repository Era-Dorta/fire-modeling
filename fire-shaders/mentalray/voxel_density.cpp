#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetFloat.h"

// TODO Min and max point should come from the transformation of the object
// this material is applied to
struct voxel_density {
	miTag filename_tag;
	miInteger read_mode; // 0 ascii, 1 binary red, 2 binary max
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
			int mode = *mi_eval_integer(&params->read_mode);
			mi_warning("\tReading voxel datase mode %d, filename %s", mode,
					filename);
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_user_memory_pointer(state,
							sizeof(VoxelDatasetFloat));

			voxels->initialize_with_file(filename,
					(VoxelDatasetFloat::FILE_FORMAT) mode);

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
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_user_memory_pointer(state, 0);
		*result = voxels->getWidth();
		break;
	}
	case HEIGHT: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_user_memory_pointer(state, 0);
		*result = voxels->getHeight();
		break;
	}
	case DEPTH: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_user_memory_pointer(state, 0);
		*result = voxels->getDepth();
		break;
	}
	case DENSITY_RAW: {
		VoxelDatasetFloat *voxels =
				(VoxelDatasetFloat *) miaux_user_memory_pointer(state, 0);
		*result = voxels->get_voxel_value((unsigned) state->point.x,
				(unsigned) state->point.y, (unsigned) state->point.z);
		break;
	}
	default: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			VoxelDatasetFloat *voxels =
					(VoxelDatasetFloat *) miaux_user_memory_pointer(state, 0);
			*result = voxels->get_fitted_voxel_value(p, min_point, max_point);
		} else {
			*result = 0.0;
		}
		break;
	}
	}
	return miTRUE;
}
