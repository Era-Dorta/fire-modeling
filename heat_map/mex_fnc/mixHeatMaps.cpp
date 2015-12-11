/*
 * To compile call 
 * mex mixHeatMaps.cpp createVoxelDataSet.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
 */

#include "mex.h"
#include <openvdb/openvdb.h>
#include <openvdb/tree/LeafManager.h>

// Shorten openvdb namespace
namespace vdb = openvdb;

#include "createVoxelDataSet.h"

// Remove comments to check how the mex file is being loaded and unloaded in Matlab
/*
 __attribute__((constructor))
 void mex_load() {
 mexPrintf("mixHeatmaps library loading\n");
 }

 __attribute__((destructor))
 void mex_unload() {
 mexPrintf("mixHeatmaps library unloading\n");
 }
*/

template<typename TreeType>
struct Combine8 {
	typedef vdb::tree::ValueAccessor<const TreeType> Accessor;
	Combine8(const TreeType&tree1, const TreeType&tree2, const vdb::Coord& min,
			const vdb::Coord& max) :
			acc1(tree1), acc2(tree2), _min(min), _max(max) {
	}

	template<typename LeafNodeType>
	void operator()(LeafNodeType &cLeaf, size_t) const {
		const LeafNodeType * c1Leaf = acc1.probeConstLeaf(cLeaf.origin());
		const LeafNodeType * c2Leaf = acc2.probeConstLeaf(cLeaf.origin());
		if (c1Leaf && c2Leaf) {
			typename LeafNodeType::ValueOnIter iter = cLeaf.beginValueOn();
			for (; iter; ++iter) {
				iter.setValue(
						c1Leaf->getValue(iter.pos())
								+ c2Leaf->getValue(iter.pos()));
			}
		}
	}
private:
	Accessor acc1;
	Accessor acc2;
	const vdb::Coord _min;
	const vdb::Coord _max;
};

/*
 * The syntax is parameters is [v , xyz] = mixHeatMaps(xyz, v0, v1, min, max)
 * xzy -> Mx3 matrix of coordinates for each v data
 * v0, v1 -> Column vector of size M of volume values
 * min -> Row vector with the min [x, y, z] coordinates of xyz
 * max -> Row vector with the max [x, y, z] coordinates of xyz
 * v -> output values
 * xyz -> output coordinates
 */
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	vdb::initialize();

	if (nrhs > 5) {
		mexErrMsgTxt("Too many input arguments.");
	} else if (nrhs < 5) {
		mexErrMsgTxt("Not enough input arguments.");
	}

	if (nlhs > 2) {
		mexErrMsgTxt("Too many output arguments.");
	} else if (nlhs < 2) {
		mexErrMsgTxt("Not enough output arguments.");
	}

	if (mxGetM(prhs[3]) != 1 || mxGetM(prhs[4]) != 1 || mxGetN(prhs[3]) != 3
			|| mxGetN(prhs[4]) != 3) {
		mexErrMsgTxt("Min and max must be 1x3 vectors.");
	}

	// Copy the input data in two datasets
	vdb::FloatGrid::Ptr grid1 = vdb::FloatGrid::create();
	array2voxelDataset(prhs[1], prhs[0], grid1);

	vdb::FloatGrid::Ptr grid2 = vdb::FloatGrid::create();
	array2voxelDataset(prhs[2], prhs[0], grid2);

	// Get the min and max range in Coord variables
	double *datap = mxGetPr(prhs[3]);
	const vdb::Coord min(datap[0], datap[1], datap[2]);

	datap = mxGetPr(prhs[4]);
	const vdb::Coord max(datap[0], datap[1], datap[2]);

	// Copying the whole grid is faster than inserting the elements
	vdb::FloatGrid::Ptr resgrid = grid1->deepCopy();

	vdb::tree::LeafManager<vdb::FloatTree> leafNodes(resgrid->tree());
	leafNodes.foreach(
			Combine8<vdb::FloatTree>(grid1->tree(), grid2->tree(), min, max));

	// Return the result
	voxelDataset2array(resgrid, plhs, plhs + 1);
}
