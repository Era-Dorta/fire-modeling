/*
 * FuelTypes.h
 *
 *  Created on: 19 Aug 2015
 *      Author: gdp24
 */

#ifndef FUELTYPES_H_
#define FUELTYPES_H_

#include <string>
#include <array>

enum FuelType {
	BlackBody, Propane, Acetylene, Cu, S, SootMax = Acetylene, FuelTypeMax = S
};

static const std::array<std::string, FuelTypeMax + 1> FuelTypeStr { "BlackBody",
		"Propane", "Acetylene", "Cu", "S" };

#endif /* FUELTYPES_H_ */
