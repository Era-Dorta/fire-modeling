#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColor.h"

//#define DEBUG_SIGMA_A

struct fire_volume {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
	miTag density_shader;
	miScalar density_scale;
	miScalar shadow_scale;
	miScalar march_increment;
	miBoolean cast_shadows;
};

extern "C" DLLEXPORT int fire_volume_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_init(miState *state,
		struct fire_volume *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
	} else {
		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		if (cast_shadows) { // If the object is transparent then do not compute
			/* Instance initialization: */
			mi_warning("Precomputing sigma_a");

			VoxelDatasetColor *voxels =
					(VoxelDatasetColor *) miaux_user_memory_pointer(state,
							sizeof(VoxelDatasetColor));

			miScalar density_scale = *mi_eval_scalar(&params->density_scale);
			miTag density_shader = *mi_eval_tag(&params->density_shader);

			// Save previous state
			miVector original_point = state->point;
			miRay_type ray_type = state->type;

			unsigned width, height, depth;
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					density_shader);

			miaux_copy_voxel_dataset(voxels, state, density_shader, width,
					height, depth, density_scale, 0);

			voxels->compute_sigma_a_threaded();

			// Restore previous state
			state->point = original_point;
			state->type = ray_type;
			mi_warning("Done precomputing sigma_a with dataset size %dx%dx%d",
					width, height, depth);
		}
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_exit(miState *state,
		void *params) {
	return miaux_release_user_memory("fire_volume", state, params);
}

extern "C" DLLEXPORT miBoolean fire_volume(VolumeShader_R *result,
		miState *state, struct fire_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miColor *color = mi_eval_color(&params->color);
	//miColor *glowColor = mi_eval_color(&params->glowColor);
	//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
	//miColor *transparency = mi_eval_color(&params->transparency);
	miScalar density_scale = *mi_eval_scalar(&params->density_scale);
	miScalar march_increment = *mi_eval_scalar(&params->march_increment);
	miTag density_shader = *mi_eval_tag(&params->density_shader);

	// Transform to object space, as voxel_shader and the voxel object assume
	// a cube centred at origin of unit width, height and depth
	miVector origin, direction;
	mi_point_to_object(state, &origin, &state->org);
	mi_vector_to_object(state, &direction, &state->dir);

	if (state->type == miRAY_SHADOW) {
		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		if (!cast_shadows) { // Object is fully transparent, do nothing
			return miFALSE;
		}
		miScalar shadow_scale = *mi_eval_scalar(&params->shadow_scale);
		shadow_scale = pow(10, shadow_scale);
		/*
		 * Seems to be affected only by transparency, 0 to not produce hard
		 * shadows (default) effect, 1 to let that colour pass
		 * result->transparency.r = 1; // Red shadow
		 */
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_user_memory_pointer(state, 0);

#ifndef DEBUG_SIGMA_A
		miaux_fractional_shader_occlusion_at_point(&result->transparency,
				&origin, &direction, state->dist, march_increment, shadow_scale,
				voxels);
		return miTRUE;
#else
		return miFALSE;
#endif
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
			miaux_march_point(&state->point, &origin, &direction, distance);
			mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
					density_shader, NULL);
#ifdef DEBUG_SIGMA_A
			VoxelDatasetColor *voxels =
			(VoxelDatasetColor *) miaux_user_memory_pointer(state, 0);
			miColor sigma_a;
			miaux_get_sigma_a(&sigma_a, &state->point, voxels);
			density = std::max(std::max(sigma_a.r, sigma_a.g), sigma_a.b)
			* pow(10, 12);
#endif
			if (density > 0) {
				// Here is where the equation is solved
				// exp(-a * march) * L_next_march + (1 - exp(-a *march)) * L_e
				density *= density_scale * march_increment;
				miaux_total_light_at_point(&light_color, state);
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
