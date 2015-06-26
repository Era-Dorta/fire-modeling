#include <iostream>
#include <thread>
#include <vector>

#include "shader.h"
#include "mayaapi.h"

#include "miaux.h"

// Go to SphereFogSG and add this as its volume shader in the mental ray tab
// in custom shaders

struct parameter_volume {
	miColor color;
	miColor glowColor;
	miColor matteOpacity;
	miColor transparency;
	miTag density_shader;
	miScalar unit_density;
	miScalar march_increment;
};

extern "C" DLLEXPORT int parameter_volume_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean parameter_volume_init(miState *state,
		struct parameter_volume *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
	} else {
		/* Instance initialization: */
		mi_warning("Precomputing sigma_a");
		miTag density_shader = *mi_eval_tag(&params->density_shader);
		voxel_data *voxels = (voxel_data *) miaux_user_memory_pointer(state,
				sizeof(voxel_data));

		// Save previous state
		miVector original_point = state->point;
		miRay_type ray_type = state->type;

		int width, height, depth;
		miaux_get_voxel_dataset_dims(state, density_shader, &width, &height,
				&depth);

		miaux_copy_voxel_dataset(state, density_shader, voxels, width, height,
				depth);

		// Get thread hint, i.e. number of cores
		unsigned num_threads = std::thread::hardware_concurrency();

		// Get are at least able to run one thread
		if (num_threads == 0) {
			num_threads = 1;
		}

		// Cap the number of threads if there is not enough work for each one
		if ((unsigned) depth < num_threads) {
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
							density_shader, 0, 0, i_depth, width, height,
							e_depth));
			i_depth = e_depth + 1;
			e_depth = e_depth + thread_chunk;
		}

		// The remaining will be handled by the current thread
		miaux_compute_sigma_a(voxels, state, density_shader, 0, 0, i_depth,
				width, height, depth - 1);

		// Wait for the other threads to finish
		for (auto& thread : threads) {
			thread.join();
		}

		// Restore previous state
		state->point = original_point;
		state->type = ray_type;
		mi_warning("Done precomputing sigma_a with dataset size %dx%dx%d",
				width, height, depth);
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean parameter_volume_exit(miState *state,
		void *params) {
	return miaux_release_user_memory("parameter_volume", state, params);
}

extern "C" DLLEXPORT miBoolean parameter_volume(VolumeShader_R *result,
		miState *state, struct parameter_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miColor *color = mi_eval_color(&params->color);
	//miColor *glowColor = mi_eval_color(&params->glowColor);
	//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
	//miColor *transparency = mi_eval_color(&params->transparency);
	miScalar unit_density = *mi_eval_scalar(&params->unit_density);
	miScalar march_increment = *mi_eval_scalar(&params->march_increment);
	miTag density_shader = *mi_eval_tag(&params->density_shader);

	if (state->type == miRAY_SHADOW) {
		/*
		 * Seems to be affected only by transparency, 0 to not produce hard
		 * shadows (default) effect, 1 to let that colour pass
		 * result->transparency.r = 1; // Red shadow
		 */
		miScalar occlusion = miaux_fractional_shader_occlusion_at_point(state,
				&state->org, &state->dir, state->dist, density_shader,
				unit_density, march_increment);
		miaux_set_rgb(&result->transparency, 1.0 - occlusion);
		return miTRUE;
	} else {
		if (state->dist == 0.0) /* infinite dist: outside volume */
			return (miTRUE);

		miaux_initialize_volume_output(result);

		miScalar distance, density;
		miColor volume_color = { 0, 0, 0, 0 }, light_color, point_color;
		miVector original_point = state->point;
		// Primitive intersection is the bounding box, set to null to be able
		// to do the ray marching
		struct miRc_intersection* original_state_pri = state->pri;
		state->pri = NULL;

		for (distance = state->dist; distance >= 0; distance -=
				march_increment) {
			miVector march_point;
			miaux_march_point(&march_point, state, distance);
			state->point = march_point;
			mi_call_shader_x((miColor*) &density, miSHADER_MATERIAL, state,
					density_shader, NULL);
			//density = 1;
			if (density > 0) {
				// Here is where the equation is solved
				// exp(-a * march) * L_next_march + (1 - exp(-a *march)) * L_e
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

		miaux_copy_color(&result->color, &volume_color);
		// In RGBA, 0 alpha is transparent, but in in transparency for maya
		// volumetric 1 is transparent
		miaux_set_rgb(&result->transparency, 1 - volume_color.a);

		state->point = original_point;
		state->pri = original_state_pri;
	}
	return miTRUE;
}
