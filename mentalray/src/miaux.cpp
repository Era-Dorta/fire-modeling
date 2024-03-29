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

void miaux_tag_to_string(std::string& tag_str, miTag tag) {
	if (tag != 0) {
		tag_str = std::string(static_cast<const char*>(mi_db_access(tag)));
		mi_db_unpin(tag);
	}
}

double miaux_fit(double v, double oldmin, double oldmax, double newmin,
		double newmax) {
	return newmin + ((v - oldmin) / (oldmax - oldmin)) * (newmax - newmin);
}

void* miaux_get_user_memory_pointer(miState *state) {
	void **user_pointer;
	mi_query(miQ_FUNC_USERPTR, state, miNULLTAG, &user_pointer);
	return *user_pointer;
}

void* miaux_alloc_user_memory(miState *state, int allocation_size) {
	void **user_pointer;
	mi_query(miQ_FUNC_USERPTR, state, miNULLTAG, &user_pointer);
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
}

void miaux_clamp_min_color(miColor *c, miScalar min) {
	if (c->r < min) {
		c->r = min;
	}
	if (c->g < min) {
		c->g = min;
	}
	if (c->b < min) {
		c->b = min;
	}
}

void miaux_march_point(miVector *result, const miVector *point,
		const miVector *direction, miScalar distance) {
	result->x = point->x + distance * direction->x;
	result->y = point->y + distance * direction->y;
	result->z = point->z + distance * direction->z;
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

void miaux_multiply_colors(miColor *result, const miColor *x,
		const miColor *y) {
	result->r = x->r * y->r;
	result->g = x->g * y->g;
	result->b = x->b * y->b;
}

void miaux_multiply_scaled_colors(miColor *result, const miColor *x,
		const miColor *y, miScalar scale) {
	result->r = x->r * y->r * scale;
	result->g = x->g * y->g * scale;
	result->b = x->b * y->b * scale;
}

void miaux_set_channels(miColor *c, miScalar new_value) {
	c->r = c->g = c->b = c->a = new_value;
}

void miaux_set_rgb(miColor *c, miScalar new_value) {
	c->r = c->g = c->b = new_value;
}

void miaux_add_transparent_color(miColor *result, const miColor *color,
		miScalar transparency) {
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

miBoolean miaux_color_is_ge(const miColor& c, miScalar x) {
	return (c.r >= x && c.g >= x && c.b >= x);
}

miBoolean miaux_color_any_is_gt(const miColor& c, miScalar x) {
	return (c.r > x || c.g > x || c.b > x);
}

miBoolean miaux_color_is_lt(const miColor& c, miScalar x) {
	return (c.r < x && c.g < x && c.b < x);
}

miBoolean miaux_color_any_is_lt(const miColor& c, miScalar x) {
	return (c.r < x || c.g < x || c.b < x);
}

miBoolean miaux_color_is_eq(const miColor& c, miScalar x) {
	return (c.r == x && c.g == x && c.b == x);
}

miBoolean miaux_color_any_is_eq(const miColor& c, miScalar x) {
	return (c.r == x || c.g == x || c.b == x);
}

miBoolean miaux_color_is_neq(const miColor& c, miScalar x) {
	return (c.r != x && c.g != x && c.b != x);
}

miBoolean miaux_color_any_is_neq(const miColor& c, miScalar x) {
	return (c.r != x || c.g != x || c.b != x);
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
	state->type = static_cast<miRay_type>(WIDTH);
	mi_call_shader_x((miColor*) &width_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	state->type = static_cast<miRay_type>(HEIGHT);
	mi_call_shader_x((miColor*) &height_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	state->type = static_cast<miRay_type>(DEPTH);
	mi_call_shader_x((miColor*) &depth_s, miSHADER_MATERIAL, state,
			density_shader, NULL);

	*width = (unsigned) width_s;
	*height = (unsigned) height_s;
	*depth = (unsigned) depth_s;
}

void miaux_copy_sparse_voxel_dataset(VoxelDatasetColor *voxels, miState *state,
		miTag density_shader, unsigned width, unsigned height, unsigned depth,
		miScalar scale, miScalar offset) {
	state->type = static_cast<miRay_type>(VOXEL_DATA_COPY);
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
				// using setValueOnly to change values, this assumes background
				// value is zero
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

void miaux_copy_sparse_voxel_dataset(VoxelDatasetColor *voxels, miState *state,
		miTag density_shader, miTag temperature_shader, unsigned width,
		unsigned height, unsigned depth) {
	state->type = static_cast<miRay_type>(VOXEL_DATA_COPY);
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
				// using setValueOnly to change values, this assumes background
				// value is zero
				mi_call_shader_x((miColor*) &density.r, miSHADER_MATERIAL,
						state, temperature_shader, NULL);
				mi_call_shader_x((miColor*) &density.g, miSHADER_MATERIAL,
						state, density_shader, NULL);
				if (density.r != 0.0f) {
					density_v.x() = density.r;
					density_v.y() = density.g;
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

void miaux_fractional_shader_occlusion_at_point(VolumeShader_R *result,
		miState* state, const RayMarchCommonData& rm_data) {
	miColor total_sigma = { 0, 0, 0, 0 };

	miVector original_point = state->point;
	miRay_type ray_type = state->type;

	state->type = static_cast<miRay_type>(VOXEL_DATA);

	// Since the equation is Lx = e^(-sigma_x * delta_x) L_{x + delta}, we can sum all
	// sigmas, and apply the exp with the sum
	int steps = static_cast<int>(state->dist / rm_data.march_increment);
	for (int i = 0; i <= steps; i++) {
		// Compute the distance on each time step to avoid numerical errors
		float distance = rm_data.march_increment * i;

		miaux_march_point(&state->point, &rm_data.origin, &rm_data.direction,
				distance);

		miColor sigma_a;
		// Get all the sigmas along the shadow ray
		mi_call_shader_x(&sigma_a, miSHADER_MATERIAL, state,
				rm_data.absorption_shader, nullptr);

		if (miaux_color_is_ge(sigma_a, 0)) {
			miaux_add_color(&total_sigma, &sigma_a);
		}
	}

	// The transparency will automatically get multiplied by Maya engine
	result->transparency.r = exp(-total_sigma.r * rm_data.march_increment);
	result->transparency.g = exp(-total_sigma.g * rm_data.march_increment);
	result->transparency.b = exp(-total_sigma.b * rm_data.march_increment);

	state->type = ray_type;
	state->point = original_point;
}

void miaux_ray_march_simple(VolumeShader_R *result, miState *state,
		const RayMarchData& rm_data) {

	miColor volume_color = { 0, 0, 0, 0 }, point_color;

	miVector original_point = state->point;
	miRay_type ray_type = state->type;
	// Primitive intersection is the bounding box, set to null to be able
	// to do the ray marching
	struct miRc_intersection* original_state_pri = state->pri;
	state->pri = NULL;

	state->type = static_cast<miRay_type>(VOXEL_DATA);

	double total_transmittance = 1.0; // exp(0)
	int steps = static_cast<int>(state->dist / rm_data.march_increment);
	for (int i = 0; i <= steps; i++) {
		// Compute the distance on each time step to avoid numerical errors
		float distance = rm_data.march_increment * i;

		miaux_march_point(&state->point, &rm_data.origin, &rm_data.direction,
				distance);

		float density;
		mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
				rm_data.density_shader, nullptr);

#ifdef DEBUG_SIGMA_A
		VoxelDatasetColor *voxels =
		(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
		miColor sigma_a;
		miaux_get_sigma_a(&sigma_a, &state->point, voxels);
		density = std::max(std::max(sigma_a.r, sigma_a.g), sigma_a.b)
		* pow(10, 12);
#endif
		if (density > 0) {

			// Here is where the equation is solved, take density as sigma
			// e^(sigma_a * delta_x)
			density = exp(-density * rm_data.march_increment);

			// Get emission at current point, Le
			mi_call_shader_x(&point_color, miSHADER_MATERIAL, state,
					rm_data.emission_shader, nullptr);

			// Clamp negative values that arise when using high order
			// interpolation methods, doing the if and then clamping is faster
			// than just clamping for all the values
			if (miaux_color_any_is_lt(point_color, 0)) {
				miaux_clamp_min_color(&point_color, 0);
			}

			// L_i = L_{i - 1} + exp(-Sum_{j from i-1 to 0} sigma_j * d_x) *
			// 	exp(-sigma_a{i} * d_x) L_e{i}
			miaux_add_scaled_color(&volume_color, &point_color,
					total_transmittance * (1.0f - density));

			// Since the total transmittance is the sum of exp, we can just
			// multiply by the current transmittance
			total_transmittance *= density;
		}
	}

	// Note changing result->color or result->transparency alpha channel
	// has no effect, the transparency is controlled with the transparency
	// rgb channels
	miaux_copy_color_scaled(&result->color, &volume_color,
			rm_data.linear_density);

	// If the total_transmittance is not one it means that some densities were
	// found along the way, this check allows the user only to change the
	// transparency of actual fire pixels
	if (total_transmittance != 1) {
		// Maya transparency -> pixel = background * transparency + foreground
		// Where we are the foreground and transparency is result->transparency
		// Scale with user coefficient
		total_transmittance = Clamp(total_transmittance + rm_data.transparency,
		FLT_EPSILON, 1.0f);
		miaux_set_rgb(&result->transparency, total_transmittance);
	}

	state->type = ray_type;
	state->point = original_point;
	state->pri = original_state_pri;
}

void miaux_ray_march_with_sigma_a(VolumeShader_R *result, miState *state,
		const RayMarchData& rm_data) {

	miColor volume_color = { 0, 0, 0, 0 };
	miColor total_transmittance = { 1.0, 1.0, 1.0, 1.0 }; // exp(0)

	miVector original_point = state->point;
	miRay_type ray_type = state->type;
	// Primitive intersection is the bounding box, set to null to be able
	// to do the ray marching
	struct miRc_intersection* original_state_pri = state->pri;
	state->pri = NULL;

	state->type = static_cast<miRay_type>(VOXEL_DATA);

	// Compute it as steps, so that rounding errors are not carried in the loop

	// This loop is where the equation is solved
	// L_i = L_{i - 1} + exp(-Sum_{j from i-1 to 0} sigma_j * d_x) *
	// 	exp(-sigma_a{i} * d_x) L_e{i}

	int steps = static_cast<int>(state->dist / rm_data.march_increment);
	for (int i = 0; i <= steps; i++) {
		// Compute the distance on each time step to avoid numerical errors
		float distance = rm_data.march_increment * i;
		miaux_march_point(&state->point, &rm_data.origin, &rm_data.direction,
				distance);

		// Get sigma_a at state->point
		miColor sigma_a;
		mi_call_shader_x(&sigma_a, miSHADER_MATERIAL, state,
				rm_data.absorption_shader, nullptr);
		miaux_scale_color(&sigma_a, rm_data.march_increment);

		// Clamp negative values
		if (miaux_color_any_is_lt(sigma_a, 0)) {
			miaux_clamp_min_color(&sigma_a, 0);
		}

		// If the color is black e^sigma_a == 1, thus Lx = L_next_march
		if (miaux_color_any_is_gt(sigma_a, 0)) {
			// Get L_e = sigma_a * black body at state->point
			miColor light_color;
			mi_call_shader_x(&light_color, miSHADER_MATERIAL, state,
					rm_data.emission_shader, nullptr);

			// Clamp negative values
			if (miaux_color_any_is_lt(light_color, 0)) {
				miaux_clamp_min_color(&light_color, 0);
			}

			sigma_a.r = exp(-sigma_a.r);
			sigma_a.g = exp(-sigma_a.g);
			sigma_a.b = exp(-sigma_a.b);

			// If L_e == 0, then Lx = L_next_march
			if (miaux_color_any_is_gt(light_color, 0)) {
				// Compute (1 - exp(-sum_sigma_a * Dx)) * exp(-sigma_a * Dx)
				miColor exp_sigma_dx;
				exp_sigma_dx.r = total_transmittance.r * (1.0f - sigma_a.r);
				exp_sigma_dx.g = total_transmittance.g * (1.0f - sigma_a.g);
				exp_sigma_dx.b = total_transmittance.b * (1.0f - sigma_a.b);

				// weight * Le(x)
				miaux_multiply_colors(&light_color, &light_color,
						&exp_sigma_dx);

				// Sum previous and current contributions
				miaux_add_color(&volume_color, &light_color);
			}
			miaux_multiply_colors(&total_transmittance, &total_transmittance,
					&sigma_a);
		}
	}

	miaux_copy_color_scaled(&result->color, &volume_color,
			rm_data.linear_density);

	if (miaux_color_any_is_neq(total_transmittance, 1)) {
		// Maya transparency -> pixel = background * transparency + foreground
		// Compute transmittance, e^(- sum sigma_a * d_x) and scale with user
		// coefficient
		result->transparency.r = total_transmittance.r + rm_data.transparency;
		result->transparency.g = total_transmittance.g + rm_data.transparency;
		result->transparency.b = total_transmittance.b + rm_data.transparency;
		miaux_clamp_color(&result->transparency, FLT_EPSILON, 1);
	}

	state->type = ray_type;
	state->point = original_point;
	state->pri = original_state_pri;
}

bool miaux_manage_shader_cach(miState* state, miTag shader,
		Voxel_Return action) {
	miColor res = { 1, 1, 1, 1 };
	state->type = static_cast<miRay_type>(action);
	mi_call_shader_x(&res, miSHADER_MATERIAL, state, shader, nullptr);
	return res.r == 1;
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

void miaux_vector_info(const char* s, const openvdb::Vec3f& v) {
	mi_info("%s %f, %f, %f", s, v.x(), v.y(), v.z());
}

void miaux_matrix_info(const char* s, const miMatrix& v) {
	mi_info("%s %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, "
			"%f", s, v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9],
			v[10], v[11], v[12], v[13], v[14], v[15]);
}
