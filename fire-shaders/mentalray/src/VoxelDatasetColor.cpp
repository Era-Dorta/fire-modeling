/*
 * VoxelDatasetColor.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetColor.h"

#include <thread>

#include "RenderingConstants.h"
#include "Spectrum.h"
#include "miaux.h"

VoxelDatasetColor::VoxelDatasetColor() :
		VoxelDataset<miColor>() {
	miaux_set_rgb(&max_color, 0);
}

void VoxelDatasetColor::compute_sigma_a_threaded() {
	// Precompute all the constant soot coefficients
	compute_soot_coefficients();

	compute_function_threaded(&VoxelDatasetColor::compute_sigma_a);
}

void VoxelDatasetColor::compute_bb_radiation_threaded(
		float visual_adaptation_factor) {
	// Spectrum static initialisation, ideally should only be called once
	// move it from here to a proper initialisation context
	Spectrum::Init();

	compute_wavelengths();

	compute_function_threaded(&VoxelDatasetColor::compute_bb_radiation);

	normalize_bb_radiation(visual_adaptation_factor);
}

const miColor& VoxelDatasetColor::get_max_voxel_value() {
	return max_color;
}

miColor VoxelDatasetColor::bilinear_interp(float tx, float ty,
		const miColor& c00, const miColor&c01, const miColor& c10,
		const miColor& c11) const {
	miColor c0 = linear_interp(tx, c00, c10);
	miColor c1 = linear_interp(tx, c01, c11);
	return linear_interp(ty, c0, c1);
}
miColor VoxelDatasetColor::linear_interp(float t, const miColor& c0,
		const miColor& c1) const {
	miColor res;
	miaux_copy_color(&res, &c1);
	miaux_scale_color(&res, t);
	miaux_add_scaled_color(&res, &c0, 1 - t);
	return res;
}

void VoxelDatasetColor::compute_function_threaded(
		void (VoxelDatasetColor::*foo)(unsigned, unsigned, unsigned, unsigned,
				unsigned, unsigned)) {
	if (depth <= 0) {
		return;
	}

	// Get thread hint, i.e. number of cores
	unsigned num_threads = std::thread::hardware_concurrency();
	// At least we are able to run the current thread
	if (num_threads == 0) {
		num_threads = 1;
	}

	// Cap the number of threads if there is not enough work for each one
	if ((unsigned) (depth) < num_threads) {
		num_threads = depth;
	}

	mi_info("\tStart computation with %d threads", num_threads);
	unsigned thread_chunk = depth / num_threads;
	std::vector<std::thread> threads;
	unsigned i_depth = 0, e_depth = thread_chunk;

	// Launch each thread with its chunk of work
	for (unsigned i = 0; i < num_threads - 1; i++) {
		threads.push_back(
				std::thread(foo, this, 0, 0, i_depth, width, height, e_depth));
		i_depth = e_depth;
		e_depth = e_depth + thread_chunk;
	}

	// The remaining work will be handled by the current thread
	auto foo_member = std::mem_fn(foo);
	foo_member(this, 0, 0, i_depth, width, height, depth);

	// Wait for the other threads to finish
	for (auto& thread : threads) {
		thread.join();
	}
}

void VoxelDatasetColor::compute_soot_coefficients() {
	// Spectrum static initialisation, ideally should only be called once
	// move it from here to a proper initialisation context
	Spectrum::Init();

	// TODO If we wanted to sample more from the spectrum, we would have to
	// compute lambda^alpha_lambda in compute_sigma_a, in any case I don't think
	// it makes sense, as we do not have more n or k data
	sootCoefficients = std::vector<miScalar>(Soot::num_samples, 0);
	for (unsigned i = 0; i < sootCoefficients.size(); i++) {
		miScalar n2_k2_2 = Soot::n[i] * Soot::n[i] - Soot::k[i] * Soot::k[i]
				+ 2;
		n2_k2_2 = n2_k2_2 * n2_k2_2;
		sootCoefficients[i] = Soot::PI_R3_36 * Soot::nk[i]
				/ (std::pow(Soot::lambda[i], Soot::alpha_lambda)
						* (n2_k2_2 + 4 * Soot::nk[i] * Soot::nk[i]));
	}
}

void VoxelDatasetColor::compute_sigma_a(unsigned i_width, unsigned i_height,
		unsigned i_depth, unsigned e_width, unsigned e_height,
		unsigned e_depth) {
	miColor density;
	std::vector<float> sigma_a(Soot::num_samples);
	for (unsigned i = i_width; i < e_width; i++) {
		for (unsigned j = i_height; j < e_height; j++) {
			for (unsigned k = i_depth; k < e_depth; k++) {
				density = get_voxel_value(i, j, k);
				if (density.r > 0.0) {
					for (unsigned l = 0; l < sigma_a.size(); l++) {
						sigma_a.at(l) = density.r * sootCoefficients[l];
					}
					// Create a Spectrum representation with the computed values
					// Spectrum expects the wavelengths to be in nanometres
					Spectrum sigma_a_spec = Spectrum::FromSampled(
							Soot::lambda_nano, &sigma_a[0], Soot::num_samples);

					// Transform the spectrum to RGB coefficients, since CIE is
					// not fully represented by RGB clamp negative intensities
					// to zero
					sigma_a_spec.ToRGB(&density.r);
					miaux_clamp_color(&density, 0, 1);
				} else {
					// Safe check for negative densities
					miaux_set_rgb(&density, 0);
				}
				set_voxel_value(i, j, k, density);
			}
		}
	}
}

void VoxelDatasetColor::compute_bb_radiation(unsigned i_width,
		unsigned i_height, unsigned i_depth, unsigned e_width,
		unsigned e_height, unsigned e_depth) {
	miColor t;
	float xyz_norm;
	float b[nSpectralSamples];
	for (unsigned i = i_width; i < e_width; i++) {
		for (unsigned j = i_height; j < e_height; j++) {
			for (unsigned k = i_depth; k < e_depth; k++) {
				t = get_voxel_value(i, j, k);
				// Anything below 0 degrees Celsius or 400 Kelvin will not glow
				// TODO Add as a parameter
				if (t.r > 400) {
					// TODO Pass a real refraction index, not 1
					// Get the blackbody values
					Blackbody(&lambdas[0], nSpectralSamples, t.r, 1, b);

					// Create a Spectrum representation with the computed values
					// Spectrum expects the wavelengths to be in nanometres
					Spectrum b_spec = Spectrum::FromSampled(&lambdas[0], b,
							nSpectralSamples);

					// Transform the spectrum to XYZ coefficients
					b_spec.ToXYZ(&t.r);

					// Normalise the XYZ coefficients
					xyz_norm = 1.0 / std::max(std::max(t.r, t.g), t.b);
					miaux_scale_color(&t, xyz_norm);

				} else {
					// If the temperature is low, just set the colour to 0
					miaux_set_rgb(&t, 0);
				}
				set_voxel_value(i, j, k, t);
			}
		}
	}
}

// TODO This could be threaded too, make all threads wait for each other and
// then use this code with start end indices
void VoxelDatasetColor::normalize_bb_radiation(float visual_adaptation_factor) {
	auto max_ind = get_maximum_voxel_index();
	const miColor& max_xyz = block[max_ind];
	miColor inv_max_lms;
	XYZtoLMS(&max_xyz.r, &inv_max_lms.r);

	if (inv_max_lms.r != 0) {
		inv_max_lms.r = 1.0 / inv_max_lms.r;
	}
	if (inv_max_lms.g != 0) {
		inv_max_lms.g = 1.0 / inv_max_lms.g;
	}
	if (inv_max_lms.b != 0) {
		inv_max_lms.b = 1.0 / inv_max_lms.b;
	}

	// Nguyen normalization in Matlab would be
	/*
	 *  m = [0.4002, 0.7076, -0.0808; -0.2263, 1.1653, 0.0457; 0, 0, 0.9182];
	 * invm = inv(m);
	 * lmslw = m * maxxyz;
	 * lmslw = 1 ./ lmslw;
	 * mLW = diag(lmslw);
	 * newxyz = invm * mLw * m * oldxyz; % For all the points
	 */

	// TODO This normalisation is assuming the fire is the main light in the
	// scene, it should pick the brightest object and normalise with that
	for (unsigned i = 0; i < count; i++) {
		if (!miaux_color_is_black(&block[i])) {
			miColor aux, color_lms;

			XYZtoLMS(&block[i].r, &color_lms.r);

			// Apply adaptation, is a diagonal matrix so we can just multiply
			// the values
			miaux_multiply_colors(&aux, &color_lms, &inv_max_lms);

			LMStoXYZ(&aux.r, &color_lms.r);

			// Give the user a control parameter between the old and the new
			// colours
			color_lms = linear_interp(visual_adaptation_factor, block[i],
					color_lms);

			XYZToRGB(&color_lms.r, &block[i].r);

			miaux_clamp_color(&block[i], 0, 1);
		}
	}

	max_color = block[max_ind];
}

unsigned VoxelDatasetColor::get_maximum_voxel_index() {
	auto max_ind = 0;
	float current_val, max_val = 0;
	for (unsigned i = 0; i < count; i++) {
		current_val = block[i].r + block[i].g + block[i].b;
		if (current_val > max_val) {
			max_val = current_val;
			max_ind = i;
		}
	}
	return max_ind;
}

void VoxelDatasetColor::compute_wavelengths() {
	unsigned l;
	float lambda;
	lambdas.resize(nSpectralSamples);
	// Convert lambad start/end from nanometres to metres
	float lambda_inc = (sampledLambdaEnd - sampledLambdaStart)
			/ (float) (nSpectralSamples);
	// Put all the wavelengths in a vector
	for (l = 0, lambda = sampledLambdaStart; l < lambdas.size(); l++, lambda +=
			lambda_inc) {
		lambdas.at(l) = lambda;
	}
}
