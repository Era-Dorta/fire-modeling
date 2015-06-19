#ifndef VOLUMEFIRECMD_H
#define VOLUMEFIRECMD_H

#include <vector>

#include <maya/MPxCommand.h>
#include <maya/MDGModifier.h>
#include<maya/MFnSet.h>

class VolumeFireCmd: public MPxCommand {

public:
	virtual MStatus doIt(const MArgList&) override;
	virtual MStatus undoIt() override;
	virtual MStatus redoIt() override;
	virtual bool isUndoable() const override;
	static void *creator();
	static MSyntax newSyntax();

private:
	MDGModifier dgMod;

	MObject getNodeByName(const MString& nodeName);
};

#endif
