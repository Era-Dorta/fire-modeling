#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "FuelTypes.h"
#include "miaux.h"
#include "VoxelDatasetColor.h"

//#define DEBUG_SIGMA_A

struct fire_volume {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
	miTag density_shader;
	miTag absorption_shader;
	miInteger fuel_type;
	miScalar density_scale;
	miScalar density_scale_for_shadows;
	miScalar march_increment;
	miBoolean cast_shadows;
	miInteger i_light;	// index of first light
	miInteger n_light;	// number of lights
	miTag light[1];	// list of lights
};

extern "C" DLLEXPORT int fire_volume_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_init(miState *state,
		struct fire_volume *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
		miaux_initialize_external_libs();
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_exit(miState *state,
		struct fire_volume *params) {
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume(VolumeShader_R *result,
		miState *state, struct fire_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miScalar march_increment = *mi_eval_scalar(&params->march_increment);

	// Transform to object space, as voxel_shader and the voxel object assume
	// a cube centred at origin of unit width, height and depth
	miVector origin, direction;
	mi_point_to_object(state, &origin, &state->org);
	mi_vector_to_object(state, &direction, &state->dir);

	// Shadows, light being absorbed
	if (state->type == miRAY_SHADOW) {
		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		if (!cast_shadows) { // Object is fully transparent, do nothing
			return miFALSE;
		}
		miScalar shadow_d_scale = *mi_eval_scalar(
				&params->density_scale_for_shadows);
		shadow_d_scale = pow(10, shadow_d_scale);
		miTag absorption_shader = *mi_eval_tag(&params->absorption_shader);
		/*
		 * Seems to be affected only by transparency, 0 to not produce hard
		 * shadows (default) effect, 1 to let that colour pass
		 * result->transparency.r = 1; // Red shadow
		 */

#ifndef DEBUG_SIGMA_A
		miaux_fractional_shader_occlusion_at_point(&result->transparency, state,
				&origin, &direction, state->dist, march_increment,
				shadow_d_scale, absorption_shader);
		return miTRUE;
#else
		return miFALSE;
#endif
		// Eye rays, final colour at point, ray marching
	} else {
		if (state->dist == 0.0) { /* infinite dist: outside volume */
			return (miTRUE);
		}

		// Initialise to black-transparent volume
		miaux_initialize_volume_output(result);

		//miColor *color = mi_eval_color(&params->color);
		//miColor *glowColor = mi_eval_color(&params->glowColor);
		//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
		//miColor *transparency = mi_eval_color(&params->transparency);
		miTag density_shader = *mi_eval_tag(&params->density_shader);
		miTag absorption_shader = *mi_eval_tag(&params->absorption_shader);
		miScalar density_scale = *mi_eval_scalar(&params->density_scale);
		miScalar march_increment = *mi_eval_scalar(&params->march_increment);
		miInteger fuel_type = *mi_eval_integer(&params->fuel_type);

		miInteger i_light = *mi_eval_integer(&params->i_light);
		miInteger n_light = *mi_eval_integer(&params->n_light);
		miTag *light = mi_eval_tag(&params->light) + i_light;

		// Only the light specified in the light list will be used
		mi_inclusive_lightlist(&n_light, &light, state);

		if (fuel_type == FuelType::BlackBody) {
			miaux_ray_march_simple(result, state, density_scale,
					march_increment, density_shader, light, n_light, origin,
					direction);
		} else {
			miaux_ray_march_with_sigma_a(result, state, density_scale,
					march_increment, density_shader, absorption_shader, light,
					n_light, origin, direction);
		}
	}
	return miTRUE;
}
