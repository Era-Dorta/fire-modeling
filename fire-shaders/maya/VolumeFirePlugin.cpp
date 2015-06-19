#include "VolumeFireCmd.h"
#include <maya/MFnPlugin.h>
#include "FireShaderNode.h"

MStatus initializePlugin(MObject obj) {
	const MString UserClassify("shader/volume");

	MFnPlugin plugin(obj, PLUGIN_COMPANY, "4.5", "Any");
	CHECK_MSTATUS(
			plugin.registerNode("Fire Shader", FireShaderNode::id,
					FireShaderNode::creator, FireShaderNode::initialize,
					MPxNode::kDependNode, &UserClassify));

	CHECK_MSTATUS(
			plugin.registerCommand("VolumeFireCmd", VolumeFireCmd::creator));
	return MS::kSuccess;
}

MStatus uninitializePlugin(MObject obj) {
	//plugin.deregisterCommand("VolumeFireCmd");

	MFnPlugin plugin(obj);
	CHECK_MSTATUS(plugin.deregisterNode(FireShaderNode::id));
	CHECK_MSTATUS(plugin.deregisterCommand("VolumeFireCmd"));
	return MS::kSuccess;
}
