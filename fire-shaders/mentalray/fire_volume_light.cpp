#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColor.h"

//#define DEBUG_SIGMA_A

// Create a point light, then in pointLightShape -> mental ray -> Custom Shaders
// -> Ligh Shader, select this node
// connectAttr -f fire_volume_light1.message pointLightShape1.miLightShader;

struct fire_volume_light {
	miTag temperature_shader;
	miScalar unit_temperature;
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
		mi_warning("Precomputing sigma_a");
		miScalar unit_temperature = *mi_eval_scalar(
				&params->temperature_shader);
		miTag temperature_shader = *mi_eval_tag(&params->temperature_shader);

		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_user_memory_pointer(state,
						sizeof(VoxelDatasetColor));

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width, height, depth;
		miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
				temperature_shader);

		miaux_copy_voxel_dataset(voxels, state, temperature_shader, width,
				height, depth, unit_temperature);

		//voxels->compute_sigma_a_threaded();

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
		mi_warning("Done precomputing sigma_a with dataset size %dx%dx%d",
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

	miScalar unit_temperature = *mi_eval_scalar(&params->temperature_shader);
	miTag temperature_shader = *mi_eval_tag(&params->temperature_shader);

	miaux_set_rgb(result, 1);
	return mi_trace_shadow(result, state);
}
