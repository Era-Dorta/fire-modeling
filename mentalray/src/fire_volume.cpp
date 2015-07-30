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
	miInteger absorption_type;
	miScalar density_scale;
	miScalar shadow_scale;
	miScalar march_increment;
	miBoolean cast_shadows;
	miInteger i_light;	// index of first light
	miInteger n_light;	// number of lights
	miTag light[1];	// list of lights
};

enum AbsorptionType {
	None, Propane, Acetylene, AbsorptionTypeMax = Acetylene
};

static const std::array<std::string, AbsorptionTypeMax + 1> AbsorptionTypeStr {
		"None", "Propane", "Acetylene" };

extern "C" DLLEXPORT int fire_volume_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean fire_volume_init(miState *state,
		struct fire_volume *params, miBoolean *instance_init_required) {
	if (!params) { /* Main shader init (not an instance): */
		*instance_init_required = miTRUE;
		miaux_initialize_external_libs();
	} else {

		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		miInteger absorption_type = *mi_eval_integer(&params->absorption_type);
		if (absorption_type != AbsorptionType::None || cast_shadows) {
			/* Instance initialization: */
			mi_info("Precomputing sigma_a");

			miScalar density_scale = *mi_eval_scalar(&params->density_scale);
			miTag density_shader = *mi_eval_tag(&params->density_shader);

			VoxelDatasetColor *voxels =
					(VoxelDatasetColor *) miaux_alloc_user_memory(state,
							sizeof(VoxelDatasetColor));

			// Placement new, initialisation of malloc memory block
			voxels = new (voxels) VoxelDatasetColor();

			// Save previous state
			miVector original_point = state->point;
			miRay_type ray_type = state->type;

			unsigned width, height, depth;
			miaux_get_voxel_dataset_dims(&width, &height, &depth, state,
					density_shader);

			miaux_copy_sparse_voxel_dataset(voxels, state, density_shader,
					width, height, depth, density_scale, 0);

			std::string data_file(LIBRARY_DATA_PATH);
			assert(
					static_cast<unsigned>(absorption_type)
							< AbsorptionTypeStr.size());
			data_file = data_file + "/" + AbsorptionTypeStr[absorption_type]
					+ ".optconst";
			voxels->compute_soot_absorption_threaded(data_file.c_str());

			// Restore previous state
			state->point = original_point;
			state->type = ray_type;

			mi_info("Done precomputing sigma_a with dataset size %dx%dx%d",
					width, height, depth);
		}
	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume_exit(miState *state,
		struct fire_volume *params) {
	if (params != NULL) {
		miBoolean cast_shadows = *mi_eval_boolean(&params->cast_shadows);
		miInteger absorption_type = *mi_eval_integer(&params->absorption_type);
		if (absorption_type != AbsorptionType::None || cast_shadows) {
			// Call the destructor manually because we had to use placement new
			void * user_pointer = miaux_get_user_memory_pointer(state);
			((VoxelDatasetColor *) user_pointer)->~VoxelDatasetColor();
			mi_mem_release(user_pointer);
		}

	}
	return miTRUE;
}

extern "C" DLLEXPORT miBoolean fire_volume(VolumeShader_R *result,
		miState *state, struct fire_volume *params) {

	// Early return with ray lights to avoid infinite recursion
	if (state->type == miRAY_LIGHT) {
		return miTRUE;
	}

	miScalar march_increment = *mi_eval_scalar(&params->march_increment);

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

		//miColor *color = mi_eval_color(&params->color);
		//miColor *glowColor = mi_eval_color(&params->glowColor);
		//miColor *matteOpacity = mi_eval_color(&params->matteOpacity);
		//miColor *transparency = mi_eval_color(&params->transparency);
		miScalar density_scale = *mi_eval_scalar(&params->density_scale);
		miScalar march_increment = *mi_eval_scalar(&params->march_increment);
		miTag density_shader = *mi_eval_tag(&params->density_shader);
		miInteger absorption_type = *mi_eval_integer(&params->absorption_type);

		miInteger i_light = *mi_eval_integer(&params->i_light);
		miInteger n_light = *mi_eval_integer(&params->n_light);
		miTag *light = mi_eval_tag(&params->light) + i_light;

		// Only the light specified in the light list will be used
		mi_inclusive_lightlist(&n_light, &light, state);

		if (absorption_type == AbsorptionType::None) {
			miaux_ray_march_simple(result, state, density_scale,
					march_increment, density_shader, light, n_light, origin,
					direction);
		} else {
			miaux_ray_march_with_sigma_a(result, state, density_scale,
					march_increment, density_shader, light, n_light, origin,
					direction);
		}
	}
	return miTRUE;
}
