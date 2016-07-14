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
	bb_type = BB_ONLY;
	tone_mapping = HDR;
}

VoxelDatasetColor::VoxelDatasetColor(const miColor& background) :
		VoxelDataset<openvdb::Vec3f, openvdb::Vec3fTree>(
				openvdb::Vec3f(background.r, background.g, background.b)) {
	miaux_set_rgb(&max_color, 0);
	bb_type = BB_ONLY;
	tone_mapping = HDR;
}

bool VoxelDatasetColor::compute_black_body_emission_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {

	if (fuel_type == FuelType::BlackBody) {
		bb_type = VoxelDatasetColor::BB_ONLY;
	} else {
		if (fuel_type <= FuelType::SootMax) {
			bb_type = VoxelDatasetColor::BB_SOOT;
		} else {
			bb_type = VoxelDatasetColor::BB_CHEM;
		}
		if (!fill_absorption_spec(fuel_type)) {
			return false;
		}
	}

	compute_function_threaded(&VoxelDatasetColor::compute_black_body_emission);

	apply_visual_adaptation(visual_adaptation_factor);

	clear_coefficients();

	return true;
}

bool VoxelDatasetColor::compute_soot_absorption_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {
	if (!fill_absorption_spec(fuel_type)) {
		return false;
	}

	compute_function_threaded(&VoxelDatasetColor::compute_soot_absorption);

	apply_visual_adaptation(visual_adaptation_factor);

	clear_coefficients();

	return true;
}

bool VoxelDatasetColor::compute_chemical_absorption_threaded(
		float visual_adaptation_factor, FuelType fuel_type) {

	if (!fill_absorption_spec(fuel_type)) {
		return false;
	}

	/*
	 * As we are normalising with bb_radiation, there is no need to call
	 * scale_coefficients_to_custom_range();
	 * Actually it completely breaks the final image if we added it
	 */

	compute_function_threaded(&VoxelDatasetColor::compute_chemical_absorption);

	apply_visual_adaptation(visual_adaptation_factor);

	fix_chem_absorption();

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

void VoxelDatasetColor::compute_soot_absorption(unsigned start_offset,
		unsigned end_offset) {
	openvdb::Vec3f density;

	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	for (auto i = start_offset; i < end_offset && iter; i++, ++iter) {
		density = iter.getValue();
		if (density.x() > 0.0) {
			const Spectrum& sigma_a_spec = absorption_spec.at(0).compute(
					density.x());

			// Transform the spectrum to XYZ coefficients
			sigma_a_spec.ToXYZ(&density.x());
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
	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}
	float maxT = 0, currentT = 0;

	if (tone_mapping != HDR) {
		// Vector where the densities will be saved for later use
		densities.resize(block->activeVoxelCount());
	}

	for (auto i = start_offset; i < end_offset && iter; i++, ++iter) {
		t = iter.getValue();

		if (tone_mapping != HDR) {
			densities.at(i) = t.y();
		}

		// As it has the same exponential as black body, with low temperatures
		// there is no absorption
		if (t.x() > 400) {
			currentT = t.x();

			Spectrum chem_spec;
			for (auto& absorption_i : absorption_spec) {
				chem_spec += absorption_i.compute(t.y(), t.x());
			}

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

	lambdas.resize(nSpectralSamples);
	std::vector<float> spec_values(lambdas.size());

	// Initialise the lambdas for blackbody computation as big as nSpectralSamples
	for (int i = 0; i < nSpectralSamples; ++i) {
		float wl0 = Lerp(float(i) / float(nSpectralSamples), sampledLambdaStart,
				sampledLambdaEnd);
		float wl1 = Lerp(float(i + 1) / float(nSpectralSamples),
				sampledLambdaStart, sampledLambdaEnd);
		lambdas[i] = (wl0 + wl1) * 0.5;
	}

	openvdb::Vec3SGrid::ValueOnIter iter = block->beginValueOn();
	for (unsigned i = 0; i < start_offset; i++) {
		iter.next();
	}

	float maxT = 0, currentT = 0;

	for (auto i = start_offset; i < end_offset && iter; i++, ++iter) {
		openvdb::Vec3f t = iter.getValue();

		// Anything below 0 degrees Celsius or 400 Kelvin will not glow
		if (t.x() > 400) {
			currentT = t.x();

			// TODO Pass a real refraction index, not 1
			// Get the blackbody values
			Blackbody(&lambdas[0], lambdas.size(), t.x(), 1, &spec_values[0]);

			// Create a Spectrum representation with the computed values
			// Spectrum expects the wavelengths to be in nanometres
			Spectrum b_spec = Spectrum::FromSampled(&lambdas[0],
					&spec_values[0], lambdas.size());

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
				b_spec = b_spec * absorption_spec.at(0).compute(t.y());
				break;
			}
			case BB_CHEM: {
				Spectrum chem_spec;
				for (auto& absorption_i : absorption_spec) {
					chem_spec += absorption_i.compute(t.y(), t.x());
				}

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
void VoxelDatasetColor::apply_visual_adaptation(
		float visual_adaptation_factor) {

	// TODO Use mi_colorprofile_... functions
	// If true output will be in RGB otherwise it will be in the XYZ colorspace
	const bool isRGB = mi_colorprofile_renderspace_id()
			!= mi_colorprofile_ciexyz_color_id();

	switch (tone_mapping) {
	case HDR: {
		apply_tm_hdr(isRGB);
		break;
	}
	case VON_KRIES: {
		apply_tm_von_kries(isRGB);
		break;
	}
	case REINHARD: {
		apply_tm_reinhard(isRGB);
		break;
	}
	case GAMMA: {
		apply_tm_gamma(isRGB);
		break;
	}
	}

	max_color.r = accessor.getValue(max_ind).x();
	max_color.g = accessor.getValue(max_ind).y();
	max_color.b = accessor.getValue(max_ind).z();
}

void VoxelDatasetColor::fix_chem_absorption() {
	/*
	 * If the absorption coefficients were toned mapped, multiply the visually
	 * adapted absorption by the densities, otherwise the densities would have
	 * no effect during the ray marching
	 */
	if (tone_mapping != HDR) {
		auto density = densities.begin();
		for (auto iter = block->beginValueOn(); iter; ++iter) {

			iter.setValue(iter.getValue() * (*density));

			++density;
		}
	}
}

bool VoxelDatasetColor::fill_absorption_spec(FuelType fuel_type) {
	assert(fuel_type != FuelType::BlackBody);

	absorption_spec.clear();

	if (fuel_type == FuelType::C3H8) {
		// For C3H8 put both C and H in a vector
		absorption_spec.push_back(AbsorptionSpectrum(FuelType::C));
		if (absorption_spec.begin()->isInValidState()) {
			absorption_spec.push_back(AbsorptionSpectrum(FuelType::H));
			return absorption_spec.at(1).isInValidState();
		} else {
			return false;
		}
	} else {
		// For all other fuels it is just a single atom
		absorption_spec.push_back(AbsorptionSpectrum(fuel_type));
		return absorption_spec.begin()->isInValidState();
	}
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

void VoxelDatasetColor::clear_coefficients() {
	lambdas.clear();
	densities.clear();
	absorption_spec.clear();
}

VoxelDatasetColor::TM_TYPE VoxelDatasetColor::getToneMapping() const {
	return tone_mapping;
}

void VoxelDatasetColor::setToneMapping(TM_TYPE tone_mapping) {
	this->tone_mapping = tone_mapping;
}

void VoxelDatasetColor::apply_tm_reinhard(const bool isRGB) {
	// This section is heavily inspired by the Reinhard Tone Mapping code
	// in https://github.com/banterle/HDR_Toolbox
	const float inv_gamma = 1.0 / 2.2;
	const float lMax = max_color.g, lMin = 0;
	const float log2Max = log2(lMax + 1e-9);
	const float log2Min = log2(lMin + 1e-9);

	// Estimate the white point luminance as in Reinhard
	float pWhite2 = 1.5 * pow(2, log2Max - log2Min - 5);

	// Set the white point as the luminance of the voxel with highest
	// temperature, Nguyen 2002
	// float pWhite2 = max_color.g;

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
							/ (log2Max - log2Min)));

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
			color_rgb_adapted.x() = sqrt(color_rgb_adapted.x() / color_xyz.y())
					* color_xyz.y();
			color_rgb_adapted.y() = sqrt(color_rgb_adapted.y() / color_xyz.y())
					* color_xyz.y();
			color_rgb_adapted.z() = sqrt(color_rgb_adapted.z() / color_xyz.y())
					* color_xyz.y();

			remove_specials(color_rgb_adapted);

			// Apply Gamma correction, with Gamma 2.2
			color_rgb_adapted.x() = pow(color_rgb_adapted.x(), inv_gamma);
			color_rgb_adapted.y() = pow(color_rgb_adapted.y(), inv_gamma);
			color_rgb_adapted.z() = pow(color_rgb_adapted.z(), inv_gamma);

			// Final clamping for [0..1] RGB space
			clamp(color_rgb_adapted, 0, 1);

			iter.setValue(color_rgb_adapted);
		}
	}
}

void VoxelDatasetColor::apply_tm_von_kries(const bool isRGB) {
	float max_xyz_float[3];

	max_xyz_float[0] = max_color.r;
	max_xyz_float[1] = max_color.g;
	max_xyz_float[2] = max_color.b;

	openvdb::Vec3f inv_max_lms;
	XYZtoLMS(max_xyz_float, &inv_max_lms[0]);

	inv_max_lms.x() = 1.0 / (inv_max_lms.x() + FLT_EPSILON);
	inv_max_lms.y() = 1.0 / (inv_max_lms.y() + FLT_EPSILON);
	inv_max_lms.z() = 1.0 / (inv_max_lms.z() + FLT_EPSILON);

	// Compute visual adaptation with the previous value
	for (auto iter = block->beginValueOn(); iter; ++iter) {
		if (!(iter->x() == 0 && iter->y() == 0 && iter->z() == 0)) {
			openvdb::Vec3f color_adapted, color_lms;

			openvdb::Vec3f color_xyz = iter.getValue();

			XYZtoLMS(&color_xyz.x(), &color_lms.x());

			// Apply adaptation, is a diagonal matrix so we can just multiply
			// the values
			color_lms = color_lms * inv_max_lms;

			LMStoXYZ(&color_lms.x(), &color_xyz.x());

			XYZToRGB(&color_xyz.x(), &color_adapted.x());

			remove_specials(color_adapted);

			// Final clamping for [0..1] RGB space
			clamp(color_adapted, 0, 1);

			iter.setValue(color_adapted);
		}
	}
}

void VoxelDatasetColor::apply_tm_hdr(const bool isRGB) {
	// Convert the values to current colorprofile
	for (auto iter = block->beginValueOn(); iter; ++iter) {
		if (!(iter->x() == 0 && iter->y() == 0 && iter->z() == 0)) {
			openvdb::Vec3f color_adapted;

			openvdb::Vec3f color_xyz = iter.getValue();

			if (isRGB) {
				XYZToRGB(&color_xyz.x(), &color_adapted.x());
			} else {
				color_adapted = color_xyz;
			}

			// Remove negative values
			clamp(color_adapted, 0, FLT_MAX);

			remove_specials(color_adapted);

			iter.setValue(color_adapted);
		}
	}
}

void VoxelDatasetColor::apply_tm_gamma(const bool isRGB) {
	const float inv_gamma = 1.0 / 2.2;

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

			// Apply Gamma correction, with Gamma 2.2
			color_rgb_adapted.x() = pow(color_rgb.x(), inv_gamma);
			color_rgb_adapted.y() = pow(color_rgb.y(), inv_gamma);
			color_rgb_adapted.z() = pow(color_rgb.z(), inv_gamma);

			// Final clamping for [0..1] RGB space
			clamp(color_rgb_adapted, 0, 1);

			iter.setValue(color_rgb_adapted);
		}
	}
}
