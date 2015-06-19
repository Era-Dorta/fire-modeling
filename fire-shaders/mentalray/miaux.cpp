/*
 * miaux.cpp
 *
 *  Created on: 19 Jun 2015
 *      Author: gdp24
 */

#include "miaux.h"

#include <fstream>

#include "shader.h"

char* miaux_tag_to_string(miTag tag, char *default_value) {
	char *result = default_value;
	if (tag != 0) {
		result = (char*) mi_db_access(tag);
		mi_db_unpin(tag);
	}
	return result;
}

double miaux_fit(double v, double oldmin, double oldmax, double newmin,
		double newmax) {
	return newmin + ((v - oldmin) / (oldmax - oldmin)) * (newmax - newmin);
}

miBoolean miaux_release_user_memory(const char* shader_name, miState *state,
		void *params) {
	if (params != NULL) { /* Shader instance exit */
		void **user_pointer;
		if (!mi_query(miQ_FUNC_USERPTR, state, 0, &user_pointer))
			mi_fatal(
					"Could not get user pointer in shader exit function %s_exit",
					shader_name);
		mi_mem_release(*user_pointer);
	}
	return miTRUE;
}

void* miaux_user_memory_pointer(miState *state, int allocation_size) {
	void **user_pointer;
	mi_query(miQ_FUNC_USERPTR, state, 0, &user_pointer);
	if (allocation_size > 0) {
		*user_pointer = mi_mem_allocate(allocation_size);
	}
	return *user_pointer;
}

miBoolean miaux_point_inside(miVector *p, miVector *min_p, miVector *max_p) {
	return p->x >= min_p->x && p->y >= min_p->y && p->z >= min_p->z
			&& p->x <= max_p->x && p->y <= max_p->y && p->z <= max_p->z;
}

void miaux_read_volume_block(char* filename, int *width, int *height,
		int *depth, float* block) {
	int count;
	std::fstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening file \"%s\".", filename);
	}
	// Read width heifht and depth
	fp >> *width;
	fp >> *height;
	fp >> *depth;

	count = (*width) * (*height) * (*depth);
	mi_warning("Volume dataset : %dx%dx%d", *width, *height, *depth);

	for (int i = 0; i < count; i++) {
		if (fp.eof()) {
			mi_fatal("Error, file \"%s\" has less data that declared.",
					filename);
		}
		fp >> block[i];
	}
	mi_warning("Done reading the dataset");
}

void miaux_light_array(miTag **lights, int *light_count, miState *state,
		int *offset_param, int *count_param, miTag *lights_param) {
	int array_offset = *mi_eval_integer(offset_param);
	*light_count = *mi_eval_integer(count_param);
	*lights = mi_eval_tag(lights_param) + array_offset;
}

void miaux_add_color(miColor *result, miColor *c) {
	result->r += c->r;
	result->g += c->g;
	result->b += c->b;
	result->a += c->a;
}

void miaux_point_along_vector(miVector *result, miVector *point,
		miVector *direction, miScalar distance) {
	result->x = point->x + distance * direction->x;
	result->y = point->y + distance * direction->y;
	result->z = point->z + distance * direction->z;
}

void miaux_march_point(miVector *result, miState *state, miScalar distance) {
	miaux_point_along_vector(result, &state->org, &state->dir, distance);
}

void miaux_alpha_blend_colors(miColor *result, miColor *foreground,
		miColor *background) {
	double bg_fraction = 1.0 - foreground->a;
	result->r = foreground->r + background->r * bg_fraction;
	result->g = foreground->g + background->g * bg_fraction;
	result->b = foreground->b + background->b * bg_fraction;
}

void miaux_add_scaled_color(miColor *result, miColor *color, miScalar scale) {
	result->r += color->r * scale;
	result->g += color->g * scale;
	result->b += color->b * scale;
}

void miaux_scale_color(miColor *result, miScalar scale) {
	result->r *= scale;
	result->g *= scale;
	result->b *= scale;
}

miScalar miaux_fractional_shader_occlusion_at_point(miState *state,
		miVector *start_point, miVector *direction, miScalar total_distance,
		miTag density_shader, miScalar unit_density, miScalar march_increment) {
	miScalar density, dist, occlusion = 0.0;
	miVector march_point;
	miVector original_point = state->point;
	mi_vector_normalize(direction);
	for (dist = 0; dist <= total_distance; dist += march_increment) {
		miaux_point_along_vector(&march_point, start_point, direction, dist);
		state->point = march_point;
		mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
				density_shader, NULL);
		occlusion += density * unit_density * march_increment;
		if (occlusion >= 1.0) {
			occlusion = 1.0;
			break;
		}
	}
	state->point = original_point;
	return occlusion;
}

void miaux_multiply_colors(miColor *result, miColor *x, miColor *y) {
	result->r = x->r * y->r;
	result->g = x->g * y->g;
	result->b = x->b * y->b;
}

void miaux_set_channels(miColor *c, miScalar new_value) {
	c->r = c->g = c->b = c->a = new_value;
}

void miaux_add_transparent_color(miColor *result, miColor *color,
		miScalar transparency) {
	miScalar new_alpha = result->a + transparency;
	if (new_alpha > 1.0)
		transparency = 1.0 - result->a;
	result->r += color->r * transparency;
	result->g += color->g * transparency;
	result->b += color->b * transparency;
	result->a += transparency;
}

void miaux_total_light_at_point(miColor *result, miVector *point,
		miState *state, miTag* light, int light_count) {
	miColor sum, light_color;
	int i, light_sample_count;
	miVector original_point = state->point;
	state->point = *point;

	miaux_set_channels(result, 0.0);
	for (i = 0; i < light_count; i++, light++) {
		miVector direction_to_light;
		light_sample_count = 0;
		miaux_set_channels(&sum, 0.0);

		while (mi_sample_light(&light_color, &direction_to_light, NULL, state,
				*light, &light_sample_count)) {
			miaux_add_scaled_color(&sum, &light_color, 1.0);
		}

		if (light_sample_count) {
			miaux_add_scaled_color(result, &sum, 1 / light_sample_count);
		}
	}
	state->point = original_point;
}
