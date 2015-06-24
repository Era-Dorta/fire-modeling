#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"

// Go to SphereFogSG and add this as its volume shader in the mental ray tab
// in custom shaders

struct parameter_volume {
	miColor color;
	miTag density_shader;
	miScalar unit_density;
	miScalar march_increment;
	int i_light;
	int n_light;
	miTag light[1];
};

extern "C" DLLEXPORT int parameter_volume_version(void) {
	return 1;
}
extern "C" DLLEXPORT miBoolean parameter_volume(miColor *result, miState *state,
		struct parameter_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miScalar unit_density, march_increment, density;
	miTag density_shader;

	miColor *color = mi_eval_color(&params->color);
	density_shader = *mi_eval_tag(&params->density_shader);
	unit_density = *mi_eval_scalar(&params->unit_density);
	march_increment = *mi_eval_scalar(&params->march_increment);

	if (state->type == miRAY_SHADOW) {
		//TODO Shadows do not work, fix
		miScalar occlusion = miaux_fractional_shader_occlusion_at_point(state,
				&state->org, &state->dir, state->dist, density_shader,
				unit_density, march_increment);
		miaux_scale_color(result, 1.0 - occlusion);
		//result->a *= 1.0 - occlusion;
		return (result->r != 0 || result->g != 0 || result->b != 0);
	} else {
		if (state->dist == 0.0) /* infinite dist: outside volume */
			return (miTRUE);

		miScalar distance;
		miColor volume_color = { 0, 0, 0, 0 }, light_color, point_color;
		miVector original_point = state->point;
		// Primitive intersection is the bounding box, set to null to be able
		// to do the ray marching
		struct miRc_intersection* original_state_pri = state->pri;
		state->pri = NULL;

		for (distance = 0; distance <= state->dist; distance +=
				march_increment) {
			miVector march_point;
			miaux_march_point(&march_point, state, distance);
			state->point = march_point;
			mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
					density_shader, NULL);
			//density = 1;
			if (density > 0) {
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
		// Get background color assuming the volume is transparent
		miColor background;
		// TODO Check if this is not needed for volume_color.a == 0
		mi_trace_transparent(&background, state);
		miaux_alpha_blend_colors(&volume_color, &volume_color, &background);
		miaux_add_color(result, &volume_color);
		state->point = original_point;
		state->pri = original_state_pri;
	}
	return miTRUE;
}
