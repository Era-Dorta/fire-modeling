/*
 * LoadFireDataCmd.cpp
 *
 *  Created on: 14 Jun 2016
 *      Author: gdp24
 */

#include "LoadFireDataCmd.h"

#include <maya/MSelectionList.h>
#include <maya/MGlobal.h>
#include <maya/MItSelectionList.h>
#include <maya/MArgDatabase.h>

const char *scaleFlag = "-s", *scaleLongFlag = "-scale";
const char *offsetFlag = "-o", *offsetLongFlag = "-offset";
const char *typeFlag = "-t", *typeLongFlag = "-type";

MStatus LoadFireDataCmd::doIt(const MArgList& args) {
	MStatus stat;
	MString typeStr("temperature");

	scale = 1;
	offset = 0;
	type = TEMPERATURE;

	MArgDatabase argData(syntax(), args);
	if (argData.isFlagSet(scaleFlag)) {
		argData.getFlagArgument(scaleFlag, 0, scale);
	}
	if (argData.isFlagSet(offsetFlag)) {
		argData.getFlagArgument(offsetFlag, 0, offset);
	}
	if (argData.isFlagSet(typeFlag)) {
		argData.getFlagArgument(typeFlag, 0, typeStr);

		if (typeStr == "density") {
			type = DENSITY;
		} else if (typeStr == "temperature") {
			type = TEMPERATURE;
		} else {
			MGlobal::displayError(
					"Valid types are: \"temperature\", \"density\"");
			return MStatus::kFailure;
		}
	}

	MSelectionList selection;

	// Set the list of selected objects to contain the fluid shape
	selection.clear();

	MString fluidName;

	argData.getCommandArgument(0, fluidName);
	argData.getCommandArgument(1, filename);

	MGlobal::getSelectionListByName(fluidName, selection);

	selection.getDagPath(0, fluidShapePath);

	if (!fluidShapePath.isValid()) {
		MGlobal::displayError("Please, enter a valid fluid shape name");
		return MStatus::kFailure;
	}

	return load_fluid_data();
}

MStatus LoadFireDataCmd::undoIt() {
	//TODO Save previous fluid temperature and restore it here
	return MStatus::kSuccess;
}

MStatus LoadFireDataCmd::redoIt() {
	return load_fluid_data();
}

bool LoadFireDataCmd::isUndoable() const {
	return false;
}

void* LoadFireDataCmd::creator() {
	return new LoadFireDataCmd;
}

MSyntax LoadFireDataCmd::newSyntax() {
	MSyntax syntax;
	syntax.addFlag(scaleFlag, scaleLongFlag, MSyntax::kDouble);
	syntax.addFlag(offsetFlag, offsetLongFlag, MSyntax::kDouble);
	syntax.addFlag(typeFlag, typeLongFlag, MSyntax::kString);
	syntax.addArg(MSyntax::kString);
	syntax.addArg(MSyntax::kString);
	return syntax;
}

MStatus LoadFireDataCmd::load_fluid_data() {
	MStatus stat;
	MFnFluid fluidFn(fluidShapePath, &stat);

	// Is fluid shape?
	if (!fluidShapePath.isValid() || !stat) {
		MGlobal::displayError("Please, enter a valid fluid shape");
		return MStatus::kFailure;
	}

	// Can be edited?
	MFnFluid::FluidMethod method;
	MFnFluid::FluidGradient gradient;
	switch (type) {
	case TEMPERATURE: {
		fluidFn.getTemperatureMode(method, gradient);
		break;
	}
	case DENSITY: {
		fluidFn.getDensityMode(method, gradient);
		break;
	}
	}
	if (method != MFnFluid::kDynamicGrid) {
		MGlobal::displayError(MString("Fluid density and/or temperature must "
				"be set to Dynamic Grid"));
		return MStatus::kFailure;
	}

	std::ifstream fp(filename.asChar(), std::ios::in | std::ios::binary);
	if (!fp.is_open()) {
		MGlobal::displayError("Could not open file " + filename);
		return MStatus::kFailure;
	}

	try {

		int width, height, depth;

		safe_binary_read(fp, reinterpret_cast<char*>(&width), 4);
		safe_binary_read(fp, reinterpret_cast<char*>(&height), 4);
		safe_binary_read(fp, reinterpret_cast<char*>(&depth), 4);
		if (width < 0 && height < 0 && depth < 0) {
			fp.close();
			MGlobal::displayError("Invalid size " + filename);
			return MStatus::kFailure;
		}

		int count;
		// Number of points in the file, integer, 4 bytes
		safe_binary_read(fp, reinterpret_cast<char*>(&count), 4);
		if (count <= 0) {
			fp.close();
			MGlobal::displayError("Invalid size " + filename);
			return MStatus::kFailure;
		}

		// Has same resolution?
		unsigned fluidRes[3];
		fluidFn.getResolution(fluidRes[0], fluidRes[1], fluidRes[2]);
		if (fluidRes[0] != (unsigned) width || fluidRes[1] != (unsigned) height
				|| fluidRes[2] != (unsigned) depth) {
			fp.close();
			MGlobal::displayError(
					MString("Size don't match, raw file size is ") + width + "x"
							+ height + "x" + depth + " fluid size "
							+ fluidRes[0] + "x" + fluidRes[1] + "x"
							+ fluidRes[2]);
			return MStatus::kFailure;
		}

		// Clear all the temperatures
		for (unsigned i = 0; i < fluidFn.gridSize(); i++) {
			switch (type) {
			case TEMPERATURE: {
				fluidFn.temperature()[i] = 0;
				break;
			}
			case DENSITY: {
				fluidFn.density()[i] = 0;
				break;
			}
			}
		}

		unsigned x, y, z;
		double r, g, b, a;

		for (int i = 0; i < count; i++) {
			// Coordinates, integer, 4 bytes, flip y,z due to Matlab indexing
			read_bin_xyz(fp, x, z, y);

			if (x == 0 || y == 0 || z == 0) {
				MGlobal::displayError(
						MString("Invalid index ") + x + "," + y + "," + z + " "
								+ filename);
				return MStatus::kFailure;
			}

			// Data comes from Matlab in 1..N, but here we use 0..N-1
			x--;
			y--;
			z--;

			if ((int) x >= width || (int) y >= height || (int) z >= depth) {
				MGlobal::displayError(
						MString("Invalid index ") + x + "," + y + "," + z + " "
								+ filename);
				return MStatus::kFailure;
			}

			// RGBA components, double, 8 bytes
			read_bin_rgba(fp, r, g, b, a);

			float max_val = static_cast<float>(std::max(std::max(r, g), b));

			// Divide by 256 to get the rgb values in [0..1]
			max_val =
					static_cast<float>(max_val * 0.00390625f * scale + offset);

			// Save the value in the array
			switch (type) {
			case TEMPERATURE: {
				fluidFn.temperature()[fluidFn.index(x, y, z)] = max_val;
				break;
			}
			case DENSITY: {
				fluidFn.density()[fluidFn.index(x, y, z)] = max_val;
				break;
			}
			}
		}

		fp.close();
		fluidFn.updateGrid();
		return MStatus::kSuccess;
	} catch (const std::ios_base::failure& e) {
		fp.close();
		MGlobal::displayError("Wrong format in file " + filename);
		return MStatus::kFailure;
	}
}

void LoadFireDataCmd::safe_binary_read(std::ifstream& fp, char *output,
		long int byte_size) {
	fp.read(output, byte_size);
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}

void LoadFireDataCmd::read_bin_xyz(std::ifstream& fp, unsigned& x, unsigned& y,
		unsigned& z) {
	safe_binary_read(fp, reinterpret_cast<char*>(&x), 4);
	safe_binary_read(fp, reinterpret_cast<char*>(&y), 4);
	safe_binary_read(fp, reinterpret_cast<char*>(&z), 4);
}

void LoadFireDataCmd::read_bin_rgba(std::ifstream& fp, double& r, double& g,
		double& b, double& a) {
	// RGBA components, double, 8 bytes
	safe_binary_read(fp, reinterpret_cast<char*>(&r), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&g), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&b), 8);
	safe_binary_read(fp, reinterpret_cast<char*>(&a), 8);
}
