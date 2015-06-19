#include <maya/MRenderUtil.h>
#include <maya/MFnNumericAttribute.h>
#include <maya/MFloatVector.h>
#include "FireShaderNode.h"
//#include <maya/.h>

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
