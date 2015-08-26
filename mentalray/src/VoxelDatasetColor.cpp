/*
 * VoxelDatasetColor.cpp
 *
 *  Created on: 26 Jun 2015
 *      Author: gdp24
 */

#include "VoxelDatasetColor.h"

#include <thread>

#include "Spectrum.h"
#include "miaux.h"

VoxelDatasetColor::VoxelDatasetColor() :
		VoxelDataset<openvdb::Vec3f, openvdb::Vec3fTree>(
				openvdb::Vec3f(0, 0, 0)) {
	miaux_set_rgb(&max_color, 0);
	soot_radius = 0;
	alpha_lambda = 0;
}

VoxelDatasetColor::VoxelDatasetColor(const miColor& background) :
		VoxelDataset<openvdb::Vec3f, openvdb::Vec3fTree>(
				openvdb::Vec3f(background.r, background.g, background.b)) {
	miaux_set_rgb(&max_color, 0);
	soot_radius = 0;
	alpha_lambda = 0;
}

void VoxelDatasetColor::compute_black_body_emission_threaded(
		float visual_adaptation_factor) {

	fill_lambda_vector();

	compute_function_threaded(&VoxelDatasetColor::compute_black_body_emission);

	normalize_bb_radiation(visual_adaptation_factor);

	lambdas.clear();
}

void VoxelDatasetColor::compute_soot_absorption_threaded(const char* filename) {
	read_optical_constants_file(filename);

	compute_soot_constant_coefficients();

	compute_function_threaded(&VoxelDatasetColor::compute_soot_absorption);

	input_data.clear();
	extra_data.clear();
	lambdas.clear();
}

void VoxelDatasetColor::compute_chemical_absorption_threaded(
		float visual_adaptation_factor, const char* filename) {
	read_spectral_line_file(filename);

	compute_function_threaded(&VoxelDatasetColor::compute_chemical_absorption);

	normalize_bb_radiation(visual_adaptation_factor);

	input_data.clear();
	lambdas.clear();
}

const miColor& VoxelDatasetColor::get_max_voxel_value() {
	return max_color;
}

void VoxelDatasetColor::compute_max_voxel_value() {
	auto voxel_val = accessor.getValue(get_maximum_voxel_index());

	max_color.r = voxel_val.x();
	max_color.g = voxel_val.y();
	max_color.b = voxel_val.z();
}

openvdb::Vec3f VoxelDatasetColor::bilinear_interp(float tx, float ty,
		const openvdb::Vec3f& c00, const openvdb::Vec3f&c01,
		const openvdb::Vec3f& c10, const openvdb::Vec3f& c11) const {
	openvdb::Vec3f c0 = linear_interp(tx, c00, c10);
	openvdb::Vec3f c1 = linear_interp(tx, c01, c11);
	return linear_interp(ty, c0, c1);
}
openvdb::Vec3f VoxelDatasetColor::linear_interp(float t,
		const openvdb::Vec3f& c0, const openvdb::Vec3f& c1) const {
	return c0 * (1.0f - t) + c1 * t;
}

void VoxelDatasetColor::compute_function_threaded(
		void (VoxelDatasetColor::*foo)(unsigned, unsigned)) {
	unsigned num_values = block->activeVoxelCount();
	if (num_values <= 0) {
		return;
	}

	// Get thread hint, i.e. number of cores
	unsigned num_threads = std::thread::hardware_concurrency();
	// At least we are able to run the current thread
	if (num_threads == 0) {
		num_threads = 1;
	}

	// Cap the number of threads if there is not enough work for each one
	if ((unsigned) (num_values) < num_threads) {
		num_threads = num_values;
	}
	// TODO Should make copies of the grid, work on them and then merge them
	num_threads = 1;

	mi_info("\tStart computation with %d threads", num_threads);
	unsigned thread_chunk = num_values / num_threads;
	std::vector<std::thread> threads;
	unsigned start_offset = 0, end_offset = thread_chunk;

	// Launch each thread with its chunk of work
	for (unsigned i = 0; i < num_threads - 1; i++) {
		threads.push_back(std::thread(foo, this, start_offset, end_offset));
		start_offset = end_offset;
		end_offset += thread_chunk;
	}

	// The remaining work will be handled by the current thread
	auto foo_member = std::mem_fn(foo);
	foo_member(this, start_offset, num_values);

	// Wait for the other threads to finish
	for (auto& thread : threads) {
		thread.join();
	}
}

void VoxelDatasetColor::compute_soot_constant_coefficients() {
	// TODO If we wanted to sample more from the spectrum, we would have to
	// compute lambda^alpha_lambda in compute_sigma_a, in any case I don't think
	// it makes sense, as we do not have more n or k data
	std::vector<float> &n = input_data;
	std::vector<float> &nk = extra_data;
	std::vector<float> k(n.size());

	for (unsigned i = 0; i < n.size(); i++) {
		k[i] = nk[i] / n[i];
	}

	float pi_r3_36 = (4.0f / 3.0f) * M_PI * soot_radius * soot_radius
			* soot_radius * 36.0f * M_PI;

	for (unsigned i = 0; i < n.size(); i++) {
		miScalar n2_k2_2 = n[i] * n[i] - k[i] * k[i] + 2;
		n2_k2_2 = n2_k2_2 * n2_k2_2;
		input_data[i] = pi_r3_36 * nk[i]
				/ (std::pow(lambdas[i] * 1e-9, alpha_lambda)
						* (n2_k2_2 + 4 * nk[i] * nk[i]));
	}
}

void VoxelDatasetColor::compute_soot_absorption(unsigned start_offset,
		unsigned end_offset) {
	openvdb::Vec3f density;
	std::vector<float> spec_values(input_data.size());
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		density = iter.getValue();
		if (density.x() > 0.0) {
			for (unsigned j = 0; j < spec_values.size(); j++) {
				// TODO 1e12 is a magic number to get the right scale
				spec_values.at(j) = density.x() * 1e12 * input_data[j];
			}
			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum sigma_a_spec = Spectrum::FromSampled(&lambdas[0],
					&spec_values[0], lambdas.size());

			// Transform the spectrum to RGB coefficients, since CIE is
			// not fully represented by RGB clamp negative intensities
			// to zero
			sigma_a_spec.ToRGB(&density.x());

			clamp_0_1(density);
		} else {
			// Negative and zero densities
			density.setZero();
		}
		iter.setValue(density);
	}
}

void VoxelDatasetColor::compute_chemical_absorption(unsigned start_offset,
		unsigned end_offset) {
	openvdb::Vec3f t;
	float spec_values[nSpectralSamples];
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		t = iter.getValue();
		// As it has the same exponential as black body, with low temperatures
		// there is no absorption
		if (t.x() > 400) {
			// TODO Pass a real refraction index, not 1
			// Compute the chemical absorption spectrum values, as we are
			// normalizing afterwards, the units used here don't matter
			ChemicalAbsorption(&lambdas[0], &input_data[0], lambdas.size(),
					t.x(), 1, spec_values);

			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum chem_spec = Spectrum::FromSampled(&lambdas[0], spec_values,
					lambdas.size());

			// Divide each coefficient by the max, to get a normalized spectrum
			chem_spec.NormalizeByMax();

			// Transform the spectrum to RGB coefficients, since CIE is
			// not fully represented by RGB clamp negative intensities
			// to zero
			chem_spec.ToRGB(&t.x());

			clamp_0_1(t);
		} else {
			// Negative and zero absorption
			t.setZero();
		}
		iter.setValue(t);
	}
}

void VoxelDatasetColor::compute_black_body_emission(unsigned start_offset,
		unsigned end_offset) {
	float spec_values[nSpectralSamples];
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		openvdb::Vec3f t = iter.getValue();

		// Anything below 0 degrees Celsius or 400 Kelvin will not glow
		if (t.x() > 400) {
			// TODO Pass a real refraction index, not 1
			// Get the blackbody values
			Blackbody(&lambdas[0], nSpectralSamples, t.x(), 1, spec_values);

			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum b_spec = Spectrum::FromSampled(&lambdas[0], spec_values,
					nSpectralSamples);

			// Transform the spectrum to XYZ coefficients
			b_spec.ToXYZ(&t.x());

			// TODO Not sure which method to use, if I should scale or if it is
			// better to scale the rgb at the end instead of the xyz here

			// Normalise the XYZ coefficients
			// 1) Norm, actually better to use t.normalize()
			// float xyz_scale = 1.0 / t.length();
			// 2) Inverse of maximum value
			float xyz_scale = 1.0 / std::max(std::max(t.x(), t.y()), t.z());
			// 3) Inverse of sum of components
			// float xyz_scale = 1.0 / (t.x() + t.y() + t.z());

			t.scale(xyz_scale, t);
		} else {
			// If the temperature is low, just set the colour to 0
			t.setZero();
		}
		iter.setValue(t);
	}
}

// TODO This could be threaded too, make all threads wait for each other and
// then use this code with start end indices
void VoxelDatasetColor::normalize_bb_radiation(float visual_adaptation_factor) {
	openvdb::Coord max_ind = get_maximum_voxel_index();
	const openvdb::Vec3f& max_xyz = accessor.getValue(max_ind);
	float max_xyz_float[3];

	max_xyz_float[0] = max_xyz.x();
	max_xyz_float[1] = max_xyz.y();
	max_xyz_float[2] = max_xyz.z();

	openvdb::Vec3f inv_max_lms;
	XYZtoLMS(max_xyz_float, &inv_max_lms[0]);

	if (inv_max_lms.x() != 0) {
		inv_max_lms.x() = 1.0 / inv_max_lms.x();
	}
	if (inv_max_lms.y() != 0) {
		inv_max_lms.y() = 1.0 / inv_max_lms.y();
	}
	if (inv_max_lms.z() != 0) {
		inv_max_lms.z() = 1.0 / inv_max_lms.z();
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
	// Print all active ("on") voxels by means of an iterator.
	for (openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn(); iter;
			++iter) {
		if (!(iter->x() == 0 && iter->y() == 0 && iter->z() == 0)) {
			openvdb::Vec3f aux, color_lms;

			openvdb::Vec3f current_color = iter.getValue();

			XYZtoLMS(&current_color.x(), &color_lms.x());

			// Apply adaptation, is a diagonal matrix so we can just multiply
			// the values
			aux = color_lms * inv_max_lms;

			LMStoXYZ(&aux.x(), &color_lms.x());

			// Give the user a control parameter between the old and the new
			// colours
			color_lms = linear_interp(visual_adaptation_factor, current_color,
					color_lms);

			XYZToRGB(&color_lms.x(), &current_color.x());

			clamp_0_1(current_color);

			iter.setValue(current_color);
		}
	}

	max_color.r = accessor.getValue(max_ind).x();
	max_color.g = accessor.getValue(max_ind).y();
	max_color.b = accessor.getValue(max_ind).z();
}

openvdb::Coord VoxelDatasetColor::get_maximum_voxel_index() {
	openvdb::Coord max_ind;
	float current_val, max_val = 0;
	for (openvdb::Vec3SGrid::ValueOnCIter iter = block->cbeginValueOn(); iter;
			++iter) {
		current_val = iter->x() + iter->y() + iter->z();
		if (current_val > max_val) {
			max_val = current_val;
			max_ind = iter.getCoord();
		}
	}
	return max_ind;
}

void VoxelDatasetColor::fill_lambda_vector() {
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

void VoxelDatasetColor::clamp_0_1(openvdb::Vec3f& v) {
	clamp_0_1(v.x());
	clamp_0_1(v.y());
	clamp_0_1(v.z());
}

void VoxelDatasetColor::clamp_0_1(float &v) {
	if (v < 0) {
		v = 0;
		return;
	}
	if (v > 1) {
		v = 1;
	}
}

void VoxelDatasetColor::read_spectral_line_file(const char* filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening spectral line file \"%s\".", filename);
	}
	unsigned num_lines = 0;
	safe_ascii_read(fp, num_lines);

	lambdas.resize(num_lines);
	input_data.resize(num_lines);

	for (unsigned i = 0; i < num_lines; i++) {
		safe_ascii_read(fp, lambdas[i]);
		safe_ascii_read(fp, input_data[i]);
	}
	fp.close();
}

void VoxelDatasetColor::read_optical_constants_file(const char* filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_fatal("Error opening optical constant file \"%s\".", filename);
	}
	unsigned num_lines = 0;
	safe_ascii_read(fp, num_lines);

	safe_ascii_read(fp, soot_radius);
	safe_ascii_read(fp, alpha_lambda);

	lambdas.resize(num_lines);
	input_data.resize(num_lines);
	extra_data.resize(num_lines);

	for (unsigned i = 0; i < num_lines; i++) {
		safe_ascii_read(fp, lambdas[i]);
		safe_ascii_read(fp, input_data[i]);
		safe_ascii_read(fp, extra_data[i]);
	}
	fp.close();
}

template<typename T>
void VoxelDatasetColor::safe_ascii_read(std::ifstream& fp, T &output) {
	fp >> output;
	if (!fp) {
		fp.close();
		mi_fatal("Error reading file");
	}
}
