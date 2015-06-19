#include <maya/MRenderUtil.h>
#include <maya/MFnNumericAttribute.h>
#include <maya/MFloatVector.h>
#include "FireShaderNode.h"

MTypeId FireShaderNode::id(0x81012);

MObject FireShaderNode::aColor;
MObject FireShaderNode::aInputValue;
MObject FireShaderNode::aOutColor;
MObject FireShaderNode::aOutTransparency;
MObject FireShaderNode::aOutAlpha;
MObject FireShaderNode::aFarPointC;
MObject FireShaderNode::aFarPointO;
MObject FireShaderNode::aFarPointW;
MObject FireShaderNode::aPointC;
MObject FireShaderNode::aPointO;
MObject FireShaderNode::aPointW;
MObject FireShaderNode::aToggleCamera;
MObject FireShaderNode::aToggleObject;
MObject FireShaderNode::aToggleWorld;

MObject FireShaderNode::aRayOrigin;
MObject FireShaderNode::aRayDirection;
MObject FireShaderNode::aRaySampler;
MObject FireShaderNode::aRayDepth;
MObject FireShaderNode::aNormalCamera;
MObject FireShaderNode::aPointCamera;

#define MAKE_INPUT(attr)						\
    CHECK_MSTATUS ( attr.setKeyable(true) );  	\
	CHECK_MSTATUS ( attr.setStorable(true) );	\
    CHECK_MSTATUS ( attr.setReadable(true) );  \
	CHECK_MSTATUS ( attr.setWritable(true) );

void FireShaderNode::postConstructor() {
	setMPSafe(true);
}

//
// DESCRIPTION:
///////////////////////////////////////////////////////
FireShaderNode::FireShaderNode() {
}

//
// DESCRIPTION:
///////////////////////////////////////////////////////
FireShaderNode::~FireShaderNode() {
}

//
// DESCRIPTION:
///////////////////////////////////////////////////////
void* FireShaderNode::creator() {
	return new FireShaderNode();
}

//
// DESCRIPTION:
///////////////////////////////////////////////////////
MStatus FireShaderNode::initialize() {
	MFnNumericAttribute nAttr;

	// Inputs
	aColor = nAttr.createColor("color", "c");
	CHECK_MSTATUS(nAttr.setKeyable(true));
	CHECK_MSTATUS(nAttr.setStorable(true));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setDefault(1.0f, 1.0f, 1.0f));

	aInputValue = nAttr.create("distance", "d", MFnNumericData::kFloat);
	CHECK_MSTATUS(nAttr.setMin(0.0f));
	CHECK_MSTATUS(nAttr.setMax(100000.0f));
	CHECK_MSTATUS(nAttr.setSoftMax(1000.0f));
	CHECK_MSTATUS(nAttr.setSoftMax(1000.0f));
	CHECK_MSTATUS(nAttr.setKeyable(true));
	CHECK_MSTATUS(nAttr.setStorable(true));
	CHECK_MSTATUS(nAttr.setDefault(1.0f));

	aToggleCamera = nAttr.create("cameraSpace", "cs", MFnNumericData::kBoolean);

	CHECK_MSTATUS(nAttr.setKeyable(true));
	CHECK_MSTATUS(nAttr.setStorable(true));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setDefault(false));

	aToggleObject = nAttr.create("objectSpace", "os", MFnNumericData::kBoolean);
	CHECK_MSTATUS(nAttr.setKeyable(true));
	CHECK_MSTATUS(nAttr.setStorable(true));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setDefault(false));

	aToggleWorld = nAttr.create("worldSpace", "ws", MFnNumericData::kBoolean);
	CHECK_MSTATUS(nAttr.setKeyable(true));
	CHECK_MSTATUS(nAttr.setStorable(true));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setDefault(true));

	aFarPointC = nAttr.createPoint("farPointCamera", "fc");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	aFarPointO = nAttr.createPoint("farPointObj", "fo");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	aFarPointW = nAttr.createPoint("farPointWorld", "fw");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	aPointC = nAttr.createPoint("pointCamera", "p");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	aPointO = nAttr.createPoint("pointObj", "po");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	aPointW = nAttr.createPoint("pointWorld", "pw");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(true));

	// Outputs

	aOutColor = nAttr.createColor("outColor", "oc");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(false));

	aOutTransparency = nAttr.createColor("outTransparency", "ot");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(false));

	aOutAlpha = nAttr.create("outAlpha", "oa", MFnNumericData::kFloat);
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(false));
	CHECK_MSTATUS(nAttr.setReadable(true));
	CHECK_MSTATUS(nAttr.setWritable(false));

	// rayOrigin
	MObject RayX = nAttr.create("rayOx", "rxo", MFnNumericData::kFloat, 0.0);
	MObject RayY = nAttr.create("rayOy", "ryo", MFnNumericData::kFloat, 0.0);
	MObject RayZ = nAttr.create("rayOz", "rzo", MFnNumericData::kFloat, 0.0);
	aRayOrigin = nAttr.create("rayOrigin", "rog", RayX, RayY, RayZ);
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(false));

	// rayDirection
	RayX = nAttr.create("rayDirectionX", "rdx", MFnNumericData::kFloat, 1.0);
	RayY = nAttr.create("rayDirectionY", "rdy", MFnNumericData::kFloat, 0.0);
	RayZ = nAttr.create("rayDirectionZ", "rdz", MFnNumericData::kFloat, 0.0);
	aRayDirection = nAttr.create("rayDirection", "rad", RayX, RayY, RayZ);
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(false));

	// raySampler
	aRaySampler = nAttr.createAddr("raySampler", "rtr");
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(false));

	// rayDepth
	aRayDepth = nAttr.create("rayDepth", "rd", MFnNumericData::kShort, 0.0);
	CHECK_MSTATUS(nAttr.setStorable(false));
	CHECK_MSTATUS(nAttr.setHidden(true));
	CHECK_MSTATUS(nAttr.setReadable(false));

	aNormalCamera = nAttr.createPoint("normalCamera", "n");
	MAKE_INPUT(nAttr);
	CHECK_MSTATUS(nAttr.setDefault(1.0f, 1.0f, 1.0f));
	CHECK_MSTATUS(nAttr.setHidden(true));

	aPointCamera = nAttr.createPoint("pointCamera", "pc");
	MAKE_INPUT(nAttr);
	CHECK_MSTATUS(nAttr.setDefault(1.0f, 1.0f, 1.0f));
	CHECK_MSTATUS(nAttr.setHidden(true));

	CHECK_MSTATUS(addAttribute(aColor));
	CHECK_MSTATUS(addAttribute(aInputValue));
	CHECK_MSTATUS(addAttribute(aFarPointC));
	CHECK_MSTATUS(addAttribute(aFarPointO));
	CHECK_MSTATUS(addAttribute(aFarPointW));
	CHECK_MSTATUS(addAttribute(aPointC));
	CHECK_MSTATUS(addAttribute(aPointO));
	CHECK_MSTATUS(addAttribute(aPointW));
	CHECK_MSTATUS(addAttribute(aToggleCamera));
	CHECK_MSTATUS(addAttribute(aToggleObject));
	CHECK_MSTATUS(addAttribute(aToggleWorld));

	CHECK_MSTATUS(addAttribute(aOutColor));
	CHECK_MSTATUS(addAttribute(aOutTransparency));
	CHECK_MSTATUS(addAttribute(aOutAlpha));

	CHECK_MSTATUS(addAttribute(aRayOrigin));
	CHECK_MSTATUS(addAttribute(aRayDirection));
	CHECK_MSTATUS(addAttribute(aRaySampler));
	CHECK_MSTATUS(addAttribute(aRayDepth));
	CHECK_MSTATUS(addAttribute(aNormalCamera));
	CHECK_MSTATUS(addAttribute(aPointCamera));

	CHECK_MSTATUS(attributeAffects(aColor, aOutColor));
	CHECK_MSTATUS(attributeAffects(aColor, aOutTransparency));

	CHECK_MSTATUS(attributeAffects(aFarPointC, aOutColor));
	CHECK_MSTATUS(attributeAffects(aFarPointO, aOutColor));
	CHECK_MSTATUS(attributeAffects(aFarPointW, aOutColor));
	CHECK_MSTATUS(attributeAffects(aPointC, aOutColor));
	CHECK_MSTATUS(attributeAffects(aPointO, aOutColor));
	CHECK_MSTATUS(attributeAffects(aPointW, aOutColor));
	CHECK_MSTATUS(attributeAffects(aToggleCamera, aOutColor));
	CHECK_MSTATUS(attributeAffects(aToggleObject, aOutColor));
	CHECK_MSTATUS(attributeAffects(aToggleWorld, aOutColor));

	CHECK_MSTATUS(attributeAffects(aRayOrigin, aOutColor));
	CHECK_MSTATUS(attributeAffects(aRayDirection, aOutColor));
	CHECK_MSTATUS(attributeAffects(aRaySampler, aOutColor));
	CHECK_MSTATUS(attributeAffects(aRayDepth, aOutColor));

	return MS::kSuccess;
}

//
// DESCRIPTION:
///////////////////////////////////////////////////////
MStatus FireShaderNode::compute(const MPlug& plug, MDataBlock& block) {
	if ((plug != aOutColor) && (plug.parent() != aOutColor)
			&& (plug != aOutTransparency)
			&& (plug.parent() != aOutTransparency))
		return MS::kUnknownParameter;

	MFloatVector& InputColor = block.inputValue(aColor).asFloatVector();
	float Distance = block.inputValue(aInputValue).asFloat();

	MFloatVector& FarCamera = block.inputValue(aFarPointC).asFloatVector();
	MFloatVector& FarObject = block.inputValue(aFarPointO).asFloatVector();
	MFloatVector& FarWorld = block.inputValue(aFarPointW).asFloatVector();
	MFloatVector& PointCam = block.inputValue(aPointC).asFloatVector();
	MFloatVector& PointObj = block.inputValue(aPointO).asFloatVector();
	MFloatVector& PointWor = block.inputValue(aPointW).asFloatVector();

	bool Camera = block.inputValue(aToggleCamera).asBool();
	bool Object = block.inputValue(aToggleObject).asBool();
	bool World = block.inputValue(aToggleWorld).asBool();

	MFloatVector interval(0.0, 0.0, 0.0);
	if (Camera) {
		interval = FarCamera - PointCam;
	}
	if (Object) {
		interval = FarObject - PointObj;
	}
	if (World) {
		interval = FarWorld - PointWor;
	}

	double value, dist;
	if ((value = ((interval[0] * interval[0]) + (interval[1] * interval[1])
			+ (interval[2] * interval[2])))) {
		dist = sqrt(value);
	} else
		dist = 0.0;

	MFloatVector resultColor(0.0, 0.0, 0.0);
	if (dist <= Distance) {
		resultColor[0] = InputColor[0];
		resultColor[1] = InputColor[1];
		resultColor[2] = InputColor[2];
	}

	if (true) {
		MStatus status;

		// required attributes for using raytracer
		// origin, direction, sampler, depth, and object id.
		//
		MDataHandle originH = block.inputValue(aRayOrigin, &status);
		MFloatVector origin = originH.asFloatVector();

		MDataHandle directionH = block.inputValue(aRayDirection, &status);
		MFloatVector direction = directionH.asFloatVector();

		MDataHandle samplerH = block.inputValue(aRaySampler, &status);
		void*& samplerPtr = samplerH.asAddr();

		MDataHandle depthH = block.inputValue(aRayDepth, &status);
		short depth = depthH.asShort();

		MFloatVector& surfaceNormal =
				block.inputValue(aNormalCamera).asFloatVector();
		MFloatVector& cameraPosition =
				block.inputValue(aPointCamera).asFloatVector();

		MFloatVector normal = surfaceNormal;
		MFloatVector point = cameraPosition;

		MFloatVector reflectColor;
		MFloatVector reflectTransparency;

		MFloatVector& triangleNormal = interval;

		// compute reflected ray
		MFloatVector l = -direction;
		float dot = l * normal;
		if (dot < 0.0)
			dot = -dot;
		MFloatVector refVector = 2 * normal * dot - l; 	// reflection ray
		float dotRef = refVector * triangleNormal;
		if (dotRef < 0.0) {
			const float s = 0.01f;
			MFloatVector mVec = refVector - dotRef * triangleNormal;
			mVec.normalize();
			refVector = mVec + s * triangleNormal;
		}
		CHECK_MSTATUS(refVector.normalize());

		status = MRenderUtil::raytrace(point,    	//  origin
				refVector,  //  direction
				nullptr, samplerPtr, //  sampler info
				depth,		//  ray depth
				reflectColor,	// output color and transp
				reflectTransparency);

		// add in the reflection color
		resultColor[0] += reflectColor[0];
		resultColor[1] += reflectColor[1];
		resultColor[2] += reflectColor[2];
	}

	// set ouput color attribute
	MDataHandle outColorHandle = block.outputValue(aOutColor);
	MFloatVector& outColor = outColorHandle.asFloatVector();
	outColor = resultColor;
	outColorHandle.setClean();

	// set output transparency
	MFloatVector transparency(resultColor[2], resultColor[2], resultColor[2]);
	MDataHandle outTransHandle = block.outputValue(aOutTransparency);
	MFloatVector& outTrans = outTransHandle.asFloatVector();
	outTrans = transparency;
	outTransHandle.setClean();

	MDataHandle outAlphaHandle = block.outputValue(aOutAlpha);
	float& outAlpha = outAlphaHandle.asFloat();
	outAlpha = resultColor[2];
	outAlphaHandle.setClean();

	return MS::kSuccess;
}
