#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"

#define MAX_DATASET_SIZE 128*128*128

typedef struct {
	int width, height, depth;
	float block[MAX_DATASET_SIZE];
} voxel_data;

float voxel_value(voxel_data *voxels, float x, float y, float z) {
	return voxels->block[((int) (z + .5)) * voxels->depth * voxels->height
			+ ((int) (y + .5)) * voxels->height + ((int) (x + .5))];
}

struct voxel_density {
	miTag filename_tag;
	miVector min_point;
	miVector max_point;
	miColor color;
};

extern "C" DLLEXPORT int voxel_dataset_version(void) {
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
			mi_warning("voxel density filename %s", filename);
			voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state,
					sizeof(voxel_data));
			miaux_read_volume_block(filename, &voxels->width, &voxels->height,
					&voxels->depth, voxels->block);
			mi_warning("Voxel dataset: %dx%dx%d", voxels->width, voxels->height,
					voxels->depth);
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
	miVector *min_point = mi_eval_vector(&params->min_point);
	miVector *max_point = mi_eval_vector(&params->max_point);
	miVector *p = &state->point;
	if (miaux_point_inside(p, min_point, max_point)) {
		float x, y, z;
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state, 0);
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
	return miTRUE;
}
