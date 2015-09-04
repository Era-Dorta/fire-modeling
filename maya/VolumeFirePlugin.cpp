#include "FireControlNode.h"
#include <maya/MFnPlugin.h>

MStatus initializePlugin(MObject obj) {
	MFnPlugin plugin(obj, PLUGIN_COMPANY, "4.5", "Any");

	CHECK_MSTATUS(
			plugin.registerNode("FireControlNode", FireControlNode::id,
					FireControlNode::creator, FireControlNode::initialize,
					MPxNode::kDependNode));
	return MS::kSuccess;
}

MStatus uninitializePlugin(MObject obj) {
	MFnPlugin plugin(obj);
	CHECK_MSTATUS(plugin.deregisterNode(FireControlNode::id));
	return MS::kSuccess;
}
