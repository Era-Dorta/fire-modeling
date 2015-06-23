/*
 * miaux.h
 *
 *  Created on: 19 Jun 2015
 *      Author: gdp24
 */

#ifndef SRC_MIAUX_H_
#define SRC_MIAUX_H_

#include "shader.h"

char* miaux_tag_to_string(miTag tag, char *default_value);

double miaux_fit(double v, double oldmin, double oldmax, double newmin,
		double newmax);

miBoolean miaux_release_user_memory(const char* shader_name, miState *state,
		void *params);

void* miaux_user_memory_pointer(miState *state, int allocation_size);

miBoolean miaux_point_inside(miVector *p, miVector *min_p, miVector *max_p);

void miaux_read_volume_block(char* filename, int *width, int *height,
		int *depth, float* block);

void miaux_light_array(miTag **lights, int *light_count, miState *state,
		int *offset_param, int *count_param, miTag *lights_param);

void miaux_add_color(miColor *result, miColor *c);

void miaux_point_along_vector(miVector *result, miVector *point,
		miVector *direction, miScalar distance);

void miaux_march_point(miVector *result, miState *state, miScalar distance);

void miaux_alpha_blend_colors(miColor *result, miColor *foreground,
		miColor *background);

void miaux_add_scaled_color(miColor *result, miColor *color, miScalar scale);

void miaux_scale_color(miColor *result, miScalar scale);

miScalar miaux_fractional_shader_occlusion_at_point(miState *state,
		miVector *start_point, miVector *direction, miScalar total_distance,
		miTag density_shader, miScalar unit_density, miScalar march_increment);

void miaux_multiply_colors(miColor *result, miColor *x, miColor *y);

void miaux_set_channels(miColor *c, miScalar new_value);

void miaux_add_transparent_color(miColor *result, miColor *color,
		miScalar transparency);

void miaux_total_light_at_point(miColor *result, miVector *point,
		miState *state, miTag* light, int light_count);
void miaux_vector_warning(const char* s, const miVector& v);

void miaux_vector_warning(const char* s, const miGeoVector& v);

void miaux_color_warning(const char* s, const miColor& v);

void miaux_matrix_warning(const char* s, const miMatrix& v);

#endif /* SRC_MIAUX_H_ */
