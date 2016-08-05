/*
 * LoadFireDataCmd.h
 *
 *  Created on: 14 Jun 2016
 *      Author: gdp24
 */

#ifndef SRC_LOADFIREDATACMD_H_
#define SRC_LOADFIREDATACMD_H_

#include <fstream>

#include <maya/MPxCommand.h>
#include <maya/MArgList.h>
#include <maya/MDagPath.h>
#include <maya/MFnFluid.h>
#include <maya/MSyntax.h>

class LoadFireDataCmd: public MPxCommand {

public:
	virtual MStatus doIt(const MArgList&args) override;
	virtual MStatus undoIt() override;
	virtual MStatus redoIt() override;
	virtual bool isUndoable() const override;
	static void *creator();
	static MSyntax newSyntax();
private:
	MStatus load_fluid_data();
	void safe_binary_read(std::ifstream& fp, char *output, long int byte_size);
	void read_bin_xyz(std::ifstream& fp, unsigned& x, unsigned& y, unsigned& z);
	void read_bin_rgba(std::ifstream& fp, double& r, double& g, double& b,
			double& a);
private:
	enum FluidType {
		DENSITY, TEMPERATURE
	};

	MDagPath fluidShapePath;
	MString filename;
	FluidType type;
	double scale;
	double offset;
};

#endif /* SRC_LOADFIREDATACMD_H_ */
