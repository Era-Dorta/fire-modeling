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
	BlackBody,
	Propane,
	Acetylene,
	Cu,
	S,
	Li,
	Ba,
	Na,
	Co,
	Sc,
	SootMax = Acetylene,
	FuelTypeMax = Sc
};

static const std::array<std::string, FuelTypeMax + 1> FuelTypeStr { "BlackBody",
		"Propane", "Acetylene", "Cu", "S", "Li", "Ba", "Na", "Co", "Sc" };

#endif /* FUELTYPES_H_ */
