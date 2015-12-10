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
	} else if (nrhs < 4) {
		mexErrMsgTxt("Not enough input arguments.");
	}

	if (nlhs > 2) {
		mexErrMsgTxt("Too many output arguments.");
	} else if (nlhs < 2) {
		mexErrMsgTxt("Not enough output arguments.");
	}

	// Copy the input data in two datasets
	openvdb::FloatGrid::Ptr grid1 = openvdb::FloatGrid::create();
	array2voxelDataset(prhs[0], prhs[1], grid1);

	openvdb::FloatGrid::Ptr grid2 = openvdb::FloatGrid::create();
	array2voxelDataset(prhs[2], prhs[3], grid2);

	//TODO Mix the volumetric data

	// Return the result
	voxelDataset2array(grid1, plhs, plhs + 1);
}
