/*
 * AbsorptionData.cpp
 *
 *  Created on: 5 Apr 2016
 *      Author: gdp24
 */

#include <cassert>
#include "AbsorptionSpectrum.h"

AbsorptionSpectrum::AbsorptionSpectrum(FuelType fuel_type) {
	assert(fuel_type != FuelType::BlackBody);

	this->fuel_type = fuel_type;
	soot_radius = 0;
	alpha_lambda = 0;
	in_valid_state = false;

	std::string data_file;

	data_file = LIBRARY_DATA_PATH;
	assert(static_cast<unsigned>(fuel_type) < FuelTypeStr.size());
	if (fuel_type <= FuelType::SootMax) {
		data_file += "/" + FuelTypeStr[fuel_type] + ".optconst";
		in_valid_state = read_optical_constants_file(data_file);
		if (in_valid_state) {
			compute_soot_constant_coefficients();
		}
	} else {
		data_file += "/" + FuelTypeStr[fuel_type] + ".specline";
		in_valid_state = read_spectral_line_file(data_file);
	}
}

const Spectrum& AbsorptionSpectrum::compute(float density, float temperature) {
	std::vector<float> spec_values(lambdas.size());

	/* Our input data is in the range of [0..10], yet the physical densities are
	 * several orders of magnitude higher, as they represent the number of
	 * molecules per unit volume. We are effectively multiplying the densities
	 * by this scale factor,
	 * Optical constants of soot in hydrocarbon flames, Lee et. al. 1981
	 * https://en.wikipedia.org/wiki/Number_density
	 */
	density = density * 1e26;

	if (fuel_type <= FuelType::SootMax) {
		for (unsigned j = 0; j < spec_values.size(); j++) {
			spec_values.at(j) = density * soot_coef[j];
		}

		// Soot samples approximate continuous data
		coef_spec = Spectrum::FromSampled(&lambdas[0], &spec_values[0],
				lambdas.size());
	} else {
		ChemicalAbsorption(&lambdas[0], &phi[0], &A21[0], &E1[0], &E2[0],
				&g1[0], &g2[0], lambdas.size(), temperature, 1, density,
				&spec_values[0]);

		// Chemical absorption represents "discrete" spectral lines
		coef_spec = Spectrum::FromSampledNoAverage(&lambdas[0], &spec_values[0],
				lambdas.size());
	}

	return coef_spec;
}

void AbsorptionSpectrum::clear() {
	lambdas.clear();
	phi.clear();
	A21.clear();
	E1.clear();
	E2.clear();
	g1.clear();
	g2.clear();
	n.clear();
	k.clear();
	soot_coef.clear();
}

void AbsorptionSpectrum::compute_soot_constant_coefficients() {
	// TODO If we wanted to sample more from the spectrum, we would have to
	// compute lambda^alpha_lambda in compute_sigma_a, in any case I don't think
	// it makes sense, as we do not have more n or k data
	soot_coef.resize(n.size());

	// In m^3
	double pi_r3_36 = (4.0f / 3.0f) * M_PI * soot_radius * soot_radius
			* soot_radius * 36.0f * M_PI;

	for (unsigned i = 0; i < n.size(); i++) {
		double n2_k2_2 = n[i] * n[i] - k[i] * k[i] + 2;
		n2_k2_2 = n2_k2_2 * n2_k2_2;

		// Convert wavelengths to micrometers, result looks like is
		// 1/micrometer^(alpha_lambda) but because its an empirical fit we can
		// assume that it outputs the right units, 1/m

		soot_coef[i] = (pi_r3_36 * n[i] * k[i])
				/ (std::pow(lambdas[i] * 1e-3, alpha_lambda)
						* (n2_k2_2 + 4 * n[i] * n[i] * k[i] * k[i]));
	}
}

bool AbsorptionSpectrum::read_spectral_line_file(const std::string& filename) {
	std::ifstream fp(filename, std::ios_base::in);
	if (!fp.is_open()) {
		mi_error("Could not open spectral line file \"%s\".", filename.c_str());
		return false;
	}
	unsigned num_lines = 0;
	try {
		safe_ascii_read(fp, num_lines);
		if (num_lines == 0) {
			throw std::ios_base::failure("No data in file");
		}

		lambdas.resize(num_lines); // nanometres
		phi.resize(num_lines); // dimensionless
		A21.resize(num_lines); // 1/seconds
		E1.resize(num_lines); // 1/centimetres, energy unit
		E2.resize(num_lines); // 1/centimetres, energy unit
		g1.resize(num_lines); // dimensionless
		g2.resize(num_lines); // dimensionless

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

bool AbsorptionSpectrum::read_optical_constants_file(
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

		// Soot radius in metres
		safe_ascii_read(fp, soot_radius);

		// Alpha(lambda) coefficient, dimensionless
		safe_ascii_read(fp, alpha_lambda);

		// Wave lengths in nanometres
		lambdas.resize(num_lines);

		// Optical constants, dimensionless
		n.resize(num_lines);
		k.resize(num_lines);

		for (unsigned i = 0; i < num_lines; i++) {
			safe_ascii_read(fp, lambdas[i]);
			safe_ascii_read(fp, n[i]);
			safe_ascii_read(fp, k[i]);
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
void AbsorptionSpectrum::safe_ascii_read(std::ifstream& fp, T &output) {
	fp >> output;
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}

const Spectrum& AbsorptionSpectrum::getCoefSpec() const {
	return coef_spec;
}

Spectrum& AbsorptionSpectrum::getCoefSpec() {
	return coef_spec;
}

void AbsorptionSpectrum::setCoefSpec(const Spectrum& coefSpec) {
	coef_spec = coefSpec;
}

bool AbsorptionSpectrum::isInValidState() const {
	return in_valid_state;
}
