/*
 * AbsorptionData.h
 *
 *  Created on: 5 Apr 2016
 *      Author: gdp24
 */

#ifndef ABSORPTIONSPECTRUM_H_
#define ABSORPTIONSPECTRUM_H_

#include <vector>
#include <fstream>

#include "Spectrum.h"
#include "FuelTypes.h"

class AbsorptionSpectrum {
public:
	AbsorptionSpectrum(FuelType fuel_type);

	// Computes and returns the absorption spectrum
	const Spectrum& compute(float density, float temperature = 300);

	void clear();

	const Spectrum& getCoefSpec() const;
	Spectrum& getCoefSpec();
	void setCoefSpec(const Spectrum& coefSpec);

	bool isInValidState() const;

private:
	void compute_soot_constant_coefficients();
	bool read_spectral_line_file(const std::string& filename);
	bool read_optical_constants_file(const std::string& filename);
	template<typename T>
	void safe_ascii_read(std::ifstream& fp, T &output);

private:
	std::vector<float> lambdas;
	std::vector<float> phi;
	std::vector<float> n;
	std::vector<float> A21;
	std::vector<float> k;
	std::vector<float> E1;
	std::vector<float> soot_coef;
	std::vector<float> E2;
	std::vector<int> g1;
	std::vector<int> g2;
	miScalar soot_radius;
	miScalar alpha_lambda;

	Spectrum coef_spec;
	FuelType fuel_type;
	bool in_valid_state;
};

#endif /* ABSORPTIONSPECTRUM_H_ */
