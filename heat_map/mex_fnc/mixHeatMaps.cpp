/*
 * To compile call 
 * mex mixHeatMaps.cpp createVoxelDataSet.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
 */

#include "mex.h"
#include <openvdb/openvdb.h>
#include <openvdb/tree/LeafManager.h>
#include <array>

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

/*
 * Custom checks for bounding boxes, in our case being in the limit of the
 * bounding box counts as being outside
 */
static inline bool lessEThan(const vdb::Coord& a, const vdb::Coord& b) {
	return (a[0] <= b[0] || a[1] <= b[1] || a[2] <= b[2]);
}

static inline bool isInsideR(const vdb::CoordBBox& bbox,
		const vdb::Coord& xyz) {
	return !(lessEThan(xyz, bbox.min()) || lessEThan(bbox.max(), xyz));
}

template<typename TreeType>
struct Combine8 {
	typedef vdb::tree::ValueAccessor<const TreeType> Accessor;
	Combine8(const TreeType&tree1, const TreeType&tree2, const vdb::Coord& min,
			const vdb::Coord& max) :
			acc1(tree1), acc2(tree2) {
		// Get the middle point between min and max
		vdb::Coord mid = min + max;
		mid.x() *= 0.5;
		mid.y() *= 0.5;
		mid.z() *= 0.5;

		/*
		 * Rename the variables to make the bounding box indices more clear,
		 * extending the borders by one unit means that there won't be
		 * interpolation for the outer edges
		 */
		int x0 = min.x() - 1;
		int x1 = mid.x();
		int x2 = max.x() + 1;

		int y0 = min.y() - 1;
		int y1 = mid.y();
		int y2 = max.y() + 1;

		int z0 = min.z() - 1;
		int z1 = mid.z();
		int z2 = max.z() + 1;

		// Built 8 bounding boxes from min to max as big as mid point
		/*
		 *  For y = 0	  For y = 1
		 *
		 *   ^
		 * z | 2  3			6  7
		 *   | 0  1			4  5
		 *    --->
		 *     x
		 *
		 * {0, 3, 5, 6} -> First grid, {1, 2, 4, 7} -> Second grid,
		 */
		bboxes1.at(0).reset(vdb::Coord(x0, y0, z0), vdb::Coord(x1, y1, z1));
		bboxes2.at(0).reset(vdb::Coord(x1, y0, z0), vdb::Coord(x2, y1, z1));
		bboxes2.at(1).reset(vdb::Coord(x0, y0, z1), vdb::Coord(x1, y1, z2));
		bboxes1.at(1).reset(vdb::Coord(x1, y0, z1), vdb::Coord(x2, y1, z2));
		bboxes2.at(2).reset(vdb::Coord(x0, y1, z0), vdb::Coord(x1, y2, z1));
		bboxes1.at(2).reset(vdb::Coord(x1, y1, z0), vdb::Coord(x2, y2, z1));
		bboxes1.at(3).reset(vdb::Coord(x0, y1, z1), vdb::Coord(x1, y2, z2));
		bboxes2.at(3).reset(vdb::Coord(x1, y1, z1), vdb::Coord(x2, y2, z2));
	}

	template<typename LeafNodeType>
	void operator()(LeafNodeType &cLeaf, size_t) const {
		const LeafNodeType * c1Leaf = acc1.probeConstLeaf(cLeaf.origin());
		const LeafNodeType * c2Leaf = acc2.probeConstLeaf(cLeaf.origin());
		if (c1Leaf && c2Leaf) {
			typename LeafNodeType::ValueOnIter iter = cLeaf.beginValueOn();
			bool var1 = true;
			for (; iter; ++iter) {
				const vdb::Coord coord = iter.getCoord();
				bool value_set = false;
				/*
				 * If the voxel is inside of any of the bounding boxes assing
				 * that value to the new voxel and continue to the next one
				 */
				for (auto b1ite = bboxes1.begin(); b1ite != bboxes1.end();
						++b1ite) {
					if (isInsideR(*b1ite, coord)) {
						iter.setValue(c1Leaf->getValue(iter.pos()));
						value_set = true;
						break;
					}
				}
				if (value_set) {
					continue;
				}

				for (auto b2ite = bboxes2.begin(); b2ite != bboxes2.end();
						++b2ite) {
					if (isInsideR(*b2ite, coord)) {
						iter.setValue(c2Leaf->getValue(iter.pos()));
						value_set = true;
						break;
					}
				}
				if (value_set) {
					continue;
				}
				/*
				 * If it is not inside any bounding box it means that it is in
				 * the boundary, in that case assign the mean of both values
				 */
				iter.setValue(
						(c1Leaf->getValue(iter.pos())
								+ c2Leaf->getValue(iter.pos())) * 0.5);
			}
		}
	}
private:
	Accessor acc1;
	Accessor acc2;
	std::array<vdb::CoordBBox, 4> bboxes1;
	std::array<vdb::CoordBBox, 4> bboxes2;
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
