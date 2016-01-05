#ifndef CREATEVOXELDATASET_H_
#define CREATEVOXELDATASET_H_

#include "mex.h"

#include <openvdb/openvdb.h>

/*
 * Store in outGrid the voxel dataset defined by the values in valuesMx in
 * the coordinates coordsMx
 */
void array2voxelDataset(const mxArray valuesMx[], const mxArray coordsMx[],
		openvdb::FloatGrid::Ptr outGrid);

/*
 * Store in valuesMx and coordsMx the voxel dataset grid inGrid
 */
void voxelDataset2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[], mxArray *coordsMx[]);

/*
 * Store in valuesMx the voxel dataset values of grid inGrid
 */
void voxelDatasetValues2array(openvdb::FloatGrid::ConstPtr inGrid,
		mxArray *valuesMx[]);

/*
 * Store in valuesMx the voxel dataset values defined by the coordinates
 * coordsMx in inGrid
 */
void voxelDatasetValues2arrayOrdered(openvdb::FloatGrid::ConstPtr inGrid,
		const mxArray coordsMx[], mxArray *valuesMx[]);

#endif /* CREATEVOXELDATASET_H_ */
