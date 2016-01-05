#include "createVoxelDataSet.h"
#include "matrix.h"

void array2voxelDataset(const mxArray valuesMx[], const mxArray coordsMx[],
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

	for (int i = 0; i < valSize0; i++) {
		// Matlab stores the data in column order, so to access the (i,j)
		// component we need to compute i + j * M
		openvdb::Coord c(coord[i], coord[i + valSize0],
				coord[i + 2 * valSize0]);
		accessor.setValue(c, values[i]);
	}
}

void voxelDataset2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[], mxArray *coordsMx[]) {

	const int size = inGrid->activeVoxelCount();

	valuesMx[0] = mxCreateDoubleMatrix(size, 1, mxREAL);
	coordsMx[0] = mxCreateDoubleMatrix(size, 3, mxREAL);

	double *values = mxGetPr(valuesMx[0]);
	double *coord = mxGetPr(coordsMx[0]);

	int i = 0;
	for (openvdb::FloatGrid::ValueOnCIter iter = inGrid->cbeginValueOn();
			iter.test(); ++iter) {
		const openvdb::Coord c = iter.getCoord();
		values[i] = *iter;

		// Matlab stores the data in column order, so to access the (i,j)
		// component we need to compute i + j * M
		coord[i] = c.x();
		coord[i + size] = c.y();
		coord[i + size * 2] = c.z();

		i++;
	}
}

void voxelDatasetValues2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[]) {
	const int size = inGrid->activeVoxelCount();

	valuesMx[0] = mxCreateDoubleMatrix(size, 1, mxREAL);

	double *values = mxGetPr(valuesMx[0]);

	int i = 0;
	for (openvdb::FloatGrid::ValueOnCIter iter = inGrid->cbeginValueOn();
			iter.test(); ++iter) {
		values[i] = *iter;
		i++;
	}
}

void voxelDatasetValues2arrayOrdered(openvdb::FloatGrid::ConstPtr inGrid,
		const mxArray coordsMx[], mxArray *valuesMx[]) {
	const int size = inGrid->activeVoxelCount();
	openvdb::FloatGrid::ConstAccessor accessor = inGrid->getAccessor();

	const int coordSize0 = mxGetM(coordsMx);
	const int coordSize1 = mxGetN(coordsMx);

	double *coord = mxGetPr(coordsMx);

	if (coordSize1 != 3) {
		mexErrMsgTxt("Indices must be threedimensional.");
	}

	if (coordSize0 != size) {
		mexErrMsgTxt("Values and indices must be the same row size.");
	}

	valuesMx[0] = mxCreateDoubleMatrix(size, 1, mxREAL);

	double *values = mxGetPr(valuesMx[0]);

	for (int i = 0; i < size; i++) {
		// Matlab stores the data in column order, so to access the (i,j)
		// component we need to compute i + j * M
		openvdb::Coord c(coord[i], coord[i + coordSize0],
				coord[i + 2 * coordSize0]);
		values[i] = accessor.getValue(c);
	}
}
