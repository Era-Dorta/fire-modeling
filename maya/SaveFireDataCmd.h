#ifndef SAVEFIREDATACMD_H
#define SAVEFIREDATACMD_H

#include <fstream>

#include <maya/MPxCommand.h>
#include <maya/MArgList.h>
#include <maya/MDagPath.h>

class SaveFireDataCmd: public MPxCommand {

public:
	virtual MStatus doIt(const MArgList&);
	virtual MStatus undoIt();
	virtual MStatus redoIt();
	virtual bool isUndoable() const;
	static void *creator();
//	static MSyntax newSyntax();

private:
	MStatus save_fluid_data();
	void bin_write(std::ofstream& fp, const char *input,
			long int byte_size) const;
private:
	MDagPath fluidShapePath;
};

#endif
