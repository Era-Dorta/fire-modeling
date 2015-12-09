/*
 * To compile call 
 * mex mixHeatMaps.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
 */

#include "mex.h"
#include <openvdb/openvdb.h>

#include "createVoxelDataSet.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	openvdb::initialize();

	mexPrintf("Calling mixHeatMaps\n");

	openvdb::FloatGrid::Ptr grid1 = openvdb::FloatGrid::create();
	createVoxelDataSet(prhs[0], prhs[1], grid1);
}
