#include "VolumeFireCmd.h"
#include <maya/MFnPlugin.h>

MStatus initializePlugin(MObject obj) {
	MFnPlugin plugin(obj, PLUGIN_COMPANY, "4.5", "Any");

	CHECK_MSTATUS(
			plugin.registerCommand("VolumeFireCmd", VolumeFireCmd::creator));
	return MS::kSuccess;
}

MStatus uninitializePlugin(MObject obj) {
	MFnPlugin plugin(obj);
	CHECK_MSTATUS(plugin.deregisterCommand("VolumeFireCmd"));
	return MS::kSuccess;
}
