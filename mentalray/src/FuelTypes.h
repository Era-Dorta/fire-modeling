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
	BlueSyn,
	Cu,
	S,
	Li,
	Ba,
	Na,
	Co,
	Sc,
	C,
	H,
	C3H8,
	SootMax = BlueSyn,
	FuelTypeMax = C3H8
};

static const std::array<std::string, FuelTypeMax + 1> FuelTypeStr { "BlackBody",
		"Propane", "Acetylene", "BlueSyn", "Cu", "S", "Li", "Ba", "Na", "Co",
		"Sc", "C", "H", "C3H8" };

#endif /* FUELTYPES_H_ */
