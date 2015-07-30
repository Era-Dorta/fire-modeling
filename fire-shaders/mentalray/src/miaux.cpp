/*
 * miaux.cpp
 *
 *  Created on: 19 Jun 2015
 *      Author: gdp24
 */

#include "miaux.h"

#include "shader.h"
#include "Spectrum.h"

void miaux_initialize_external_libs() {
	Spectrum::Init();
	openvdb::initialize();
}

const char* miaux_tag_to_string(miTag tag, const char *default_value) {
	const char *result = default_value;
	if (tag != 0) {
		result = (const char*) mi_db_access(tag);
		mi_db_unpin(tag);
	}
	return result;
}

double miaux_fit(double v, double oldmin, double oldmax, double newmin,
		double newmax) {
	return newmin + ((v - oldmin) / (oldmax - oldmin)) * (newmax - newmin);
}

void* miaux_get_user_memory_pointer(miState *state) {
	void **user_pointer;
	mi_query(miQ_FUNC_USERPTR, state, 0, &user_pointer);
	return *user_pointer;
}

void* miaux_alloc_user_memory(miState *state, int allocation_size) {
	void **user_pointer;
	mi_query(miQ_FUNC_USERPTR, state, 0, &user_pointer);
	assert(allocation_size > 0);
	*user_pointer = mi_mem_allocate(allocation_size);
	return *user_pointer;
}

miBoolean miaux_point_inside(const miVector *p, const miVector *min_p,
		const miVector *max_p) {
	return p->x >= min_p->x && p->y >= min_p->y && p->z >= min_p->z
			&& p->x <= max_p->x && p->y <= max_p->y && p->z <= max_p->z;
}

void miaux_add_color(miColor *result, const miColor *c) {
	result->r += c->r;
	result->g += c->g;
	result->b += c->b;
	result->a += c->a;
}

void miaux_add_inv_rgb_color(miColor *result, const miColor *c) {
	result->r += 1.0 - c->r;
	result->g += 1.0 - c->g;
	result->b += 1.0 - c->b;
}

void miaux_clamp(miScalar *result, miScalar min, miScalar max) {
	if (*result < min) {
		*result = min;
		return;
	}
	if (*result > max) {
		*result = max;
	}
}

void miaux_clamp_color(miColor *c, miScalar min, miScalar max) {
	miaux_clamp(&c->r, min, max);
	miaux_clamp(&c->g, min, max);
	miaux_clamp(&c->b, min, max);
	miaux_clamp(&c->a, min, max);
}

void miaux_point_along_vector(miVector *result, const miVector *point,
		const miVector *direction, miScalar distance) {
	result->x = point->x + distance * direction->x;
	result->y = point->y + distance * direction->y;
	result->z = point->z + distance * direction->z;
}

void miaux_march_point(miVector *result, const miVector *org,
		const miVector *dir, miScalar distance) {
	miaux_point_along_vector(result, org, dir, distance);
}

void miaux_alpha_blend_colors(miColor *result, const miColor *foreground,
		const miColor *background) {
	double bg_fraction = 1.0 - foreground->a;
	result->r = foreground->r + background->r * bg_fraction;
	result->g = foreground->g + background->g * bg_fraction;
	result->b = foreground->b + background->b * bg_fraction;
}

void miaux_add_scaled_color(miColor *result, const miColor *color,
		miScalar scale) {
	result->r += color->r * scale;
	result->g += color->g * scale;
	result->b += color->b * scale;
}

void miaux_invert_rgb_color(miColor *result) {
	result->r = 1.0 - result->r;
	result->g = 1.0 - result->g;
	result->b = 1.0 - result->b;
}

void miaux_scale_color(miColor *result, miScalar scale) {
	result->r *= scale;
	result->g *= scale;
	result->b *= scale;
}

void miaux_fractional_shader_occlusion_at_point(miColor *transparency,
		const miVector *start_point, const miVector *direction,
		miScalar total_distance, miScalar march_increment,
		miScalar shadow_scale, const VoxelDatasetColor *voxels) {
	VoxelDatasetColor::Accessor accessor = voxels->get_accessor();
	miScalar dist;
	miColor total_sigma = { 0, 0, 0, 0 }, current_sigma;
	miVector march_point;
	for (dist = 0; dist <= total_distance; dist += march_increment) {
		miaux_point_along_vector(&march_point, start_point, direction, dist);
		miaux_get_sigma_a(&current_sigma, &march_point, voxels, accessor);
		miaux_add_color(&total_sigma, &current_sigma);
	}
	// In sigma_a we do R^3 since R is 10e-10, that leaves a final result in
	// the order of 10e-30 so a good shadow density value should be around
	// 10e30, empirically 10e12
	miaux_scale_color(&total_sigma, march_increment * shadow_scale);
	// Bigger coefficient, small exp
	total_sigma.r = exp(-total_sigma.r);
	total_sigma.g = exp(-total_sigma.g);
	total_sigma.b = exp(-total_sigma.b);
	// 0 is completely transparent
	miaux_add_color(transparency, &total_sigma);
}

void miaux_multiply_colors(miColor *result, const miColor *x,
		const miColor *y) {
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

void miaux_add_transparent_color(miColor *result, const miColor *color,
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

void miaux_total_light_at_point(miColor *result, miState *state, miTag *light,
		miInteger n_light) {
	miColor sum, light_color;
	int light_sample_count;

	miaux_set_channels(result, 0.0);
	for (mi::shader::LightIterator iter(state, light, n_light); !iter.at_end();
			++iter) {
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
}

miScalar miaux_threshold_density(const miVector *point, const miVector *center,
		miScalar radius, miScalar scale, miScalar march_increment) {
	miScalar distance = mi_vector_dist(center, point);
	if (distance <= radius) {
		return scale * march_increment;
	} else {
		return 0.0;
	}
}

void miaux_copy_color(miColor *result, const miColor *color) {
	result->r = color->r;
	result->g = color->g;
	result->b = color->b;
	result->a = color->a;
}

void miaux_copy_color_rgb(miColor *result, const miColor *color) {
	result->r = color->r;
	result->g = color->g;
	result->b = color->b;
}

void miaux_copy_color_scaled(miColor *result, const miColor *color,
		miScalar scale) {
	result->r = color->r * scale;
	result->g = color->g * scale;
	result->b = color->b * scale;
}

double miaux_shadow_breakpoint(double color, double transparency,
		double breakpoint) {
	if (transparency < breakpoint) {
		return miaux_fit(transparency, 0, breakpoint, 0, color);
	} else {
		return miaux_fit(transparency, breakpoint, 1, color, 1);
	}
}

miBoolean miaux_all_channels_equal(const miColor *c, miScalar v) {
	if (c->r == v && c->g == v && c->b == v && c->a == v) {
		return miTRUE;
	} else {
		return miFALSE;
	}
}

miBoolean miaux_color_is_black(const miColor *c) {
	return (c->r == 0 && c->g == 0 && c->b == 0);
}

void miaux_initialize_volume_output(VolumeShader_R* result) {
	miaux_set_rgb(&result->color, 0);
	miaux_set_rgb(&result->glowColor, 0);
	miaux_set_rgb(&result->transparency, 1);
}

void miaux_get_voxel_dataset_dims(unsigned *width, unsigned *height,
		unsigned *depth, miState *state, miTag density_shader) {
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

	*width = (unsigned) width_s;
	*height = (unsigned) height_s;
	*depth = (unsigned) depth_s;
}

void miaux_copy_voxel_dataset(VoxelDatasetColor *voxels, miState *state,
		miTag density_shader, unsigned width, unsigned height, unsigned depth,
		miScalar scale, miScalar offset) {

	state->type = (miRay_type) DENSITY_RAW;
	voxels->resize(width, height, depth);
	miColor density = { 0, 0, 0, 0 };
	openvdb::Vec3f density_v = openvdb::Vec3f::zero();
	for (unsigned i = 0; i < width; i++) {
		for (unsigned j = 0; j < height; j++) {
			for (unsigned k = 0; k < depth; k++) {
				state->point.x = i;
				state->point.y = j;
				state->point.z = k;
				mi_call_shader_x((miColor*) &density.r, miSHADER_MATERIAL,
						state, density_shader, NULL);
				if (density.r != 0) { // Don't add offset if there isn't any data
					density.r = density.r * scale + offset;
				}
				density.r = density.r * scale + offset;
				density_v.x() = density.r;
				voxels->set_voxel_value(i, j, k, density_v);
			}
		}
	}
}

void miaux_copy_sparse_voxel_dataset(VoxelDatasetColor *voxels, miState *state,
		miTag density_shader, unsigned width, unsigned height, unsigned depth,
		miScalar scale, miScalar offset) {
	state->type = (miRay_type) DENSITY_RAW;
	voxels->resize(width, height, depth);
	miColor density = { 0, 0, 0, 0 };
	openvdb::Vec3f density_v = openvdb::Vec3f::zero();
	for (unsigned i = 0; i < width; i++) {
		for (unsigned j = 0; j < height; j++) {
			for (unsigned k = 0; k < depth; k++) {
				state->point.x = i;
				state->point.y = j;
				state->point.z = k;
				// TODO Modify voxel_density to copy only the sparse values
				// Also the authors recommend setting the topology and then
				// using setValueOnly to change values
				mi_call_shader_x((miColor*) &density.r, miSHADER_MATERIAL,
						state, density_shader, NULL);
				if (density.r != 0.0f) {
					density.r = density.r * scale + offset;
					density_v.x() = density.r;
					voxels->set_voxel_value(i, j, k, density_v);
				}
			}
		}
	}
}

void miaux_get_sigma_a(miColor *sigma_a, const miVector *point,
		const VoxelDatasetColor *voxels,
		const VoxelDatasetColor::Accessor& accessor) {
	miVector min_point = { -1, -1, -1 };
	miVector max_point = { 1, 1, 1 };
	if (miaux_point_inside(point, &min_point, &max_point)) {
		openvdb::Vec3f sigma_av = voxels->get_fitted_voxel_value(point,
				&min_point, &max_point, accessor);
		sigma_a->r = sigma_av.x();
		sigma_a->g = sigma_av.y();
		sigma_a->b = sigma_av.z();
	} else {
		miaux_set_rgb(sigma_a, 0.0);
	}
}

void miaux_compute_object_matrix(miState *state, miMatrix matrix) {
	miVector x_0 = { 1, 0, 0 };
	miVector y_0 = { 0, 1, 0 };
	miVector z_0 = { 0, 0, 1 };
	miVector origin0 = { 0, 0, 0 };
	miVector x, y, z, origin;

	mi_vector_from_object(state, &x, &x_0);
	mi_vector_from_object(state, &y, &y_0);
	mi_vector_from_object(state, &z, &z_0);
	mi_point_from_object(state, &origin, &origin0);

	miMatrix object_rot, object_trans;
	mi_matrix_ident(object_rot);
	mi_matrix_ident(object_trans);

	object_trans[12] = -origin.x;
	object_trans[13] = -origin.y;
	object_trans[14] = -origin.z;

	object_rot[0] = x.x;
	object_rot[4] = x.y;
	object_rot[8] = x.z;
	object_rot[1] = y.x;
	object_rot[5] = y.y;
	object_rot[9] = y.z;
	object_rot[2] = z.x;
	object_rot[6] = z.y;
	object_rot[10] = z.z;

	mi_matrix_prod(matrix, object_trans, object_rot);
}

void miaux_copy_vector(miVector *result, const miVector *vector) {
	result->x = vector->x;
	result->y = vector->y;
	result->z = vector->z;
}

void miaux_copy_vector_neg(miVector *result, const miVector *vector) {
	result->x = -vector->x;
	result->y = -vector->y;
	result->z = -vector->z;
}

void miaux_ray_march_simple(VolumeShader_R *result, miState *state,
		miScalar density_scale, miScalar march_increment, miTag density_shader,
		miTag *light, miInteger n_light, miVector &origin, miVector &direction) {

	miScalar distance, density;
	miColor volume_color = { 0, 0, 0, 0 }, point_color;

	miVector original_point = state->point;
	miRay_type ray_type = state->type;
	// Primitive intersection is the bounding box, set to null to be able
	// to do the ray marching
	struct miRc_intersection* original_state_pri = state->pri;
	state->pri = NULL;

	// Since we are going to call the density shader several times,
	// tell the shader to cache the values
	state->type = static_cast<miRay_type>(ALLOC_CACHE);
	mi_call_shader_x(nullptr, miSHADER_MATERIAL, state, density_shader,
			nullptr);

	for (distance = state->dist; distance >= 0; distance -= march_increment) {
		miaux_march_point(&state->point, &origin, &direction, distance);

		state->type = static_cast<miRay_type>(DENSITY_CACHE);
		mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
				density_shader, nullptr);
		state->type = ray_type;

#ifdef DEBUG_SIGMA_A
		VoxelDatasetColor *voxels =
		(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		miColor sigma_a;
		miaux_get_sigma_a(&sigma_a, &state->point, voxels);
		density = std::max(std::max(sigma_a.r, sigma_a.g), sigma_a.b)
		* pow(10, 12);
#endif
		if (density > 0) {
			// Here is where the equation is solved
			// exp(-a * march) * L_next_march + (1 - exp(-a *march)) * L_e
			density *= density_scale * march_increment;
			miaux_total_light_at_point(&point_color, state, light, n_light);
			miaux_add_transparent_color(&volume_color, &point_color, density);
		}
		if (volume_color.a == 1.0) {
			break;
		}
	}

	// Note changing result->color or result->transparecy alpha channel
	// has no effect, the transparency is controlled with the transparency
	// rgb channels
	miaux_copy_color(&result->color, &volume_color);

	// In RGBA, 0 alpha is transparent, but in in transparency for maya
	// volumetric 1 is transparent
	miaux_set_rgb(&result->transparency, 1 - volume_color.a);

	state->type = static_cast<miRay_type>(FREE_CACHE);
	mi_call_shader_x(nullptr, miSHADER_MATERIAL, state, density_shader,
			nullptr);

	state->type = ray_type;
	state->point = original_point;
	state->pri = original_state_pri;
}

void miaux_ray_march_with_sigma_a(VolumeShader_R *result, miState *state,
		miScalar density_scale, miScalar march_increment, miTag density_shader,
		miTag *light, miInteger n_light, miVector &origin, miVector &direction) {
	VoxelDatasetColor *voxels =
			(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
	VoxelDatasetColor::Accessor accessor = voxels->get_accessor();
	miColor sigma_a;

	miScalar distance, density;
	miColor volume_color = { 0, 0, 0, 0 }, light_color, l_e;

	miVector original_point = state->point;
	miRay_type ray_type = state->type;
	// Primitive intersection is the bounding box, set to null to be able
	// to do the ray marching
	struct miRc_intersection* original_state_pri = state->pri;
	state->pri = NULL;

	// Since we are going to call the density shader several times,
	// tell the shader to cache the values
	state->type = static_cast<miRay_type>(ALLOC_CACHE);
	mi_call_shader_x(nullptr, miSHADER_MATERIAL, state, density_shader,
			nullptr);

	for (distance = state->dist; distance >= 0; distance -= march_increment) {
		miaux_march_point(&state->point, &origin, &direction, distance);

		state->type = static_cast<miRay_type>(DENSITY_CACHE);
		mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
				density_shader, nullptr);
		state->type = ray_type;

#ifdef DEBUG_SIGMA_A
		VoxelDatasetColor *voxels =
		(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		miColor sigma_a;
		miaux_get_sigma_a(&sigma_a, &state->point, voxels);
		density = std::max(std::max(sigma_a.r, sigma_a.g), sigma_a.b)
		* pow(10, 12);
#endif
		if (density > 0) {
			// Here is where the equation is solved
			// L_current = exp(a * march) * L_next_march + (1 - exp(a *march)) * L_e
			miaux_get_sigma_a(&sigma_a, &state->point, voxels, accessor);
			density *= density_scale * march_increment;
			miaux_total_light_at_point(&light_color, state, light, n_light);

			//sigma_a * L_e
			miaux_multiply_colors(&l_e, &sigma_a, &light_color);

			// e^(- sigma_a * dx)*L(x + dx)
			volume_color.r *= exp(-sigma_a.r * march_increment);
			volume_color.g *= exp(-sigma_a.g * march_increment);
			volume_color.b *= exp(-sigma_a.b * march_increment);

			// L_x = e^(- sigma_a * dx)*L(x + dx) + sigma_a * L_e
			miScalar new_alpha = volume_color.a + density;
			if (new_alpha > 1.0) {
				density = 1.0 - volume_color.a;
			}
			volume_color.r += l_e.r * density;
			volume_color.g += l_e.g * density;
			volume_color.b += l_e.b * density;
			volume_color.a += density;
		}
		if (volume_color.a == 1.0) {
			break;
		}
	}
	// Note changing result->color or result->transparecy alpha channel
	// has no effect, the transparency is controlled with the transparency
	// rgb channels
	miaux_copy_color(&result->color, &volume_color);

	// In RGBA, 0 alpha is transparent, but in in transparency for maya
	// volumetric 1 is transparent
	miaux_set_rgb(&result->transparency, 1 - volume_color.a);

	state->type = static_cast<miRay_type>(FREE_CACHE);
	mi_call_shader_x(nullptr, miSHADER_MATERIAL, state, density_shader,
			nullptr);

	state->type = ray_type;
	state->point = original_point;
	state->pri = original_state_pri;
}

void miaux_vector_info(const char* s, const miVector& v) {
	mi_info("%s %f, %f, %f", s, v.x, v.y, v.z);
}

void miaux_vector_info(const char* s, const miGeoVector& v) {
	mi_info("%s %f, %f, %f", s, v.x, v.y, v.z);
}

void miaux_vector_info(const char* s, const miColor& v) {
	mi_info("%s %f, %f, %f, %f", s, v.r, v.g, v.b, v.a);
}

void miaux_matrix_info(const char* s, const miMatrix& v) {
	mi_info("%s %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, "
			"%f", s, v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9],
			v[10], v[11], v[12], v[13], v[14], v[15]);
}
