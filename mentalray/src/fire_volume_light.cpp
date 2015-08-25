#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "FuelTypes.h"
#include "miaux.h"
#include "VoxelDatasetColorSorted.h"

//#define DEBUG_SIGMA_A

#define INV_SIZE (1.0 / (MAX_DATASET_DIM - 1.0)) * 2

struct fire_volume_light {
	miTag bb_shader;
	miTag sigma_a_shader;
	miInteger fuel_type;
	miScalar temperature_scale;
	miScalar temperature_offset;
	miScalar visual_adaptation_factor;
	miScalar shadow_threshold;
	miScalar intensity;
	miScalar decay;
};

extern "C" DLLEXPORT int fire_volume_light_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_light_init(miState *state,
		struct fire_volume_light *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
		miaux_initialize_external_libs();
	} else {
		/* Instance initialization: */
		FuelType fuel_type = static_cast<FuelType>(*mi_eval_integer(
				&params->fuel_type));
		if (fuel_type != BlackBody) {
			mi_info("Premultiplying bb radiation and sigma_a");

			miVector original_point = state->point;
			miRay_type ray_type = state->type;

			miTag bb_shader = *mi_eval_tag(&params->bb_shader);
			miTag sigma_a_shader = *mi_eval_tag(&params->sigma_a_shader);

			// Get background values
			miColor background_bb;
			state->type = static_cast<miRay_type>(BACKGROUND);
			mi_call_shader_x(&background_bb, miSHADER_MATERIAL, state,
					bb_shader, nullptr);

			miColor background_sigma;
			state->type = static_cast<miRay_type>(BACKGROUND);
			mi_call_shader_x(&background_sigma, miSHADER_MATERIAL, state,
					sigma_a_shader, nullptr);

			miColor background;
			miaux_multiply_colors(&background, &background_bb,
					&background_sigma);

			VoxelDatasetColorSorted *voxels =
					(VoxelDatasetColorSorted *) miaux_alloc_user_memory(state,
							sizeof(VoxelDatasetColorSorted));

			// Placement new, initialisation of malloc memory block
			voxels = new (voxels) VoxelDatasetColorSorted(background);

			// Since we are going to call the density shader several times,
			// tell the shader to cache the values
			bool alloc_bb = miaux_manage_shader_cach(state, bb_shader,
					ALLOC_CACHE);
			bool alloc_sigma = miaux_manage_shader_cach(state, sigma_a_shader,
					ALLOC_CACHE);

			unsigned width = 0, height = 0, depth = 0;
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					bb_shader);
			voxels->resize(width, height, depth);

			state->type = static_cast<miRay_type>(DENSITY_RAW_CACHE);

			miColor bb_radiation = { 0, 0, 0, 0 }, sigma_a = { 0, 0, 0, 0 };
			openvdb::Vec3f bb_sigma_v = openvdb::Vec3f::zero();
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
						mi_call_shader_x(&bb_radiation, miSHADER_MATERIAL,
								state, bb_shader, NULL);
						mi_call_shader_x(&sigma_a, miSHADER_MATERIAL, state,
								sigma_a_shader, NULL);
						miColor bb_sigma;
						miaux_multiply_colors(&bb_sigma, &bb_radiation,
								&sigma_a);

						bb_sigma_v.x() = bb_sigma.r;
						bb_sigma_v.y() = bb_sigma.g;
						bb_sigma_v.z() = bb_sigma.b;

						if (!miaux_color_is_black(&bb_sigma)) {
							voxels->set_voxel_value(i, j, k, bb_sigma_v);
						}
					}
				}
			}

			// Since we copied the data manually, we need to call sort and
			// maximum voxel so that the VoxelDataset is correctly initialized
			voxels->sort();
			voxels->compute_max_voxel_value();

			if (alloc_bb) {
				miaux_manage_shader_cach(state, bb_shader, FREE_CACHE);
			}
			if (alloc_sigma) {
				miaux_manage_shader_cach(state, sigma_a_shader, FREE_CACHE);
			}

			// Restore previous state
			state->point = original_point;
			state->type = ray_type;

			mi_info("Done premultiplying bb radiation and sigma_a");
		} else {
			miVector original_point = state->point;
			miRay_type ray_type = state->type;

			miTag bb_shader = *mi_eval_tag(&params->bb_shader);

			// Get background values
			miColor background_bb;
			state->type = static_cast<miRay_type>(BACKGROUND);
			mi_call_shader_x(&background_bb, miSHADER_MATERIAL, state,
					bb_shader, nullptr);

			VoxelDatasetColorSorted *voxels =
					(VoxelDatasetColorSorted *) miaux_alloc_user_memory(state,
							sizeof(VoxelDatasetColorSorted));

			// Placement new, initialisation of malloc memory block
			voxels = new (voxels) VoxelDatasetColorSorted(background_bb);

			// Since we are going to call the density shader several times,
			// tell the shader to cache the values
			bool alloc_bb;
			alloc_bb = miaux_manage_shader_cach(state, bb_shader, ALLOC_CACHE);

			unsigned width = 0, height = 0, depth = 0;
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					bb_shader);

			state->type = static_cast<miRay_type>(DENSITY_RAW_CACHE);
			voxels->resize(width, height, depth);
			miColor bb_radiation = { 0, 0, 0, 0 };
			openvdb::Vec3f bb_radiation_v = openvdb::Vec3f::zero();
			for (unsigned i = 0; i < width; i++) {
				for (unsigned j = 0; j < height; j++) {
					for (unsigned k = 0; k < depth; k++) {
						state->point.x = i;
						state->point.y = j;
						state->point.z = k;
						// TODO Modify voxel_density to copy only the sparse values
						mi_call_shader_x(&bb_radiation, miSHADER_MATERIAL,
								state, bb_shader, NULL);

						bb_radiation_v.x() = bb_radiation.r;
						bb_radiation_v.y() = bb_radiation.g;
						bb_radiation_v.z() = bb_radiation.b;

						if (bb_radiation.r != background_bb.r
								&& bb_radiation.g != background_bb.g
								&& bb_radiation.b != background_bb.b) {
							voxels->set_voxel_value(i, j, k, bb_radiation_v);
						}
					}
				}
			}

			// Since we copied the data manually, we need to call sort and
			// maximum voxel so that the VoxelDataset is correctly initialized
			voxels->sort();
			voxels->compute_max_voxel_value();

			if (alloc_bb) {
				miaux_manage_shader_cach(state, bb_shader, FREE_CACHE);
			}

			// Restore previous state
			state->point = original_point;
			state->type = ray_type;
		}
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_light_exit(miState *state,
		struct fire_volume_light *params) {
	if (params != NULL) {
		// Call the destructor manually because we had to use placement new
		void * user_pointer = miaux_get_user_memory_pointer(state);
		((VoxelDatasetColorSorted *) user_pointer)->~VoxelDatasetColorSorted();
		mi_mem_release(user_pointer);
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_light(miColor *result,
		miState *state, struct fire_volume_light *params) {

	VoxelDatasetColorSorted *voxels =
			(VoxelDatasetColorSorted *) miaux_get_user_memory_pointer(state);

	miScalar intensity = *mi_eval_scalar(&params->intensity);

	// Get the maximum value and say this light has that colour
	miaux_copy_color_scaled(result, &voxels->get_max_voxel_value(), intensity);

	// If a shape were associated with the light this would handle the calls if
	// the light was set to visible, in our case it never happens, but it is a
	// safe check
	if (state->type != miRAY_LIGHT) {
		return (miTRUE);
	}

	miScalar shadow_threshold = *mi_eval_scalar(&params->shadow_threshold);

	// Set light position from the handler, this comes in internal space
	mi_query(miQ_LIGHT_ORIGIN, state, state->light_instance, &state->org);

	// TODO If asked for more samples than we have in the voxel, we could start
	// interpolating between the value the interpolation code is there, what is
	// needed is to decide where to place the points

	// If no more voxel data then return early
	if (state->count >= voxels->getTotal()) {
		return ((miBoolean) 2);
	}
	VoxelDatasetColorSorted::Accessor accessor = voxels->get_accessor();
	miColor voxel_c = voxels->get_sorted_voxel_value(state->count, accessor);

	// If the contribution is too small return early
	if (voxel_c.r < shadow_threshold && voxel_c.g < shadow_threshold
			&& voxel_c.b < shadow_threshold) {
		return ((miBoolean) 2);
	}

	// Set the colour using the next value
	miaux_copy_color_scaled(result, &voxel_c, intensity);

	// Move the light origin to the voxel position
	const miVector minus_one = { -1, -1, -1 };
	miVector offset_light, offset_internal;

	voxels->get_i_j_k_from_sorted(offset_light, state->count);

	// The voxel data set goes from {-1,-1,-1} to {1,1,1}, so with
	// i,j,k = (SIZE / 2) it should be 1, to cancel the offset and
	// with i,j,k = SIZE, then it should be 2, to be 1 above the offset
	mi_vector_mul(&offset_light, INV_SIZE);

	mi_vector_add(&offset_light, &offset_light, &minus_one);

	// {-1,-,1,-1} is for a light at origin without rotation, so transform
	// from light space to internal, to account for that
	mi_vector_from_light(state, &offset_internal, &offset_light);

	mi_vector_add(&state->org, &state->org, &offset_internal);

	// dir is vector from light origin to primitive intersection point
	mi_vector_sub(&state->dir, &state->point, &state->org);

	// Distance is the norm of dir
	state->dist = mi_vector_norm(&state->dir);

	// Normalise dir using dist, more efficient than computing directly dir
	// normalised and computing the norm again for dir
	mi_vector_div(&state->dir, state->dist);

	// N.b. seems like the direction for the shadows to work has to be
	// origin -> point, but for the shaders to work, it has to be
	// point -> origin, options include switching the normal or changing the
	// direction again after calling mi_trace_shadow
	miVector aux;
	miaux_copy_vector_neg(&aux, &state->dir);
	state->dot_nd = mi_vector_dot(&aux, &state->normal);

	// Distance falloff
	miScalar decay = *mi_eval_scalar(&params->decay);
	miaux_scale_color(result, 1.0 / (4 * M_PI * pow(state->dist, decay)));

	if (result->r < shadow_threshold && result->g < shadow_threshold
			&& result->b < shadow_threshold) {
		// If the contribution is too small return early
		return ((miBoolean) 2);
	} else {
		return mi_trace_shadow(result, state);
	}
}
