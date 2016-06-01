#include "SaveFireDataCmd.h"

#include <maya/MSelectionList.h>
#include <maya/MGlobal.h>
#include <maya/MItSelectionList.h>
#include <maya/MFnFluid.h>

MStatus SaveFireDataCmd::doIt(const MArgList &) {
	MStatus stat;
	MSelectionList selection;

	// Get a list of currently selected objects
	selection.clear();
	MGlobal::getActiveSelectionList(selection);
	MItSelectionList iter(selection);

	// Get the first fluid
	iter.setFilter(MFn::kFluid);
	iter.reset();

	if (!iter.isDone()) {
		iter.getDagPath(fluidShapePath);
	}

	if (!fluidShapePath.isValid()) {
		MGlobal::displayInfo("Please, select a fluid shape");
		return MStatus::kFailure;
	}

	return save_fluid_data();
}

MStatus SaveFireDataCmd::undoIt() {
	// One option would be to delete the file, but it is safer to do nothing
	return MStatus::kSuccess;
}

MStatus SaveFireDataCmd::redoIt() {
	return save_fluid_data();
}

bool SaveFireDataCmd::isUndoable() const {
	return true;
}

void *SaveFireDataCmd::creator() {
	return new SaveFireDataCmd;
}

MStatus SaveFireDataCmd::save_fluid_data() {
	MStatus stat;
	MFnFluid fluidFn(fluidShapePath, &stat);

	if (!fluidShapePath.isValid() || !stat) {
		MGlobal::displayInfo("Please, select a fluid shape");
		return MStatus::kFailure;
	}

	// Get the volume grid dimensions
	unsigned fluidRes[3];
	fluidFn.getResolution(fluidRes[0], fluidRes[1], fluidRes[2]);

	const float *density = fluidFn.density();

	// Count active voxels, assume 0 is background
	int count = 0;
	for (unsigned i = 0; i < fluidRes[0]; i++) {
		for (unsigned j = 0; j < fluidRes[1]; j++) {
			for (unsigned k = 0; k < fluidRes[2]; k++) {
				if (density[fluidFn.index(i, j, k)] != 0) {
					count++;
				}
			}
		}
	}

	// Saving data in filename with raw 2 format
	std::string filename("/home/gdp24/outtest.raw");
	std::ofstream fp(filename, std::ios::out | std::ios::binary);
	if (!fp.is_open()) {
		MGlobal::displayError(("Could not open file " + filename).c_str());
		return MStatus::kFailure;
	}
	try {

		// Save width, height, depth, integer 4 bytes
		bin_write(fp, reinterpret_cast<const char*>(&fluidRes[0]), 4);
		bin_write(fp, reinterpret_cast<const char*>(&fluidRes[1]), 4);
		bin_write(fp, reinterpret_cast<const char*>(&fluidRes[2]), 4);

		// Number of points in the file, integer, 4 bytes
		bin_write(fp, reinterpret_cast<const char*>(&count), 4);

		const double zero = 0, one = 1;
		const char* zeroc = reinterpret_cast<const char*>(&zero);
		const char* onec = reinterpret_cast<const char*>(&one);

		for (unsigned i = 0; i < fluidRes[0]; i++) {
			for (unsigned j = 0; j < fluidRes[1]; j++) {
				for (unsigned k = 0; k < fluidRes[2]; k++) {
					double density_val = density[fluidFn.index(i, j, k)];
					if (density_val != 0) {
						// Save, x,y,z for each point, switch y, z for Matlab
						// consistency
						bin_write(fp, reinterpret_cast<const char*>(&i), 4);
						bin_write(fp, reinterpret_cast<const char*>(&k), 4);
						bin_write(fp, reinterpret_cast<const char*>(&j), 4);

						// Save as RGBA, read file will divide by 256
						density_val *= 256;
						bin_write(fp,
								reinterpret_cast<const char*>(&density_val), 8);
						bin_write(fp, zeroc, 8);
						bin_write(fp, zeroc, 8);
						bin_write(fp, onec, 8);
					}
				}
			}
		}

		fp.close();
	} catch (const std::ios_base::failure& e) {

		fp.close();
		MGlobal::displayError(e.what());
		return MStatus::kFailure;
	}

	MGlobal::displayInfo("Saved data for " + fluidFn.name());

	return MStatus::kSuccess;
}

void SaveFireDataCmd::bin_write(std::ofstream& fp, const char *input,
		long int byte_size) const {
	fp.write(input, byte_size);
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}
