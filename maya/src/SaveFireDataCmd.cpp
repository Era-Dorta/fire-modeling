#include "SaveFireDataCmd.h"

#include <maya/MSelectionList.h>
#include <maya/MGlobal.h>
#include <maya/MItSelectionList.h>

#ifdef _WIN32
#define FILE_SEP "\\"
#else
#define FILE_SEP "/"
#endif

MStatus SaveFireDataCmd::doIt(const MArgList &args) {
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
		MGlobal::displayError("Please, select a fluid shape");
		return MStatus::kFailure;
	}

	// Check that only one argument is given
	if (args.length() == 0) {
		MGlobal::displayError(
				"Please, provide directory path to save the files");
		return MStatus::kFailure;
	}

	if (args.length() >= 3) {
		MGlobal::displayError("Too many input arguments");
		return MStatus::kFailure;
	}

	if (args.length() == 1) {
		background_threshold = 1e-6;
	} else {
		args.get(1, background_threshold);
	}

	// Get directory path
	args.get(0, dirname);

	if (dirname.numChars() < 1) {
		MGlobal::displayError("Please enter a valid directory path");
		return MStatus::kFailure;
	}

	// Add file separator at the end of the file name if the user did not add it
	const int file_sep_pos = dirname.rindex(FILE_SEP[0]);
	if (file_sep_pos == -1
			|| unsigned(file_sep_pos) != dirname.numChars() - 1) {
		dirname = dirname + FILE_SEP;
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
		MGlobal::displayError("Please, select a fluid shape");
		return MStatus::kFailure;
	}

	// Get the volume grid dimensions
	unsigned fluidRes[3];
	fluidFn.getResolution(fluidRes[0], fluidRes[1], fluidRes[2]);

	// Save the density
	MString filename = dirname + "density.raw";
	stat = save_fluid_internal(fluidRes, fluidFn.density(), filename, fluidFn);
	if (stat != MStatus::kSuccess) {
		return stat;
	}

	// Save the temperature
	filename = dirname + "temperature.raw";
	stat = save_fluid_internal(fluidRes, fluidFn.temperature(), filename,
			fluidFn);
	if (stat != MStatus::kSuccess) {
		return stat;
	}

	MGlobal::displayInfo("Saved density and temperature for " + fluidFn.name());

	return MStatus::kSuccess;
}

MStatus SaveFireDataCmd::save_fluid_internal(const unsigned fluidRes[3],
		const float* data, const MString& filename, MFnFluid& fluidFn) {

	if (is_file_exist(filename)) {
		MGlobal::displayError("File " + filename + " already exists");
		return MStatus::kFailure;
	}

	// Count active voxels, assume 0 is background
	int count = 0;
	for (unsigned i = 0; i < fluidRes[0]; i++) {
		for (unsigned j = 0; j < fluidRes[1]; j++) {
			for (unsigned k = 0; k < fluidRes[2]; k++) {
				if (data[fluidFn.index(i, j, k)] > background_threshold) {
					count++;
				}
			}
		}
	}

	// Saving data in filename with raw 2 format
	std::ofstream fp(filename.asChar(), std::ios::out | std::ios::binary);
	if (!fp.is_open()) {
		MGlobal::displayError("Could not open file " + filename);
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

		for (unsigned i = 1; i <= fluidRes[0]; i++) {
			for (unsigned j = 1; j <= fluidRes[1]; j++) {
				for (unsigned k = 1; k <= fluidRes[2]; k++) {
					double density_val =
							data[fluidFn.index(i - 1, j - 1, k - 1)];
					if (density_val > background_threshold) {
						// Save, x,y,z for each point, switch y, z for Matlab
						// consistency, and move to 1..N
						bin_write(fp, reinterpret_cast<const char*>(&i), 4);
						bin_write(fp, reinterpret_cast<const char*>(&k), 4);
						bin_write(fp, reinterpret_cast<const char*>(&j), 4);

						// Save as RGBA, read file will divide by 256
						density_val *= 256.0;
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
	return MStatus::kSuccess;
}

void SaveFireDataCmd::bin_write(std::ofstream& fp, const char *input,
		long int byte_size) const {
	fp.write(input, byte_size);
	if (!fp) {
		fp.exceptions(fp.failbit);
	}
}

bool SaveFireDataCmd::is_file_exist(const MString& filename) const {
	std::ifstream infile(filename.asChar());
	return infile.good();
}
