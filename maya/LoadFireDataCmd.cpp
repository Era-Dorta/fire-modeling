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

#define MAX_DATASET_DIM 128

MStatus LoadFireDataCmd::doIt(const MArgList& args) {
	MStatus stat;
	MSelectionList selection;

	// Get a list of currently selected objects
	selection.clear();

	MString fluidName;
	args.get(0, fluidName);

	MGlobal::getSelectionListByName(fluidName, selection);

	selection.getDagPath(0, fluidShapePath);

	if (!fluidShapePath.isValid()) {
		MGlobal::displayError("Please, enter a valid fluid shape name");
		return MStatus::kFailure;
	}

	// Check that only one argument is given
	if (args.length() <= 3) {
		MGlobal::displayError("Please, enter a shape name and a raw file path");
		return MStatus::kFailure;
	}

	if (args.length() >= 5) {
		MGlobal::displayError("Too many input arguments");
		return MStatus::kFailure;
	}

	// Get filename path
	args.get(1, filename);

	args.get(2, scale);
	args.get(3, offset);

	return load_fluid_data();
}

MStatus LoadFireDataCmd::undoIt() {
	// One option would be to delete the file, but it is safer to do nothing
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

MStatus LoadFireDataCmd::load_fluid_data() {
	MStatus stat;
	MFnFluid fluidFn(fluidShapePath, &stat);

	if (!fluidShapePath.isValid() || !stat) {
		MGlobal::displayError("Please, enter a valid fluid shape");
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

		// Clear all temperatures
		for (unsigned i = 0; i < fluidFn.gridSize(); i++) {
			fluidFn.temperature()[i] = 0;
		}

		unsigned x, y, z;
		double r, g, b, a;

		for (int i = 0; i < count; i++) {
			// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
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

			// For the temperature, use the channel with maximum intensity
			fluidFn.temperature()[fluidFn.index(x, y, z)] = max_val;
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
	// Coordinates, integer, 4 bytes, flip y,z, probably Matlab stuff
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
