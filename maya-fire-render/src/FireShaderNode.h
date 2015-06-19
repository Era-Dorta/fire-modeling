#ifndef FIRESHADERNODE_H
#define FIRESHADERNODE_H

#include <maya/MPxNode.h>
#include <maya/MDataBlock.h>
#include <maya/MPlug.h>

class FireShaderNode: public MPxNode {
public:
	FireShaderNode();
	virtual ~FireShaderNode();

	virtual MStatus compute(const MPlug&, MDataBlock&) override;
	virtual void postConstructor() override;

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

	// Attributes for raytracing
	static MObject aRayOrigin;
	static MObject aRayDirection;
	static MObject aRaySampler;
	static MObject aRayDepth;
	static MObject aNormalCamera;
	static MObject aPointCamera;
};

#endif
