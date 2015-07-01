#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColor.h"

//#define DEBUG_SIGMA_A

// Go to SphereFogSG and add this as its volume shader in the mental ray tab
// in custom shaders

struct fire_volume_shader {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
	miTag density_shader;
	miTag temperature_shader;
	miScalar unit_density;
	miScalar shadow_density;
	miScalar march_increment;
};

extern "C" DLLEXPORT int fire_volume_shader_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_shader_init(miState *state,
		struct fire_volume_shader *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
	} else {
		/* Instance initialization: */
		mi_warning("Precomputing sigma_a");
		miScalar unit_density = *mi_eval_scalar(&params->unit_density);
		miTag density_shader = *mi_eval_tag(&params->density_shader);
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_user_memory_pointer(state,
						sizeof(VoxelDatasetColor));

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width, height, depth;
		miaux_get_voxel_dataset_dims(state, density_shader, &width, &height,
				&depth);

		miaux_copy_voxel_dataset(state, density_shader, voxels, width, height,
				depth, unit_density);

		voxels->compute_sigma_a_threaded();

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
		mi_warning("Done precomputing sigma_a with dataset size %dx%dx%d",
				width, height, depth);
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_shader_exit(miState *state,
		void *params) {
	return miaux_release_user_memory("fire_volume_shader", state, params);
}

extern "C" DLLEXPORT miBoolean fire_volume_shader(VolumeShader_R *result,
		miState *state, struct fire_volume_shader *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miColor *color = mi_eval_color(&params->color);
	//miColor *glowColor = mi_eval_color(&params->glowColor);
	//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
	//miColor *transparency = mi_eval_color(&params->transparency);
	miScalar unit_density = *mi_eval_scalar(&params->unit_density);
	miScalar march_increment = *mi_eval_scalar(&params->march_increment);
	miTag density_shader = *mi_eval_tag(&params->density_shader);

	if (state->type == miRAY_SHADOW) {
		miScalar shadow_density = *mi_eval_scalar(&params->shadow_density);
		/*
		 * Seems to be affected only by transparency, 0 to not produce hard
		 * shadows (default) effect, 1 to let that colour pass
		 * result->transparency.r = 1; // Red shadow
		 */
		miaux_fractional_shader_occlusion_at_point(state, &state->org,
				&state->dir, state->dist, march_increment, shadow_density,
				&result->transparency);
		return miTRUE;
	} else {
		if (state->dist == 0.0) /* infinite dist: outside volume */
			return (miTRUE);

		miaux_initialize_volume_output(result);

		miScalar distance, density;
		miColor volume_color = { 0, 0, 0, 0 }, light_color, point_color;
		miVector original_point = state->point;
		// Primitive intersection is the bounding box, set to null to be able
		// to do the ray marching
		struct miRc_intersection* original_state_pri = state->pri;
		state->pri = NULL;

		for (distance = state->dist; distance >= 0; distance -=
				march_increment) {
			miVector march_point;
			miaux_march_point(&march_point, state, distance);
			state->point = march_point;
			mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
					density_shader, NULL);
#ifdef DEBUG_SIGMA_A
			miColor sigma_a;
			miaux_get_sigma_a(state, &sigma_a);
			density = sigma_a.r;
#endif
			//density = 1;
			if (density > 0) {
				// Here is where the equation is solved
				// exp(-a * march) * L_next_march + (1 - exp(-a *march)) * L_e
				density *= unit_density * march_increment;
				miaux_total_light_at_point(&light_color, &march_point, state);
				miaux_multiply_colors(&point_color, color, &light_color);
				miaux_add_transparent_color(&volume_color, &point_color,
						density);
			}
			if (volume_color.a == 1.0) {
				break;
			}
		}

		miaux_copy_color(&result->color, &volume_color);
		// In RGBA, 0 alpha is transparent, but in in transparency for maya
		// volumetric 1 is transparent
		miaux_set_rgb(&result->transparency, 1 - volume_color.a);

		state->point = original_point;
		state->pri = original_state_pri;
	}
	return miTRUE;
}
