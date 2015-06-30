/*
 * miaux.h
 *
 *  Created on: 19 Jun 2015
 *      Author: gdp24
 */

#ifndef SRC_MIAUX_H_
#define SRC_MIAUX_H_

#include "shader.h"
#include "VoxelDatasetColor.h"

// Standard Maya return struct for volumetric shaders
typedef struct VolumeShader_R {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
} VolumeShader_R;

enum Voxel_Return {
	DENSITY, WIDTH, HEIGHT, DEPTH, DENSITY_RAW
};

char* miaux_tag_to_string(miTag tag, char *default_value);

double miaux_fit(double v, double oldmin, double oldmax, double newmin,
		double newmax);

miBoolean miaux_release_user_memory(const char* shader_name, miState *state,
		void *params);

void* miaux_user_memory_pointer(miState *state, int allocation_size);

miBoolean miaux_point_inside(miVector *p, miVector *min_p, miVector *max_p);

void miaux_add_color(miColor *result, miColor *c);

void miaux_add_inv_rgb_color(miColor *result, miColor *c);

void miaux_clamp(miScalar *result, miScalar min, miScalar max);

void miaux_clamp_color(miColor *c, miScalar min, miScalar max);

void miaux_point_along_vector(miVector *result, miVector *point,
		miVector *direction, miScalar distance);

void miaux_march_point(miVector *result, miState *state, miScalar distance);

void miaux_alpha_blend_colors(miColor *result, miColor *foreground,
		miColor *background);

void miaux_add_scaled_color(miColor *result, miColor *color, miScalar scale);

void miaux_scale_color(miColor *result, miScalar scale);

void miaux_fractional_shader_occlusion_at_point(miState *state,
		miVector *start_point, miVector *direction, miScalar total_distance,
		miScalar march_increment, miScalar shadow_density,
		miColor *transparency);

void miaux_multiply_colors(miColor *result, miColor *x, miColor *y);

void miaux_set_channels(miColor *c, miScalar new_value);

void miaux_set_rgb(miColor *c, miScalar new_value);

void miaux_add_transparent_color(miColor *result, miColor *color,
		miScalar transparency);

void miaux_total_light_at_point(miColor *result, miVector *point,
		miState *state);

miScalar miaux_threshold_density(miVector *point, miVector *center,
		miScalar radius, miScalar unit_density, miScalar march_increment);

double miaux_shadow_breakpoint(double color, double transparency,
		double breakpoint);

void miaux_copy_color(miColor *result, miColor *color);

miBoolean miaux_all_channels_equal(miColor *c, miScalar v);

void miaux_initialize_volume_output(VolumeShader_R* result);

void miaux_get_voxel_dataset_dims(miState *state, miTag density_shader,
		unsigned *width, unsigned *height, unsigned *depth);

void miaux_copy_voxel_dataset(miState *state, miTag density_shader,
		VoxelDatasetColor *voxels, unsigned width, unsigned height,
		unsigned depth, miScalar unit_density);

void miaux_get_sigma_a(miState *state, miColor *sigma_a);

void miaux_vector_warning(const char* s, const miVector& v);

void miaux_vector_warning(const char* s, const miGeoVector& v);

void miaux_vector_warning(const char* s, const miColor& v);

void miaux_matrix_warning(const char* s, const miMatrix& v);

#endif /* SRC_MIAUX_H_ */
