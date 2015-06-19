#include "VolumeFireCmd.h"
#include "FireShaderNode.h"

#include<cassert>

#include<maya/MStatus.h>
#include<maya/MItDependencyNodes.h>
#include<maya/MSelectionList.h>
#include<maya/MGlobal.h>
#include<maya/MDagPath.h>
#include<maya/MFnDagNode.h>
#include<maya/MPlugArray.h>
#include<maya/MPlug.h>
#include<maya/MString.h>

MStatus VolumeFireCmd::doIt(const MArgList &) {
	MStatus stat;

	MFnSet initialSgFn(getNodeByName("initialShadingGroup"));

	MFnSet particleSgFn(getNodeByName("initialParticleSE"));

	// TODO Do this for each fire emitter in the scene

	MObject fireShaderNode = dgMod.createNode(FireShaderNode::id);
	assert(!fireShaderNode.isNull());

	// Connect the output color of our shading node to the volume shader of the
	// particle emitter
	MFnDependencyNode fireShaderNodeFn(fireShaderNode);
	MPlug fireNodeColorPlug = fireShaderNodeFn.findPlug("outColor");
	MPlug particleSgVolShaderPlug = particleSgFn.findPlug("volumeShader");
	dgMod.connect(fireNodeColorPlug, particleSgVolShaderPlug);

	return redoIt();
}

MStatus VolumeFireCmd::undoIt() {
	return dgMod.undoIt();
}

MStatus VolumeFireCmd::redoIt() {
	return dgMod.doIt();
}

bool VolumeFireCmd::isUndoable() const {
	return true;
}

void *VolumeFireCmd::creator() {
	return new VolumeFireCmd;
}

MObject VolumeFireCmd::getNodeByName(const MString& nodeName) {
	MSelectionList selection;
	// N.B. Ensure the selection is list empty beforehand since
	// getSelectionListByName() will append the matching objects
	selection.clear();

	CHECK_MSTATUS(MGlobal::getSelectionListByName(nodeName, selection));
	// Get the initial shading group

	MObject shadingGroupObj;
	CHECK_MSTATUS(selection.getDependNode(0, shadingGroupObj));

	return shadingGroupObj;
}
