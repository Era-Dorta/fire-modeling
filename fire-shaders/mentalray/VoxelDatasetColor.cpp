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

void VoxelDatasetColor::compute_sigma_a_threaded() {
	// Precompute all the constant soot coefficients
	compute_soot_coefficients();

	compute_function_threaded(&VoxelDatasetColor::compute_sigma_a);
}

void VoxelDatasetColor::compute_bb_radiation_threaded() {
	// Spectrum static initialisation, ideally should only be called once
	// move it from here to a proper initialisation context
	Spectrum::Init();

	compute_wavelengths();

	compute_function_threaded(&VoxelDatasetColor::compute_bb_radiation);

	normalize_bb_radiation();
}

miColor VoxelDatasetColor::get_max_voxel_value() {
	return max_color;
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

	mi_warning("\tStart computation with %d threads", num_threads);
	unsigned thread_chunk = depth / num_threads;
	std::vector<std::thread> threads;
	unsigned i_depth = 0, e_depth = thread_chunk;

	// Launch each thread with its chunk of work
	for (unsigned i = 0; i < num_threads - 1; i++) {
		threads.push_back(
				std::thread(foo, this, 0, 0, i_depth, width, height, e_depth));
		i_depth = e_depth + 1;
		e_depth = e_depth + thread_chunk;
	}

	// The remaining work will be handled by the current thread
	auto foo_member = std::mem_fn(foo);
	foo_member(this, 0, 0, i_depth, width, height, depth - 1);

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
	for (unsigned i = i_width; i <= e_width; i++) {
		for (unsigned j = i_height; j <= e_height; j++) {
			for (unsigned k = i_depth; k <= e_depth; k++) {
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

					set_voxel_value(i, j, k, density);
				}
			}
		}
	}
}

void VoxelDatasetColor::compute_bb_radiation(unsigned i_width,
		unsigned i_height, unsigned i_depth, unsigned e_width,
		unsigned e_height, unsigned e_depth) {
	miColor t;
	float rgbCoefficients[3];
	float b[nSpectralSamples];
	for (unsigned i = i_width; i <= e_width; i++) {
		for (unsigned j = i_height; j <= e_height; j++) {
			for (unsigned k = i_depth; k <= e_depth; k++) {
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

					// Transform the spectrum to RGB coefficients
					b_spec.ToRGB(rgbCoefficients);

					t.r = (rgbCoefficients[0] > 0) ? rgbCoefficients[0] : 0;
					t.g = (rgbCoefficients[1] > 0) ? rgbCoefficients[1] : 0;
					t.b = (rgbCoefficients[2] > 0) ? rgbCoefficients[2] : 0;

					set_voxel_value(i, j, k, t);
				}
			}
		}
	}
}

void VoxelDatasetColor::normalize_bb_radiation() {
	auto max_ind = get_maximum_voxel_index();
	miColor inv_norm_factor = block[max_ind];

	if (inv_norm_factor.r > 0) {
		inv_norm_factor.r = 1.0 / inv_norm_factor.r;
	}
	if (inv_norm_factor.g > 0) {
		inv_norm_factor.g = 1.0 / inv_norm_factor.g;
	}
	if (inv_norm_factor.b > 0) {
		inv_norm_factor.b = 1.0 / inv_norm_factor.b;
	}

	// TODO This normalisation is assuming the fire is the main light in the
	// scene, it should pick the brightest object and normalise with that
	unsigned count = width * height * depth;
	for (unsigned i = 0; i < count; i++) {
		block[i].r *= inv_norm_factor.r;
		block[i].g *= inv_norm_factor.g;
		block[i].b *= inv_norm_factor.b;
	}

	max_color = block[max_ind];
}

unsigned VoxelDatasetColor::get_maximum_voxel_index() {
	unsigned count = width * height * depth;
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
