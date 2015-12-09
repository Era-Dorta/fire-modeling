#include "createVoxelDataSet.h"

bool createVoxelDataSet(const mxArray valuesMx[], const mxArray coordsMx[],
		openvdb::FloatGrid::Ptr outGrid) {

	outGrid->clear();
	openvdb::FloatGrid::Accessor accessor = outGrid->getAccessor();

	const int valSize0 = mxGetM(valuesMx);
	const int valSize1 = mxGetN(valuesMx);

	mexPrintf("Values size %d ,%d\n", valSize0, valSize1);

	double *values = mxGetPr(valuesMx);

	mexPrintf("Values %f ,%f, %f\n", values[0], values[1], values[2]);

	const int coordSize0 = mxGetM(coordsMx);
	const int coordSize1 = mxGetN(coordsMx);

	double *coord = mxGetPr(valuesMx);

	mexPrintf("coord size %d ,%d\n", coordSize0, coordSize1);

	mexPrintf("coord %f ,%f, %f, %f\n", coord[0], coord[1], coord[2], coord[3]);

	int j = 0;
	for (int i = 0; i < valSize0 * valSize1; i++) {
		openvdb::Coord c = openvdb::Coord(coord[i * 3], coord[i * 3 + 1],
				coord[i * 3 + 2]);
		accessor.setValue(c, values[i]);
	}

	return true;
}
