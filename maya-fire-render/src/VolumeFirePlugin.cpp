#include "VolumeFireCmd.h"
#include "VolumeFireNode.h"

#include <maya/MFnPlugin.h>

MStatus initializePlugin(MObject obj) {
	const MString UserClassify("shader/volume");

	MFnPlugin plugin(obj, PLUGIN_COMPANY, "4.5", "Any");
	CHECK_MSTATUS(
			plugin.registerNode("VolumeFireNode", VolumeFireNode::id,
					VolumeFireNode::creator, VolumeFireNode::initialize,
					MPxNode::kDependNode, &UserClassify));

	CHECK_MSTATUS(
			plugin.registerCommand("VolumeFireCmd", VolumeFireCmd::creator));
	return MS::kSuccess;
}

MStatus uninitializePlugin(MObject obj) {
	//plugin.deregisterCommand("VolumeFireCmd");

	MFnPlugin plugin(obj);
	CHECK_MSTATUS(plugin.deregisterNode(VolumeFireNode::id));
	CHECK_MSTATUS(plugin.deregisterCommand("VolumeFireCmd"));
	return MS::kSuccess;
}
