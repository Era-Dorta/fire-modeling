#include <iostream>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"
#include "VoxelDatasetColor.h"

//#define DEBUG_SIGMA_A

struct fire_volume {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
	miTag density_shader;
	miScalar density_scale;
	miScalar shadow_scale;
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
	} else {

		/* Instance initialization: */
		mi_info("Precomputing sigma_a");

		miScalar density_scale = *mi_eval_scalar(&params->density_scale);
		miTag density_shader = *mi_eval_tag(&params->density_shader);

		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_alloc_user_memory(state,
						sizeof(VoxelDatasetColor));

		openvdb::initialize();
		// Placement new, initialisation of malloc memory block
		voxels = new (voxels) VoxelDatasetColor();

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		unsigned width, height, depth;
		miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
				density_shader);

		miaux_copy_sparse_voxel_dataset(voxels, state, density_shader, width,
				height, depth, density_scale, 0);

		// TODO Not sure were this should go here or what to do
		std::string data_file(LIBRARY_DATA_PATH);
		data_file = data_file + "/Propane.optconst";
		voxels->compute_soot_absorption_threaded(data_file.c_str());

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;

		mi_info("Done precomputing sigma_a with dataset size %dx%dx%d", width,
				height, depth);
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_exit(miState *state,
		struct fire_volume *params) {
	if (params != NULL) {

		// Call the destructor manually because we had to use placement new
		void * user_pointer = miaux_get_user_memory_pointer(state);
		((VoxelDatasetColor *) user_pointer)->~VoxelDatasetColor();
		mi_mem_release(user_pointer);

	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume(VolumeShader_R *result,
		miState *state, struct fire_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miColor *color = mi_eval_color(&params->color);
	//miColor *glowColor = mi_eval_color(&params->glowColor);
	//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
	//miColor *transparency = mi_eval_color(&params->transparency);
	miScalar density_scale = *mi_eval_scalar(&params->density_scale);
	miScalar march_increment = *mi_eval_scalar(&params->march_increment);
	miTag density_shader = *mi_eval_tag(&params->density_shader);

	// Transform to object space, as voxel_shader and the voxel object assume
	// a cube centred at origin of unit width, height and depth
	miVector origin, direction;
	mi_point_to_object(state, &origin, &state->org);
	mi_vector_to_object(state, &direction, &state->dir);

	if (state->type == miRAY_SHADOW) {
		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		if (!cast_shadows) { // Object is fully transparent, do nothing
			return miFALSE;
		}
		miScalar shadow_scale = *mi_eval_scalar(&params->shadow_scale);
		shadow_scale = pow(10, shadow_scale);
		/*
		 * Seems to be affected only by transparency, 0 to not produce hard
		 * shadows (default) effect, 1 to let that colour pass
		 * result->transparency.r = 1; // Red shadow
		 */
		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);

#ifndef DEBUG_SIGMA_A
		miaux_fractional_shader_occlusion_at_point(&result->transparency,
				&origin, &direction, state->dist, march_increment, shadow_scale,
				voxels);
		return miTRUE;
#else
		return miFALSE;
#endif
	} else {
		if (state->dist == 0.0) /* infinite dist: outside volume */
			return (miTRUE);

		miaux_initialize_volume_output(result);

		miInteger i_light = *mi_eval_integer(&params->i_light);
		miInteger n_light = *mi_eval_integer(&params->n_light);
		miTag *light = mi_eval_tag(&params->light) + i_light;

		// Only the light specified in the light list will be used
		mi_inclusive_lightlist(&n_light, &light, state);

		VoxelDatasetColor *voxels =
				(VoxelDatasetColor *) miaux_get_user_memory_pointer(state);
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

		for (distance = state->dist; distance >= 0; distance -=
				march_increment) {
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
				miaux_get_sigma_a(&sigma_a, &state->point, voxels);
				density *= density_scale * march_increment;
				miaux_total_light_at_point(&light_color, state, light, n_light);
				miaux_multiply_colors(&l_e, color, &light_color);

				//sigma_a * L_e
				l_e.r *= sigma_a.r;
				l_e.g *= sigma_a.g;
				l_e.b *= sigma_a.b;

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
	return miTRUE;
}
