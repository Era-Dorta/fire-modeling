/*
 * SootOpticalConstants.h
 *
 *  Created on: 29 Jun 2015
 *      Author: gdp24
 */

#ifndef SOOTOPTICALCONSTANTS_H_
#define SOOTOPTICALCONSTANTS_H_

#include <cmath>

// Data from Optical Constants of Soot and Their Application to Heat-Flux
// Calculations, 1969
namespace Soot {
const static miScalar sampleSize = 13;
const static miScalar lambda[] = { 0.4358, 0.4500, 0.5500, 0.6500, 0.8065, 2.5,
		3.0, 4.0, 5.0, 6.0, 7.0, 8.5, 10.0 };
const static miScalar n[] = { 1.57, 1.56, 1.57, 1.56, 1.57, 2.04, 2.21, 2.38,
		2.07, 2.62, 3.05, 3.26, 3.48 };
const static miScalar nk[] = { 0.46, 0.50, 0.53, 0.52, 0.49, 1.15, 1.23, 1.44,
		1.72, 1.67, 1.91, 2.10, 2.46 };
// k = nk / n
const static miScalar k[] = { 0.2930, 0.3205, 0.3376, 0.3333, 0.3121, 0.5637,
		0.5566, 0.6050, 0.8309, 0.6374, 0.6262, 0.6442, 0.7069 };
// Paper says it ranges from 50 to 800, so take the mean
const static miScalar R = 425;
const static miScalar alpha_lambda = 1.39;
const static miScalar PI_R3_36 = (4.0 / 3.0) * M_PI * R * R * R * 36 * M_PI;
}

#endif /* SOOTOPTICALCONSTANTS_H_ */
