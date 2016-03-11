/*
 * reinhard_tone_map.cpp
 *
 *  Created on: 23 Feb 2016
 *      Author: gdp24
 */

#include "shader.h"

#include "miaux.h"

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

#include "piccante.hpp"

#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif /* __GNUC__ */

struct reinhard_tone_map {
	miScalar white_point;
	miScalar image_exposure;
	miScalar gamma;
	miScalar schlick_coeff;
};

extern "C" DLLEXPORT int reinhard_tone_map_version(void) {
	return 2;
}

extern "C" DLLEXPORT miBoolean reinhard_tone_map(void *result, miState *state,
		struct reinhard_tone_map *paras) {
	const miScalar white_point = *mi_eval_scalar(&paras->white_point);
	const miScalar image_exposure = *mi_eval_scalar(&paras->image_exposure);
	const miScalar gamma = *mi_eval_scalar(&paras->gamma);
	const miScalar schlick_coeff = *mi_eval_scalar(&paras->schlick_coeff);

	// This section is heavily inspired by the Reinhard Tone Mapping code
	// in https://github.com/banterle/HDR_Toolbox
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

	// Apply the tone mapping and save the result in img1
	pic::Image *img1;
	img1 = pic::ReinhardTMO(&img0, nullptr, image_exposure, white_point);

	// Apply gamma correction and save the result in img0
	pic::FilterSimpleTMO::Execute(img1, &img0, gamma, schlick_coeff);

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
