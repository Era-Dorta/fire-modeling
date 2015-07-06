#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColorSorted.h"

//#define DEBUG_SIGMA_A

#define INV_SIZE (1.0 / 127.0) * 2

struct fire_volume_light {
	miTag temperature_shader;
	miScalar temperature_scale;
	miScalar temperature_offset;
	miScalar march_increment;
};

extern "C" DLLEXPORT int fire_volume_light_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_light_init(miState *state,
		struct fire_volume_light *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
	} else {
		/* Instance initialization: */
		mi_warning("Precomputing bb radiation");
		miScalar temperature_scale = *mi_eval_scalar(
				&params->temperature_scale);
		miScalar temperature_offset = *mi_eval_scalar(
				&params->temperature_offset);
		miTag temperature_shader = *mi_eval_tag(&params->temperature_shader);

		VoxelDatasetColorSorted *voxels =
				(VoxelDatasetColorSorted *) miaux_user_memory_pointer(state,
						sizeof(VoxelDatasetColorSorted));

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width, height, depth;
		miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
				temperature_shader);

		miaux_copy_voxel_dataset(voxels, state, temperature_shader, width,
				height, depth, temperature_scale, temperature_offset);

		voxels->compute_bb_radiation_threaded();

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
		mi_warning("Done precomputing bb radiation with dataset size %dx%dx%d",
				width, height, depth);
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_light_exit(miState *state,
		void *params) {
	return miaux_release_user_memory("fire_volume_light", state, params);
}

//TODO Add check for small contribution and return (miBoolean)2
extern "C" DLLEXPORT miBoolean fire_volume_light(miColor *result,
		miState *state, struct fire_volume_light *params) {

	VoxelDatasetColorSorted *voxels =
			(VoxelDatasetColorSorted *) miaux_user_memory_pointer(state, 0);

	// Get the maximum value and say this light has that colour
	miaux_copy_color_rgb(result, &voxels->get_max_voxel_value());

	if (state->type != miRAY_LIGHT) { /* visible area light set */
		return (miTRUE);
	}

	// Set light position from the handler, this comes in internal space
	mi_query(miQ_LIGHT_ORIGIN, state, state->light_instance, &state->org);

	// If this is not the first sample then next data from the voxel dataset
	// set the light to be that colour and in that position
	if (state->count > 0) {
		// Set the colour using the next value
		miaux_copy_color_rgb(result,
				&voxels->get_sorted_voxel_value(state->count));

		// Move the light origin to the voxel position
		const miVector minus_one = { -1, -1, -1 };
		miVector offset_light, offset_internal;

		voxels->get_i_j_k_from_sorted(offset_light, state->count);

		// The voxel data set goes from {-1,-1,-1} to {1,1,1}, so with
		// i,j,k = (127 / 2) it should be 1, to cancel the offset and
		// with i,j,k = 127, then it should be 2, to be 1 above the offset
		mi_vector_mul(&offset_light, INV_SIZE);

		mi_vector_add(&offset_light, &offset_light, &minus_one);

		// {-1,-,1,-1} is for a light at origin without rotation, so transform
		// from light space to internal, to account for that
		mi_vector_from_light(state, &offset_internal, &offset_light);

		mi_vector_add(&state->org, &state->org, &offset_internal);
	}
	// dir is vector from light origin to primitive intersection point
	mi_vector_sub(&state->dir, &state->point, &state->org);

	// Distance is the norm of dir
	state->dist = mi_vector_norm(&state->dir);

	// Normalise dir using dist, more efficient than computing directly dir
	// normalised and computing the norm again for dir
	mi_vector_div(&state->dir, state->dist);

	// N.b. seems like the direction for the shadows to work has to be
	// origin -> point, but for the shaders to work, it has to be
	// point -> origin, options include switching the normal or changing the
	// direction again after calling mi_trace_shadow
	miVector aux;
	miaux_copy_vector_neg(&aux, &state->dir);
	state->dot_nd = mi_vector_dot(&aux, &state->normal);

	return mi_trace_shadow(result, state);
}
