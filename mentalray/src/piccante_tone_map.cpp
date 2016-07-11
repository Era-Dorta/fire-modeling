/*
 * piccante_tone_map.cpp
 *
 *  Created on: 23 Feb 2016
 *      Author: gdp24
 */

#include "shader.h"

// Disable warnings for piccante if using gcc
#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wswitch"
#pragma GCC diagnostic ignored "-Wdelete-non-virtual-dtor"
#pragma GCC diagnostic ignored "-Wunused-result"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#pragma GCC diagnostic ignored "-Wformat"
#endif /* __GNUC__ */

// Disable QT and OpenGL in piccate as we don't need them
#define PIC_DISABLE_OPENGL
#define PIC_DISABLE_QT

#include <cstring> // For memcpy in piccante
#include <climits> // For INT_MAX in piccante
#include "piccante.hpp"

#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif /* __GNUC__ */

struct piccante_tone_map {
	miInteger tm_operator;
	miScalar white_point; // For ReinhardTMO/LischinskiTMO
	miScalar image_exposure; // For ReinhardTMO/LischinskiTMO
	miScalar sharpenning; // For ReinhardTMO
	miScalar weight_contrast; // For Exposure Fusion
	miScalar weight_exposedness; // For Exposure Fusion
	miScalar weight_saturation; // For Exposure Fusion
	miScalar gamma; // For Gamma correction
	miScalar f_stop; // For Exposure correction
};

void get_default_parameters(pic::Image *img_in, float &image_exposure,
		float &white_point) {
	if (image_exposure <= 0.0f || white_point <= 0.0f) {
		// If the user is using automated estimation, compute the actual values
		// so that they can be reused
		pic::Image *lum = pic::FilterLuminance::Execute(img_in, nullptr,
				pic::LT_CIE_LUMINANCE);

		float l_max = lum->getMaxVal()[0];
		float l_min = lum->getMinVal()[0];

		if (white_point <= 0.0f) {
			white_point = pic::EstimateWhitePoint(l_max, l_min);
			mi_info("Tone mapping: White Point estimate %e", white_point);
		}

		if (image_exposure <= 0.0f) {
			float log_average = lum->getLogMeanVal()[0];
			image_exposure = pic::EstimateAlpha(l_max, l_min, log_average);
			mi_info("Tone mapping: Image Exposure estimate %e", image_exposure);
		}

	}
}

extern "C" DLLEXPORT int piccante_tone_map_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean piccante_tone_map(void *result, miState *state,
		struct piccante_tone_map *paras) {
	const miInteger tm_operator = *mi_eval_integer(&paras->tm_operator);

	if (tm_operator == 4) { // Do nothing operator
		return miTRUE;
	}

	const miScalar gamma = *mi_eval_scalar(&paras->gamma);
	const miScalar f_stop = *mi_eval_scalar(&paras->f_stop);

	if (gamma <= 0) {
		mi_error("reinhard_tone_map: Gamma must be a positive scalar");
		return miTRUE;
	}

	// Open the color buffer
	miImg_image *fb_color = mi_output_image_open(state, miRC_IMAGE_RGBA);

	if (fb_color->comp < 3) {
		mi_output_image_close(state, miRC_IMAGE_RGBA);
		mi_error("Tone mapper only supports color images");
		return miFALSE;
	}

	pic::Image pic_img(fb_color->width, fb_color->height, 3);

	miColor color;

	// Copy the buffer to img0
	for (int y = 0; y < state->camera->y_resolution; y++) {
		if (mi_par_aborted()) {
			break;
		}
		for (int x = 0; x < state->camera->x_resolution; x++) {

			mi_img_get_color(fb_color, &color, x, y);

			float *img_pix = pic_img(x, y);
			img_pix[0] = color.r;
			img_pix[1] = color.g;
			img_pix[2] = color.b;
		}
	}

	switch (tm_operator) {
	case 0: { // Only Gamma Correction
		pic::FilterSimpleTMO::Execute(&pic_img, &pic_img, gamma, f_stop);
		break;
	}
	case 1: { // Exposure Fusion
		const miScalar wC = *mi_eval_scalar(&paras->weight_contrast);
		const miScalar wE = *mi_eval_scalar(&paras->weight_exposedness);
		const miScalar wS = *mi_eval_scalar(&paras->weight_saturation);

		// Exposure fusion requires a stack of LDR images
		pic::ImageVec stack = pic::getAllExposuresImages(&pic_img);

		for (auto& i : stack) {
			i->clamp(0.0f, 1.0f);
		}

		pic::ExposureFusion(stack, wC, wE, wS, &pic_img);

		// Exposure fusion doesn't need gamma correction, but we can apply
		// exposure correction
		pic::FilterSimpleTMO::Execute(&pic_img, &pic_img, 1.0f, f_stop);
		break;
	}
	case 2: { // Reinhard
		miScalar white_point = *mi_eval_scalar(&paras->white_point);
		miScalar image_exposure = *mi_eval_scalar(&paras->image_exposure);
		const miScalar sharpenning = *mi_eval_scalar(&paras->sharpenning);

		get_default_parameters(&pic_img, image_exposure, white_point);

		pic::ReinhardTMO(&pic_img, &pic_img, image_exposure, white_point,
				sharpenning);

		// Apply gamma correction
		pic::FilterSimpleTMO::Execute(&pic_img, &pic_img, gamma, f_stop);
		break;
	}
	case 3: { // Lischinski
		miScalar white_point = *mi_eval_scalar(&paras->white_point);
		miScalar image_exposure = *mi_eval_scalar(&paras->image_exposure);

		get_default_parameters(&pic_img, image_exposure, white_point);

		pic::LischinskiTMO(&pic_img, &pic_img, image_exposure, white_point);

		// Apply gamma correction
		pic::FilterSimpleTMO::Execute(&pic_img, &pic_img, gamma, f_stop);
		break;
	}
	default: {
		mi_output_image_close(state, miRC_IMAGE_RGBA);
		mi_error("Invalid tone mapping operator");
		return miFALSE;
	}
	}

	// Copy the tone mapped image to the buffer
	for (int y = 0; y < state->camera->y_resolution; y++) {
		if (mi_par_aborted()) {
			break;
		}
		for (int x = 0; x < state->camera->x_resolution; x++) {
			float *img_pix = pic_img(x, y);
			color.r = img_pix[0];
			color.g = img_pix[1];
			color.b = img_pix[2];

			mi_img_put_color(fb_color, &color, x, y);
		}
	}

	mi_output_image_close(state, miRC_IMAGE_RGBA);

	return miTRUE;
}
