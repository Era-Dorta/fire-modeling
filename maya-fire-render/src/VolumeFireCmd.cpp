#include "VolumeFireCmd.h"

#include "VolumeFireNode.h"

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

	MFnSet shadingGroupFn(getInitianShadingGroup());

	// create an iterator to go through all nodes
	MItDependencyNodes it(MFn::kRenderSphere);

	// keep looping until done
	while (!it.isDone()) {

		// get a handle to this node
		MObject obj = it.item();

		// write the node type found
		//cout << obj.apiTypeStr() << endl;

		MDagPath volumeShapePath;
		CHECK_MSTATUS(MDagPath::getAPathTo(obj, volumeShapePath));
		MFnDagNode volumeShapePathFn(volumeShapePath);
		MPlugArray volumeShapeOutputs, shadeNodeInputs;

		volumeShapePathFn.getConnections(volumeShapeOutputs);
		if (volumeShapeOutputs.length() > 0) {
			volumeShapeOutputs[0].connectedTo(shadeNodeInputs, false, true);
			if (shadeNodeInputs.length() > 0) {
				cout << "disconnecting "
						<< volumeShapeOutputs[0].name().asChar() << ", "
						<< shadeNodeInputs[0].name().asChar() << endl;
				dgMod.disconnect(volumeShapeOutputs[0], shadeNodeInputs[0]);
			}
		}

		MString cmd = "shadingNode -asShader VolumeFireNode";
		dgMod.commandToExecute(cmd);

		cmd =
				"sets -renderable true -noSurfaceShader true -empty -name VolumeFireNode1SG";
		dgMod.commandToExecute(cmd);

		cmd =
				"connectAttr -f VolumeFireNode1.outColor VolumeFireNode1SG.volumeShader";
		cout << cmd << endl;
		dgMod.commandToExecute(cmd);

		/*
		 * select -r sphere1 ;
		 * sets -e -forceElement VolumeFireNode1SG;
		 */
		/*MObject volumeFireNode = dgMod.createNode(VolumeFireNode::id);
		 assert(!volumeFireNode.isNull());
		 cout << "node created" << endl;
		 MFnDependencyNode volumeFireNodeFn(volumeFireNode);
		 MPlug volumeFireNodePlug = volumeFireNodeFn.findPlug(shadeNodeInputs[0].name().asChar());
		 dgMod.connect(volumeShapeOutputs[0], volumeFireNodePlug);*/

		it.next();
	}
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

MObject VolumeFireCmd::getInitianShadingGroup() {
	MSelectionList selection;
	// N.B. Ensure the selection is list empty beforehand since
	// getSelectionListByName() will append the matching objects
	selection.clear();

	CHECK_MSTATUS(
			MGlobal::getSelectionListByName("initialShadingGroup", selection));
	// Get the initial shading group

	MObject shadingGroupObj;
	CHECK_MSTATUS(selection.getDependNode(0, shadingGroupObj));

	return shadingGroupObj;
}
