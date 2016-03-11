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
#define PIC_DISABLE_EIGEN
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
	miScalar white_point; // For ReinhardTMO
	miScalar image_exposure; // For ReinhardTMO
	miScalar wC; // For Exposure Fusion
	miScalar wE; // For Exposure Fusion
	miScalar wS; // For Exposure Fusion
	miScalar gamma; // For Gamma correction
	miScalar f_stop; // For Exposure correction
};

extern "C" DLLEXPORT int piccante_tone_map_version(void) {
	return 1;
}

extern "C" DLLEXPORT miBoolean piccante_tone_map(void *result, miState *state,
		struct piccante_tone_map *paras) {
	const miInteger tm_operator = *mi_eval_integer(&paras->tm_operator);
	const miScalar gamma = *mi_eval_scalar(&paras->gamma);
	const miScalar f_stop = *mi_eval_scalar(&paras->f_stop);

	if (gamma <= 0) {
		mi_error("reinhard_tone_map: Gamma must be a positive scalar");
		return miTRUE;
	}

	// Open the color buffer
	miImg_image *fb_color = mi_output_image_open(state, miRC_IMAGE_RGBA);

	if (fb_color->comp < 3) {
		mi_error("Tone mapper only supports color images");
		return miFALSE;
	}

	pic::Image img0(fb_color->width, fb_color->height, 3);

	miColor color;

	// Copy the buffer to img0
	for (int y = 0; y < state->camera->y_resolution; y++) {
		if (mi_par_aborted()) {
			break;
		}
		for (int x = 0; x < state->camera->x_resolution; x++) {

			mi_img_get_color(fb_color, &color, x, y);

			float *img_pix = img0(x, y);
			img_pix[0] = color.r;
			img_pix[1] = color.g;
			img_pix[2] = color.b;
		}
	}

	switch (tm_operator) {
	case 0: { // Reinhard
		const miScalar white_point = *mi_eval_scalar(&paras->white_point);
		const miScalar image_exposure = *mi_eval_scalar(&paras->image_exposure);

		pic::ReinhardTMO(&img0, &img0, image_exposure, white_point);

		// Apply gamma correction and save the result in img0
		pic::FilterSimpleTMO::Execute(&img0, &img0, gamma, f_stop);
		break;
	}
	case 1: { // Exposure Fusion
		const miScalar wC = *mi_eval_scalar(&paras->wC);
		const miScalar wE = *mi_eval_scalar(&paras->wE);
		const miScalar wS = *mi_eval_scalar(&paras->wS);

		// Exposure fusion requires a stack of LDR images
		pic::ImageVec stack = pic::getAllExposuresImages(&img0);

		for (auto& i : stack) {
			i->clamp(0.0f, 1.0f);
		}

		pic::ExposureFusion(stack, wC, wE, wS, &img0);

		pic::FilterSimpleTMO::Execute(&img0, &img0, 1.0f, f_stop);
		break;
	}
	case 2: { // Only Gamma Correction

		pic::FilterSimpleTMO::Execute(&img0, &img0, gamma, f_stop);
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
			float *img_pix = img0(x, y);
			color.r = img_pix[0];
			color.g = img_pix[1];
			color.b = img_pix[2];

			mi_img_put_color(fb_color, &color, x, y);
		}
	}

	mi_output_image_close(state, miRC_IMAGE_RGBA);

	return miTRUE;
}
