#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"

float voxel_value(voxel_data *voxels, float x, float y, float z) {
	return voxels->block[((int) (z + .5)) * voxels->depth * voxels->height
			+ ((int) (y + .5)) * voxels->height + ((int) (x + .5))];
}

float voxel_value_raw(voxel_data *voxels, float x, float y, float z) {
	return voxels->block[((int) z) * voxels->depth * voxels->height
			+ ((int) y) * voxels->height + ((int) x)];
}

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
			voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state,
					sizeof(voxel_data));
			miaux_read_volume_block(filename, &voxels->width, &voxels->height,
					&voxels->depth, voxels->block);
			mi_warning("\tDone with Voxel dataset: %dx%dx%d %s", voxels->width,
					voxels->height, voxels->depth, filename);
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
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state, 0);
		*result = voxels->width;
		break;
	}
	case HEIGHT: {
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state, 0);
		*result = voxels->height;
		break;
	}
	case DEPTH: {
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state, 0);
		*result = voxels->depth;
		break;
	}
	case DENSITY_RAW: {
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state, 0);
		*result = voxel_value_raw(voxels, state->point.x, state->point.y,
				state->point.z);
		break;
	}
	default: {
		miVector *min_point = mi_eval_vector(&params->min_point);
		miVector *max_point = mi_eval_vector(&params->max_point);
		miVector *p = &state->point;
		if (miaux_point_inside(p, min_point, max_point)) {
			float x, y, z;
			voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state,
					0);
			x = (float) miaux_fit(p->x, min_point->x, max_point->x, 0,
					voxels->width - 1);
			y = (float) miaux_fit(p->y, min_point->y, max_point->y, 0,
					voxels->height - 1);
			z = (float) miaux_fit(p->z, min_point->z, max_point->z, 0,
					voxels->depth - 1);
			*result = voxel_value(voxels, x, y, z);
		} else {
			*result = 0.0;
		}
		break;
	}
	}
	return miTRUE;
}
