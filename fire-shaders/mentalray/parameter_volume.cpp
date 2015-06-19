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
	miScalar unit_density, march_increment, density;
	miTag density_shader, *light;
	int light_count;
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}
	density_shader = *mi_eval_tag(&params->density_shader);
	unit_density = *mi_eval_scalar(&params->unit_density);
	march_increment = *mi_eval_scalar(&params->march_increment);
	miaux_light_array(&light, &light_count, state, &params->i_light,
			&params->n_light, params->light);
	if (state->type == miRAY_SHADOW) {
		miScalar occlusion = miaux_fractional_shader_occlusion_at_point(state,
				&state->org, &state->dir, state->dist, density_shader,
				unit_density, march_increment);
		miaux_scale_color(result, 1.0 - occlusion);
	} else {
		miColor *color = mi_eval_color(&params->color);
		miScalar distance;
		miColor volume_color = { 0, 0, 0, 0 }, light_color, point_color;
		miVector original_point = state->point;
		struct miRc_intersection* original_state_pri = state->pri;
		state->pri = NULL;
		for (distance = 0; distance <= state->dist; distance +=
				march_increment) {
			miVector march_point;
			miaux_march_point(&march_point, state, distance);
			state->point = march_point;
			mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
					density_shader, NULL);
			if (density > 0) {
				density *= unit_density * march_increment;
				//miaux_total_light_at_point(&light_color, &march_point, state,
				//		light, light_count);
				//miaux_multiply_colors(&point_color, color, &light_color);
				//miaux_add_transparent_color(&volume_color, &point_color,
				//		density);
				volume_color.r = density;
				volume_color.g = density;
				volume_color.b = density;
			}
			if (volume_color.a == 1.0) {
				break;
			}
		}
		miaux_alpha_blend_colors(result, &volume_color, result);
		state->point = original_point;
		state->pri = original_state_pri;
	}
	return miTRUE;
}
