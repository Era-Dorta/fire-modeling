/*
 * RenderingConstants.h
 *
 *  Created on: 29 Jun 2015
 *      Author: gdp24
 */

#ifndef RENDERINGCONSTANTS_H_
#define RENDERINGCONSTANTS_H_

#include <cmath>

// Data from Optical Constants of Soot and Their Application to Heat-Flux
// Calculations, 1969
namespace Soot {
const static miScalar num_samples = 4;
const static miScalar lambda[] = { 0.4358e-6, 0.4500e-6, 0.5500e-6, 0.6500e-6,
		0.8065e-6, 2.5e-6, 3.0e-6, 4.0e-6, 5.0e-6, 6.0e-6, 7.0e-6, 8.5e-6,
		10.0e-6 };
const static miScalar lambda_nano[] = { 0.4358e3, 0.4500e3, 0.5500e3, 0.6500e3,
		0.8065e3, 2.5e3, 3.0e3, 4.0e3, 5.0e3, 6.0e3, 7.0e3, 8.5e3, 10.0e3 };
const static miScalar n[] = { 1.57, 1.56, 1.57, 1.56, 1.57, 2.04, 2.21, 2.38,
		2.07, 2.62, 3.05, 3.26, 3.48 };
const static miScalar nk[] = { 0.46, 0.50, 0.53, 0.52, 0.49, 1.15, 1.23, 1.44,
		1.72, 1.67, 1.91, 2.10, 2.46 };
// k = nk / n
const static miScalar k[] = { 0.2930, 0.3205, 0.3376, 0.3333, 0.3121, 0.5637,
		0.5566, 0.6050, 0.8309, 0.6374, 0.6262, 0.6442, 0.7069 };
// Paper says it ranges from 50 to 800 Angstroms, so take the mean
const static miScalar R = 425e-10;
const static miScalar alpha_lambda = 1.39;
const static miScalar PI_R3_36 = (4.0 / 3.0) * M_PI * R * R * R * 36 * M_PI;
}

// Data from Optical Constants of Soot and Their Application to Heat-Flux
// Calculations, 1969
namespace BB {
const static unsigned num_samples = 30;
const static miScalar k = 1.3806488e-23; // Bolztmann constant in J/K
//const static miScalar k = 8.6173324e-5; // Bolztmann constant in eV/K
//const static miScalar k = 1.3806488e-16; // Bolztmann constant in erg/K
const static miScalar h = 6.62606957e-34; // Planck constant in J/s
const static miScalar c0 = 299792458; // Speed of light m/s
const static miScalar two_h = 2 * h;
}

#endif /* RENDERINGCONSTANTS_H_ */
