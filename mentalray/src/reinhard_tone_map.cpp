/*
 * reinhard_tone_map.cpp
 *
 *  Created on: 23 Feb 2016
 *      Author: gdp24
 */

#include "shader.h"

#include "miaux.h"

struct reinhard_tone_map {
	miScalar white_point;
	miScalar image_exposure;
	miScalar gamma;
	miScalar schlick_coeff;
};

void remove_specials(float &v) {
	if (isnan(v) || isnan(-v) || isinf(v) || isinf(-v)) {
		v = 0;
	}
}

void remove_specials(miColor& v) {
	remove_specials(v.r);
	remove_specials(v.g);
	remove_specials(v.b);
}

static void clamp(float &v, float min, float max) {
	if (v < min) {
		v = min;
		return;
	}
	if (v > max) {
		v = max;
		return;
	}
}

static void clamp(miColor& v, float min, float max) {
	clamp(v.r, min, max);
	clamp(v.g, min, max);
	clamp(v.b, min, max);
}

extern "C" DLLEXPORT miBoolean reinhard_tone_map(void *result, miState *state,
		struct reinhard_tone_map *paras) {
	const miScalar white_point = *mi_eval_scalar(&paras->white_point);
	const miScalar image_exposure = *mi_eval_scalar(&paras->image_exposure);
	const miScalar gamma = *mi_eval_scalar(&paras->gamma);
	const miScalar schlick_coeff = *mi_eval_scalar(&paras->schlick_coeff);

	int x, y;
	miColor color, color_xyz;
	miImg_image *fb_color;
	const int num_pixels = state->camera->y_resolution
			* state->camera->x_resolution;

	// This section is heavily inspired by the Reinhard Tone Mapping code
	// in https://github.com/banterle/HDR_Toolbox
	const float inv_gamma = 1.0 / gamma;
	float lMax = 0, lMin = FLT_MAX;

	fb_color = mi_output_image_open(state, miRC_IMAGE_RGBA);

	// Computer the e^(mean(luminance)), max luminance and min luminance
	float exp_mean_log = 0;
	for (y = 0; y < state->camera->y_resolution; y++) {
		if (mi_par_aborted()) {
			break;
		}
		for (x = 0; x < state->camera->x_resolution; x++) {
			mi_img_get_color(fb_color, &color, x, y);

			miaux_copy_color(&color_xyz, &color);

			mi_colorprofile_render_to_ciexyz(&color_xyz);

			if (lMax < color_xyz.g) {
				lMax = color_xyz.g;
			}

			if (lMin > color_xyz.g) {
				lMin = color_xyz.g;
			}

			exp_mean_log += log(color_xyz.g + 1e-6);
		}
	}
	exp_mean_log = exp(exp_mean_log / num_pixels);

	const float log2Max = log2(lMax + 1e-9);
	const float log2Min = log2(lMin + 1e-9);

	// Estimate the white point luminance
	float pWhite2;
	if (white_point == 0) {
		pWhite2 = 1.5 * pow(2, log2Max - log2Min - 5);
	} else {
		pWhite2 = white_point;
	}
	pWhite2 = pWhite2 * pWhite2;

	// Estimate the image exposure
	float pAlpha;
	if (image_exposure == 0) {
		pAlpha = 0.18
				* pow(4,
						((2.0 * log2(exp_mean_log + 1e-9) - log2Min - log2Max)
								/ (log2Max - log2Min)));
	} else {
		pAlpha = image_exposure;
	}

	mi_info("Exposure: %f, White: %f, Gamma: %f, Schlick %f", pAlpha, pWhite2,
			gamma, schlick_coeff);

	// Compute visual adaptation with the previous value
	for (y = 0; y < state->camera->y_resolution; y++) {
		if (mi_par_aborted()){
			break;
		}
		for (x = 0; x < state->camera->x_resolution; x++) {
			miColor color_rgb_adapted, color_rgb;

			mi_img_get_color(fb_color, &color_rgb, x, y);

			miaux_copy_color(&color_xyz, &color_rgb);

			mi_colorprofile_render_to_ciexyz(&color_xyz);

			// Remove negative RGB values
			clamp(color_rgb, 0, FLT_MAX);

			// Compute new luminance as in Reinhard et. al. 2002
			// "Photographic tone reproduction for digital images"
			float new_l = (pAlpha * color_xyz.g) / exp_mean_log;
			new_l = (new_l * (1 + new_l / pWhite2)) / (1 + new_l);

			// Apply luminance change to the original RGB color
			miaux_copy_color_scaled(&color_rgb_adapted, &color_rgb,
					new_l / color_xyz.g);

			remove_specials(color_rgb_adapted);

			miaux_copy_color(&color_xyz, &color_rgb_adapted);

			mi_colorprofile_render_to_ciexyz(&color_xyz);

			// Apply Schlick color correction
			color_rgb_adapted.r = pow(color_rgb_adapted.r / color_xyz.g,
					schlick_coeff) * color_xyz.g;
			color_rgb_adapted.g = pow(color_rgb_adapted.g / color_xyz.g,
					schlick_coeff) * color_xyz.g;
			color_rgb_adapted.b = pow(color_rgb_adapted.b / color_xyz.g,
					schlick_coeff) * color_xyz.g;

			remove_specials(color_rgb_adapted);

			// Apply Gamma correction
			color_rgb_adapted.r = pow(color_rgb_adapted.r, inv_gamma);
			color_rgb_adapted.g = pow(color_rgb_adapted.g, inv_gamma);
			color_rgb_adapted.b = pow(color_rgb_adapted.b, inv_gamma);

			// Final clamping for [0..1] RGB space
			clamp(color_rgb_adapted, 0, 1);

			// Keep the original transparency
			color_rgb_adapted.a = color_rgb.a;

			mi_img_put_color(fb_color, &color_rgb_adapted, x, y);
		}
	}

	mi_output_image_close(state, miRC_IMAGE_RGBA);

	return (miTRUE);
}
