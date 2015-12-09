#ifndef CREATEVOXELDATASET_H_
#define CREATEVOXELDATASET_H_

#include "mex.h"

#include <openvdb/openvdb.h>

bool createVoxelDataSet(const mxArray values[], const mxArray coords[],
		openvdb::FloatGrid::Ptr outGrid);

#endif /* CREATEVOXELDATASET_H_ */
