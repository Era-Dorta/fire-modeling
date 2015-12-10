/*
 * To compile call 
 * mex mixHeatMaps.cpp createVoxelDataSet.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
 */

#include "mex.h"
#include <openvdb/openvdb.h>

#include "createVoxelDataSet.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	openvdb::initialize();

	if (nrhs > 4) {
		mexErrMsgTxt("Too many input arguments.");
	}

	if (nrhs < 4) {
		mexErrMsgTxt("Not enough input arguments.");
	}

	openvdb::FloatGrid::Ptr grid1 = openvdb::FloatGrid::create();
	createVoxelDataSet(prhs[0], prhs[1], grid1);

	openvdb::FloatGrid::Ptr grid2 = openvdb::FloatGrid::create();
	createVoxelDataSet(prhs[2], prhs[3], grid2);
}
