#ifndef CREATEVOXELDATASET_H_
#define CREATEVOXELDATASET_H_

#include "mex.h"

#include <openvdb/openvdb.h>

void array2voxelDataset(const mxArray valuesMx[], const mxArray coordsMx[],
		openvdb::FloatGrid::Ptr outGrid);

void voxelDataset2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[], mxArray *coordsMx[]);

void voxelDatasetValues2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[]);

#endif /* CREATEVOXELDATASET_H_ */
