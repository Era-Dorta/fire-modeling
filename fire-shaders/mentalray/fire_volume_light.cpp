#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColorSorted.h"

//#define DEBUG_SIGMA_A

/*
 * Create an area light, then in areaLightShape -> mental ray
 * Tick Use Light Shape
 * On type select Custom
 * Scroll down to Custom Shaders
 * Add this shader as Light Shader
 *
 setAttr "areaLightShape1.areaLight" 1;
 setAttr "areaLightShape1.areaType" 4;
 connectAttr -f fire_volume_light1.message pointLightShape1.miLightShader;
 */

/*
 * An easy way to move everything together is to set the cube as parent
 * of the light, select the cube, then sift select the light then execute
 parent -s -r;
 *
 select -r areaLight1 box1 ;
 parent -s -r;
 *
 * Additionally, lock all transformations in the light shape
 *
 setAttr -l true { "areaLight1.t" };
 setAttr -l true { "areaLight1.r" };
 setAttr -l true { "areaLight1.s" };
 setAttr -l true { "areaLight1.sh" };
 */

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

extern "C" DLLEXPORT miBoolean fire_volume_light(miColor *result,
		miState *state, struct fire_volume_light *params) {

	VoxelDatasetColorSorted *voxels =
			(VoxelDatasetColorSorted *) miaux_user_memory_pointer(state, 0);

	// Get the maximum value and say this light has that colour
	miaux_copy_color_rgb(result, &voxels->get_max_voxel_value());

	if (state->type != miRAY_LIGHT) { /* visible area light set */
		return (miTRUE);
	}

	// Set light position from the handler
	mi_query(miQ_LIGHT_ORIGIN, state, state->light_instance, &state->org);

	if (state->count > 0) {
		miaux_copy_color_rgb(result,
				&voxels->get_sorted_voxel_value(state->count));

		miVector offset, minus_half = { -0.5, -0.5, -0.5 };
		mi_vector_add(&state->org, &state->org, &minus_half);

		voxels->get_i_j_k_from_sorted(offset, state->count);
		miScalar inv_n = 1 / 128.0;
		mi_vector_mul(&offset, inv_n);
		mi_vector_add(&state->org, &state->org, &offset);
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
