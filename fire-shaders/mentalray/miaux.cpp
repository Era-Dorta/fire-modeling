/*
 * miaux.cpp
 *
 *  Created on: 19 Jun 2015
 *      Author: gdp24
 */

#include "miaux.h"

#include <fstream>
#include <thread>
#include <vector>

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

	for (int i = 0; i < count; i++) {
		if (fp.eof()) {
			mi_fatal("Error, file \"%s\" has less data that declared.",
					filename);
		}
		fp >> block[i];
		block[i] = block[i] * 4.15;
	}
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

void miaux_set_rgb(miColor *c, miScalar new_value) {
	c->r = c->g = c->b = new_value;
}

void miaux_add_transparent_color(miColor *result, miColor *color,
		miScalar transparency) {
	miScalar new_alpha = result->a + transparency;
	if (new_alpha > 1.0) {
		transparency = 1.0 - result->a;
	}
	result->r += color->r * transparency;
	result->g += color->g * transparency;
	result->b += color->b * transparency;
	result->a += transparency;
}

void miaux_total_light_at_point(miColor *result, miVector *point,
		miState *state) {
	miColor sum, light_color;
	int light_sample_count;
	miVector original_point = state->point;
	state->point = *point;

	miaux_set_channels(result, 0.0);
	for (mi::shader::LightIterator iter(state); !iter.at_end(); ++iter) {
		miaux_set_channels(&sum, 0.0);

		while (iter->sample()) {
			iter->get_contribution(&light_color);
			// Do not change to miaux_add_color, since add_color also changes
			// the alpha
			miaux_add_scaled_color(&sum, &light_color, 1.0);
		}

		light_sample_count = iter->get_number_of_samples();
		if (light_sample_count > 0) {
			miaux_add_scaled_color(result, &sum, 1.0 / light_sample_count);
		}
	}
	state->point = original_point;
}

miScalar miaux_threshold_density(miVector *point, miVector *center,
		miScalar radius, miScalar unit_density, miScalar march_increment) {
	miScalar distance = mi_vector_dist(center, point);
	if (distance <= radius) {
		return unit_density * march_increment;
	} else {
		return 0.0;
	}
}

void miaux_copy_color(miColor *result, miColor *color) {
	result->r = color->r;
	result->g = color->g;
	result->b = color->b;
	result->a = color->a;
}

double miaux_shadow_breakpoint(double color, double transparency,
		double breakpoint) {
	if (transparency < breakpoint) {
		return miaux_fit(transparency, 0, breakpoint, 0, color);
	} else {
		return miaux_fit(transparency, breakpoint, 1, color, 1);
	}
}

miBoolean miaux_all_channels_equal(miColor *c, miScalar v) {
	if (c->r == v && c->g == v && c->b == v && c->a == v) {
		return miTRUE;
	} else {
		return miFALSE;
	}
}

void miaux_initialize_volume_output(VolumeShader_R* result) {
	miaux_set_rgb(&result->color, 0);
	miaux_set_rgb(&result->glowColor, 0);
	miaux_set_rgb(&result->transparency, 1);
}

void miaux_get_voxel_dataset_dims(miState *state, miTag density_shader,
		int *width, int *height, int *depth) {
	// Get the dimensions of the voxel data
	miScalar width_s, height_s, depth_s;
	state->type = (miRay_type) WIDTH;
	mi_call_shader_x((miColor*) &width_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	state->type = (miRay_type) HEIGHT;
	mi_call_shader_x((miColor*) &height_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	state->type = (miRay_type) DEPTH;
	mi_call_shader_x((miColor*) &depth_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	*width = (int) width_s;
	*height = (int) height_s;
	*depth = (int) depth_s;
}

void set_voxel_val(voxel_data *voxels, int x, int y, int z, float val) {
	voxels->block[z * voxels->depth * voxels->height + y * voxels->height + x] =
			val;
}

float get_voxel_val(voxel_data *voxels, int x, int y, int z) {
	return voxels->block[z * voxels->depth * voxels->height + y * voxels->height
			+ x];
}

void miaux_copy_voxel_dataset(miState *state, miTag density_shader,
		voxel_data *voxels, int width, int height, int depth) {

	miScalar density;
	for (int i = 0; i < width; i++) {
		for (int j = 0; j < height; j++) {
			for (int k = 0; k < depth; k++) {
				state->point.x = i;
				state->point.y = j;
				state->point.z = k;
				mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
						density_shader, NULL);
				set_voxel_val(voxels, i, j, k, density);
			}
		}
	}
}

void miaux_compute_sigma_a(voxel_data *voxels, miState *state,
		miTag density_shader, int i_width, int i_height, int i_depth,
		int e_width, int e_height, int e_depth) {

	for (int i = i_width; i <= e_width; i++) {
		for (int j = i_height; j <= e_height; j++) {
			for (int k = i_depth; k <= e_depth; k++) {
				set_voxel_val(voxels, i, j, k,
						get_voxel_val(voxels, i, j, k) + 0.5);
			}
		}
	}
}

void miaux_threaded_compute_sigma_a(miState* state, miTag density_shader,
		voxel_data* voxels, int width, int height, int depth){

	// Get thread hint, i.e. number of cores
	unsigned num_threads = std::thread::hardware_concurrency();
	// Get are at least able to run one thread
	if (num_threads == 0) {
		num_threads = 1;
	}
	// Cap the number of threads if there is not enough work for each one
	if ((unsigned) (depth) < num_threads) {
		num_threads = depth;
	}
	mi_warning("\tStart computation with %d threads", num_threads);
	unsigned thread_chunk = depth / num_threads;
	std::vector<std::thread> threads;
	unsigned i_depth = 0, e_depth = thread_chunk;
	// Launch each thread with its chunk of work
	for (unsigned i = 0; i < num_threads - 1; i++) {
		threads.push_back(
				std::thread(miaux_compute_sigma_a, voxels, state,
						density_shader, 0, 0, i_depth, width, height, e_depth));
		i_depth = e_depth + 1;
		e_depth = e_depth + thread_chunk;
	}
	// The remaining will be handled by the current thread
	miaux_compute_sigma_a(voxels, state, density_shader, 0, 0, i_depth, width,
			height, depth - 1);
	// Wait for the other threads to finish
	for (auto& thread : threads) {
		thread.join();
	}
}

void miaux_vector_warning(const char* s, const miVector& v) {
	mi_warning("%s %f, %f, %f", s, v.x, v.y, v.z);
}

void miaux_vector_warning(const char* s, const miGeoVector& v) {
	mi_warning("%s %f, %f, %f", s, v.x, v.y, v.z);
}

void miaux_vector_warning(const char* s, const miColor& v) {
	mi_warning("%s %f, %f, %f, %f", s, v.r, v.g, v.b, v.a);
}

void miaux_matrix_warning(const char* s, const miMatrix& v) {
	mi_warning("%s %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, "
			"%f", s, v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9],
			v[10], v[11], v[12], v[13], v[14], v[15]);
}
