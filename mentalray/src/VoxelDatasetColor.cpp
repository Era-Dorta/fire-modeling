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
	bb_type = BB_ONLY;
	tone_mapped = true;
}

VoxelDatasetColor::VoxelDatasetColor(const miColor& background) :
		VoxelDataset<openvdb::Vec3f, openvdb::Vec3fTree>(
				openvdb::Vec3f(background.r, background.g, background.b)) {
	miaux_set_rgb(&max_color, 0);
	soot_radius = 0;
	alpha_lambda = 0;
	bb_type = BB_ONLY;
	tone_mapped = true;
}

bool VoxelDatasetColor::compute_black_body_emission_threaded(
		float visual_adaptation_factor, BB_TYPE bb_type,
		const std::string& filename) {
	this->bb_type = bb_type;

	switch (bb_type) {
	case BB_ONLY: {
		break;
	}
	case BB_SOOT: {
		if (!read_optical_constants_file(filename)) {
			return false;
		}
		compute_soot_constant_coefficients();

		// Densities coefficients need to be scale up heavily here so that the
		// user does not need to use insane density scale parameters
		scale_coefficients_to_custom_range();
		break;
	}
	case BB_CHEM: {
		if (!read_spectral_line_file(filename)) {
			return false;
		}
		break;
	}
	}

	compute_function_threaded(&VoxelDatasetColor::compute_black_body_emission);

	normalize_bb_radiation(visual_adaptation_factor);

	clear_coefficients();

	return true;
}

bool VoxelDatasetColor::compute_soot_absorption_threaded(
		const std::string& filename) {
	if (!read_optical_constants_file(filename)) {
		return false;
	}

	compute_soot_constant_coefficients();

	scale_coefficients_to_custom_range();

	compute_function_threaded(&VoxelDatasetColor::compute_soot_absorption);

	clear_coefficients();

	return true;
}

bool VoxelDatasetColor::compute_chemical_absorption_threaded(
		float visual_adaptation_factor, const std::string& filename) {
	if (!read_spectral_line_file(filename)) {
		return false;
	}

	/*
	 * As we are normalising with bb_radiation, there is no need to call
	 * scale_coefficients_to_custom_range();
	 * Actually it completely breaks the final image if we added it
	 */

	compute_function_threaded(&VoxelDatasetColor::compute_chemical_absorption);

	normalize_bb_radiation(visual_adaptation_factor);

	clear_coefficients();

	return true;
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
	soot_coef.resize(n.size());
	std::vector<float> k(n.size());

	for (unsigned i = 0; i < n.size(); i++) {
		k[i] = nk[i] / n[i];
	}

	float pi_r3_36 = (4.0f / 3.0f) * M_PI * soot_radius * soot_radius
			* soot_radius * 36.0f * M_PI;

	for (unsigned i = 0; i < n.size(); i++) {
		miScalar n2_k2_2 = n[i] * n[i] - k[i] * k[i] + 2;
		n2_k2_2 = n2_k2_2 * n2_k2_2;
		soot_coef[i] = pi_r3_36 * nk[i]
				/ (std::pow(lambdas[i] * 1e-9, alpha_lambda)
						* (n2_k2_2 + 4 * nk[i] * nk[i]));
	}
}

void VoxelDatasetColor::compute_soot_absorption(unsigned start_offset,
		unsigned end_offset) {
	openvdb::Vec3f density;
	std::vector<float> spec_values(soot_coef.size());
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		density = iter.getValue();
		if (density.x() > 0.0) {
			for (unsigned j = 0; j < spec_values.size(); j++) {
				spec_values.at(j) = density.x() * soot_coef[j];
			}
			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum sigma_a_spec = Spectrum::FromSampled(&lambdas[0],
					&spec_values[0], lambdas.size());

			// Transform the spectrum to RGB coefficients, since CIE is
			// not fully represented by RGB clamp negative intensities
			// to zero
			sigma_a_spec.ToRGB(&density.x());

			clamp(density, 0, 1);
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
	std::vector<float> spec_values(lambdas.size());
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	float maxT = 0, currentT = 0;

	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		t = iter.getValue();
		// As it has the same exponential as black body, with low temperatures
		// there is no absorption
		if (t.x() > 400) {
			currentT = t.x();

			// TODO Pass a real refraction index, not 1
			// Compute the chemical absorption spectrum values, as we are
			// normalizing afterwards, the units used here don't matter
			ChemicalAbsorption(&lambdas[0], &phi[0], &A21[0], &E1[0], &E2[0],
					&g1[0], &g2[0], lambdas.size(), t.x(), 1, t.y(),
					&spec_values[0]);

			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum chem_spec = Spectrum::FromSampled(&lambdas[0],
					&spec_values[0], lambdas.size());

			// Divide each coefficient by the max, to get a normalized spectrum
			chem_spec.NormalizeByMax();

			// Convert to XYZ, the visual adaption function will convert to RGB
			chem_spec.ToXYZ(&t.x());

			if (currentT > maxT) {
				maxT = currentT;
				max_ind = iter.getCoord();

				max_color.r = t.x();
				max_color.g = t.y();
				max_color.b = t.z();
			}
		} else {
			// Negative and zero absorption
			t.setZero();
		}
		iter.setValue(t);
	}
}

void VoxelDatasetColor::compute_black_body_emission(unsigned start_offset,
		unsigned end_offset) {
	std::vector<float> spec_values(nSpectralSamples), other_spec_values(
			lambdas.size());
	std::vector<float> bb_lambdas(nSpectralSamples);

	// Initialise the lambdas for blackbody computation as big as nSpectralSamples
	for (int i = 0; i < nSpectralSamples; ++i) {
		float wl0 = Lerp(float(i) / float(nSpectralSamples), sampledLambdaStart,
				sampledLambdaEnd);
		float wl1 = Lerp(float(i + 1) / float(nSpectralSamples),
				sampledLambdaStart, sampledLambdaEnd);
		bb_lambdas[i] = (wl0 + wl1) * 0.5;
	}

	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}

	float maxT = 0, currentT = 0;

	for (auto i = start_offset; i < end_offset && iter; ++iter) {
		openvdb::Vec3f t = iter.getValue();

		// Anything below 0 degrees Celsius or 400 Kelvin will not glow
		if (t.x() > 400) {
			currentT = t.x();

			// TODO Pass a real refraction index, not 1
			// Get the blackbody values
			Blackbody(&bb_lambdas[0], bb_lambdas.size(), t.x(), 1,
					&spec_values[0]);

			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum b_spec = Spectrum::FromSampled(&bb_lambdas[0],
					&spec_values[0], bb_lambdas.size());

			/*
			 * With SOOT and CHEM, compute the absorption coefficient in
			 * spectral form, multiply here the absorption by the emission,
			 * delaying the transformation to RGB improves the final result
			 */
			switch (bb_type) {
			case BB_ONLY: {
				break;
			}
			case BB_SOOT: {
				// Soot absorption spectrum is precomputed values * density
				for (unsigned j = 0; j < other_spec_values.size(); j++) {
					other_spec_values.at(j) = t.y() * soot_coef[j];
				}

				// Create a Spectrum representation with the absorption values
				// Spectrum expects the wavelengths to be in nanometres
				Spectrum sigma_a_spec = Spectrum::FromSampled(&lambdas[0],
						&other_spec_values[0], lambdas.size());

				b_spec = b_spec * sigma_a_spec;

				break;
			}
			case BB_CHEM: {
				// Compute the chemical absorption spectrum values, as we are
				// normalizing afterwards, the units used here don't matter
				ChemicalAbsorption(&lambdas[0], &phi[0], &A21[0], &E1[0],
						&E2[0], &g1[0], &g2[0], lambdas.size(), t.x(), 1, t.y(),
						&other_spec_values[0]);

				// Create a Spectrum representation with the computed values
				// Spectrum expects the wavelengths to be in nanometres
				Spectrum chem_spec = Spectrum::FromSampled(&lambdas[0],
						&other_spec_values[0], lambdas.size());

				b_spec = b_spec * chem_spec;

				break;
			}
			}

			// Transform the spectrum to XYZ coefficients
			b_spec.ToXYZ(&t.x());

			if (currentT > maxT) {
				maxT = currentT;
				max_ind = iter.getCoord();

				max_color.r = t.x();
				max_color.g = t.y();
				max_color.b = t.z();
			}
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

	// This section is heavily inspired by the Reinhard Tone Mapping code
	// in https://github.com/banterle/HDR_Toolbox
	const float inv_gamma = 1.0 / 2.2;
	const float lMax = max_color.g, lMin = 0;
	const float log2Max = log2(lMax + 1e-9);
	const float log2Min = log2(lMin + 1e-9);

	// Estimate the white point luminance as in Reinhard
	// float pWhite2 = 1.5 * pow(2, log2Max - log2Min - 5);

	// Set the white point as the luminance of the voxel with highest
	// temperature, Nguyen 2002
	float pWhite2 = max_color.g;

	pWhite2 = pWhite2 * pWhite2;

	// Computer the e^(mean(luminance))
	float exp_mean_log = 0;
	for (auto iter = block->cbeginValueOn(); iter; ++iter) {
		exp_mean_log += log(iter->y() + 1e-6);
	}
	exp_mean_log = exp(exp_mean_log / block->activeVoxelCount());

	// Estimate the image exposure
	const float pAlpha = 0.18
			* pow(4,
					((2.0 * log2(exp_mean_log + 1e-9) - log2Min - log2Max)
							/ (log2Max - log2Min))) * visual_adaptation_factor;

	// TODO Use mi_colorprofile_... functions
	// If true output will be in RGB otherwise it will be in the XYZ colorspace
	const bool isRGB = mi_colorprofile_internalspace_id()
			!= mi_colorprofile_ciexyz_color_id();

	// Compute visual adaptation with the previous value
	for (auto iter = block->beginValueOn(); iter; ++iter) {
		if (!(iter->x() == 0 && iter->y() == 0 && iter->z() == 0)) {
			openvdb::Vec3f color_rgb_adapted, color_rgb;

			openvdb::Vec3f color_xyz = iter.getValue();

			if (isRGB) {
				XYZToRGB(&color_xyz.x(), &color_rgb.x());
			} else {
				color_rgb = color_xyz;
			}

			// Remove negative RGB values
			clamp(color_rgb, 0, FLT_MAX);

			if (tone_mapped) {

				// Compute new luminance as in Reinhard et. al. 2002
				// "Photographic tone reproduction for digital images"
				float new_l = (pAlpha * color_xyz.y()) / exp_mean_log;
				new_l = (new_l * (1 + new_l / pWhite2)) / (1 + new_l);

				// Apply luminance change to the original RGB color
				color_rgb_adapted = (color_rgb * new_l) / color_xyz.y();

				remove_specials(color_rgb_adapted);

				if (isRGB) {
					RGBToXYZ(&color_rgb_adapted.x(), &color_xyz.x());
				} else {
					color_xyz = color_rgb_adapted;
				}

				// Apply Schlick color correction, with 0.5 coefficient -> sqrt
				color_rgb_adapted.x() = sqrt(
						color_rgb_adapted.x() / color_xyz.y()) * color_xyz.y();
				color_rgb_adapted.y() = sqrt(
						color_rgb_adapted.y() / color_xyz.y()) * color_xyz.y();
				color_rgb_adapted.z() = sqrt(
						color_rgb_adapted.z() / color_xyz.y()) * color_xyz.y();

				remove_specials(color_rgb_adapted);

				// Apply Gamma correction, with Gamma 2.2
				color_rgb_adapted.x() = pow(color_rgb_adapted.x(), inv_gamma);
				color_rgb_adapted.y() = pow(color_rgb_adapted.y(), inv_gamma);
				color_rgb_adapted.z() = pow(color_rgb_adapted.z(), inv_gamma);

				// Final clamping for [0..1] RGB space
				clamp(color_rgb_adapted, 0, 1);
			} else {
				// Without tone mapping simply copy the color and remove any nan
				// and inf values
				color_rgb_adapted = color_rgb;
				remove_specials(color_rgb_adapted);
			}

			iter.setValue(color_rgb_adapted);
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

void VoxelDatasetColor::clamp(openvdb::Vec3f& v, float min, float max) {
	clamp(v.x(), min, max);
	clamp(v.y(), min, max);
	clamp(v.z(), min, max);
}

void VoxelDatasetColor::clamp(float &v, float min, float max) {
	if (v < min) {
		v = min;
		return;
	}
	if (v > max) {
		v = max;
		return;
	}
}

void VoxelDatasetColor::remove_specials(openvdb::Vec3f& v) {
	remove_specials(v.x());
	remove_specials(v.y());
	remove_specials(v.z());
}

void VoxelDatasetColor::remove_specials(float &v) {
	if (isnan(v) || isnan(-v) || isinf(v) || isinf(-v)) {
		v = 0;
	}
}

bool VoxelDatasetColor::read_spectral_line_file(const std::string& filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_error("Could not open spectral line file \"%s\".", filename.c_str());
		return false;
	}
	unsigned num_lines = 0;
	try {
		safe_ascii_read(fp, num_lines);

		lambdas.resize(num_lines);
		phi.resize(num_lines);
		A21.resize(num_lines);
		E1.resize(num_lines);
		E2.resize(num_lines);
		g1.resize(num_lines);
		g2.resize(num_lines);

		for (unsigned i = 0; i < num_lines; i++) {
			safe_ascii_read(fp, lambdas[i]);
			safe_ascii_read(fp, phi[i]);
			safe_ascii_read(fp, A21[i]);
			safe_ascii_read(fp, E1[i]);
			safe_ascii_read(fp, E2[i]);
			safe_ascii_read(fp, g1[i]);
			safe_ascii_read(fp, g2[i]);
		}
		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
}

bool VoxelDatasetColor::read_optical_constants_file(
		const std::string& filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_error("Could not open optical constant file \"%s\".",
				filename.c_str());
		return false;
	}
	unsigned num_lines = 0;
	try {
		safe_ascii_read(fp, num_lines);

		safe_ascii_read(fp, soot_radius);
		safe_ascii_read(fp, alpha_lambda);

		lambdas.resize(num_lines);
		n.resize(num_lines);
		nk.resize(num_lines);

		for (unsigned i = 0; i < num_lines; i++) {
			safe_ascii_read(fp, lambdas[i]);
			safe_ascii_read(fp, n[i]);
			safe_ascii_read(fp, nk[i]);
		}
		fp.close();
		return true;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		mi_error("Wrong format in file \"%s\".", filename.c_str());
		return false;
	}
}

template<typename T>
void VoxelDatasetColor::safe_ascii_read(std::ifstream& fp, T &output) {
	fp >> output;
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}

void VoxelDatasetColor::scale_coefficients_to_custom_range() {
	/* Our input data is in the range of [0..1], when the physical densities are
	 * several orders of magnitude higher, as they represent the number of
	 * molecules per unit volume
	 */
	for (auto iter = soot_coef.begin(); iter != soot_coef.end(); ++iter) {
		*iter *= 1e12;
	}
}

void VoxelDatasetColor::clear_coefficients() {
	lambdas.clear();
	phi.clear();
	A21.clear();
	E1.clear();
	E2.clear();
	g1.clear();
	g2.clear();
}

bool VoxelDatasetColor::isToneMapped() const {
	return tone_mapped;
}

void VoxelDatasetColor::setToneMapped(bool tone_mapped) {
	this->tone_mapped = tone_mapped;
}
