/*
 * VoxelDatasetColor.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetColor.h"

#include <thread>

#include "SootOpticalConstants.h"
#include "Spectrum.h"

void VoxelDatasetColor::compute_sigma_a_threaded() {
	// Precompute all the constant soot coefficients
	compute_soot_coefficients();

	// Get thread hint, i.e. number of cores
	unsigned num_threads = std::thread::hardware_concurrency();
	// Get are at least able to run one thread
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
				std::thread(&VoxelDatasetColor::compute_sigma_a, this, 0, 0,
						i_depth, width, height, e_depth));
		i_depth = e_depth + 1;
		e_depth = e_depth + thread_chunk;
	}
	// The remaining will be handled by the current thread
	compute_sigma_a(0, 0, i_depth, width, height, depth - 1);
	// Wait for the other threads to finish
	for (auto& thread : threads) {
		thread.join();
	}
}

void VoxelDatasetColor::compute_soot_coefficients() {
	// TODO If we wanted to sample more from the spectrum, we could not compute
	// lambda^alpha_lambda here and do it in compute_sigma_a
	sootCoefficients = std::vector<miScalar>(Soot::sampleSize, 0);
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
	std::vector<float> sigma_a(Soot::sampleSize);
	float rgbCoefficients[3];
	for (unsigned i = i_width; i <= e_width; i++) {
		for (unsigned j = i_height; j <= e_height; j++) {
			for (unsigned k = i_depth; k <= e_depth; k++) {
				density = get_voxel_value(i, j, k);
				if (density.r > 0.0) {
					for (unsigned l = 0; l < sigma_a.size(); l++) {
						sigma_a.at(l) = density.r * sootCoefficients[l];
					}
					// Create a Spectrum representation with the computed values
					Spectrum sigma_a_spec = Spectrum::FromSampled(Soot::lambda,
							&sigma_a[0], Soot::sampleSize);
					// Transform the spectrum to RGB coefficients
					sigma_a_spec.ToRGB(rgbCoefficients);
					density.r = rgbCoefficients[0];
					density.g = rgbCoefficients[1];
					density.b = rgbCoefficients[2];
					set_voxel_value(i, j, k, density);
				}
			}
		}
	}
}
