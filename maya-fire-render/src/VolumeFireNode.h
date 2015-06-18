#ifndef VOLUMEFIRENODE_H
#define VOLUMEFIRENODE_H

#include <maya/MPxNode.h>
#include <maya/MDataBlock.h>
#include <maya/MPlug.h>

class VolumeFireNode: public MPxNode {
public:
	VolumeFireNode();
	virtual ~VolumeFireNode();

	virtual MStatus compute(const MPlug&, MDataBlock&);
	virtual void postConstructor();

	static void * creator();
	static MStatus initialize();

	static MTypeId id;

private:

	static MObject aColor;
	static MObject aInputValue;
	static MObject aOutColor;
	static MObject aOutTransparency;
	static MObject aFarPointC;
	static MObject aFarPointO;
	static MObject aFarPointW;
	static MObject aPointC;
	static MObject aPointO;
	static MObject aPointW;
	static MObject aToggleCamera;
	static MObject aToggleObject;
	static MObject aToggleWorld;
	static MObject aOutAlpha;
};

#endif
