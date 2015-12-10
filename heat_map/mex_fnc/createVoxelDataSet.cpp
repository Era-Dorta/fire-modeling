#include "createVoxelDataSet.h"

bool createVoxelDataSet(const mxArray valuesMx[], const mxArray coordsMx[],
		openvdb::FloatGrid::Ptr outGrid) {

	outGrid->clear();
	openvdb::FloatGrid::Accessor accessor = outGrid->getAccessor();

	const int valSize0 = mxGetM(valuesMx);
	const int valSize1 = mxGetN(valuesMx);

	double *values = mxGetPr(valuesMx);

	const int coordSize0 = mxGetM(coordsMx);
	const int coordSize1 = mxGetN(coordsMx);

	double *coord = mxGetPr(coordsMx);

	if (coordSize1 != 3) {
		mexErrMsgTxt("Indices must be threedimensional.");
	}

	if (valSize1 != 1) {
		mexErrMsgTxt("Values must be a column vector.");
	}

	if (coordSize0 != valSize0) {
		mexErrMsgTxt("Values and indices must be the same row size.");
	}

	for (int i = 0; i < valSize0 * valSize1; i++) {
		// Matlab stores the data in column order, so to access the first row is
		// i + j * M
		openvdb::Coord c = openvdb::Coord(coord[i], coord[i + valSize0],
				coord[i + 2 * valSize0]);
		accessor.setValue(c, values[i]);
	}

	return true;
}
