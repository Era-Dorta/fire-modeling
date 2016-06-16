#include <maya/MFnPlugin.h>
#include "SaveFireDataCmd.h"
#include "LoadFireDataCmd.h"

MStatus initializePlugin(MObject obj) {
	MStatus stat;
	MFnPlugin plugin(obj);

	stat = plugin.registerCommand("saveFireData", SaveFireDataCmd::creator);
	if (!stat) {
		stat.perror("registerCommand failed");
	}

	stat = plugin.registerCommand("loadFireData", LoadFireDataCmd::creator);
	if (!stat) {
		stat.perror("registerCommand failed");
	}

	return stat;
}

MStatus uninitializePlugin(MObject obj) {
	MStatus stat;
	MFnPlugin plugin(obj);

	stat = plugin.deregisterCommand("saveFireData");
	if (!stat) {
		stat.perror("deregisterCommand failed");
	}

	stat = plugin.deregisterCommand("loadFireData");
	if (!stat) {
		stat.perror("deregisterCommand failed");
	}

	return stat;
}
