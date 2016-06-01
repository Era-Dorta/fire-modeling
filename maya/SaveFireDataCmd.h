#ifndef SAVEFIREDATACMD_H
#define SAVEFIREDATACMD_H

#include <fstream>

#include <maya/MPxCommand.h>
#include <maya/MArgList.h>
#include <maya/MDagPath.h>
#include <maya/MFnFluid.h>

class SaveFireDataCmd: public MPxCommand {

public:
	virtual MStatus doIt(const MArgList&args) override;
	virtual MStatus undoIt() override;
	virtual MStatus redoIt() override;
	virtual bool isUndoable() const override;
	static void *creator();

private:
	MStatus save_fluid_data();
	MStatus save_fluid_internal(const unsigned fluidRes[3], const float* data,
			const MString& filename, MFnFluid& fluidFn);
	void bin_write(std::ofstream& fp, const char *input,
			long int byte_size) const;
	bool is_file_exist(const MString &filename) const;

private:
	MDagPath fluidShapePath;
	MString dirname;
};

#endif
