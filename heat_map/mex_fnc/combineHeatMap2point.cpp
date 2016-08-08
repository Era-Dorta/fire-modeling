///*
// * To compile call
// * mex combineHeatMap2point.cpp createVoxelDataSet.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
// */

#include "mex.h"
#include <openvdb/openvdb.h>
#include <openvdb/tree/LeafManager.h>
#include <array>
#include <random>
#include <utility>

#define RUN_TESTS

// Shorter openvdb namespace
namespace vdb = openvdb;

#include "createVoxelDataSet.h"

/*
 __attribute__((constructor))
 void mex_load() {
 mexPrintf("combineHeatMap2point library loading\n");
 }

 __attribute__((destructor))
 void mex_unload() {
 mexPrintf("combineHeatMap2point library unloading\n");
 }
 */

/*
 * Custom checks for bounding boxes, in our case being in the limit of the
 * bounding box counts as being outside
 */
static inline bool isAnyEqual(const vdb::Coord& a, const vdb::Coord& b) {
	return (a[0] == b[0] || a[1] == b[1] || a[2] == b[2]);
}

static inline bool isOnEdge(const vdb::CoordBBox& bbox, const vdb::Coord& xyz) {
	return isAnyEqual(xyz, bbox.min()) || isAnyEqual(bbox.max(), xyz);
}

static inline float interpolate(float v0, float v1, float t) {
	return v0 * t + v1 * (1.0 - t);
}

static bool voxel_changed;

template<typename TreeType>
struct Combine2 {
	typedef vdb::tree::ValueAccessor<const TreeType> Accessor;
	Combine2(const TreeType&tree1, const TreeType&tree2, const vdb::Coord& min,
			const vdb::Coord& max, float interp_f, unsigned seed_val) :
			acc1(tree1), acc2(tree2), interp_r(interp_f) {

		// Set a minimum interpolation rate of 5%
		if (interp_r < 0.05) {
			interp_r = 0.05;
		}

#ifdef RUN_TESTS
		// Use a reproducible random number generator
		std::mt19937_64 generator;
		generator.seed(seed_val);
#else
		// Use a non-deterministic random number generator
		std::random_device generator;
#endif

		std::uniform_int_distribution<int> rand_idx;
		std::vector<std::vector<std::pair<int, int>>>all_idx;
		all_idx.resize(3);
		int total_bbox = 1;

#ifdef PRINT_INFO
		mexPrintf("Total size\n[%d, %d, %d]\n[%d, %d, %d]\n", min[0], min[1],
				min[2], max[0], max[1], max[2]);
#endif

		for (int i = 0; i <= 2; i++) {
			// Pick two random points in the ith dimension
			rand_idx = std::uniform_int_distribution<int>(min[i], max[i]);
			all_idx.at(i).push_back(
					std::make_pair(rand_idx(generator), rand_idx(generator)));

#ifdef PRINT_INFO
			mexPrintf("ori idx\n[%d, %d]\n", all_idx.at(i).at(0).first,
					all_idx.at(i).at(0).second);
#endif

			// If the first is larger, add the edges [0, p1], [p0, end]
			if (all_idx.at(i).at(0).first > all_idx.at(i).at(0).second) {
				// Add a second pair with right edge
				all_idx.at(i).push_back(
						std::make_pair(all_idx.at(i).at(0).first, max[i]));

				// Put left edge is first pair
				all_idx.at(i).at(0).first = min[i];

				// Every time we wrap with the edge the number of bounding
				// boxes needed to cover the space is doubled
				total_bbox *= 2;
			}
		}

		bbox.resize(total_bbox);

		/*
		 * Generate all the combination of bounding boxes, as we are using the
		 * modulus with the edges
		 */
		vdb::Coord b0, b1;
		int l = 0;
		for (unsigned i = 0; i < all_idx[0].size(); i++) {
			for (unsigned j = 0; j < all_idx[1].size(); j++) {
				for (unsigned k = 0; k < all_idx[2].size(); k++) {
					b0.x() = all_idx[0][i].first;
					b0.y() = all_idx[1][j].first;
					b0.z() = all_idx[2][k].first;

					b1.x() = all_idx[0][i].second;
					b1.y() = all_idx[1][j].second;
					b1.z() = all_idx[2][k].second;

					bbox.at(l).reset(b0, b1);

#ifdef PRINT_INFO
					mexPrintf("Box idx\n[%d, %d, %d]\n[%d, %d, %d]\n", b0[0],
							b0[1], b0[2], b1[0], b1[1], b1[2]);
#endif
					l++;
				}
			}
		}
	}

	template<typename LeafNodeType>
	void operator()(LeafNodeType &cLeaf, size_t) const {
		const LeafNodeType * c1Leaf = acc1.probeConstLeaf(cLeaf.origin());
		const LeafNodeType * c2Leaf = acc2.probeConstLeaf(cLeaf.origin());
		if (c1Leaf && c2Leaf) {

			typename LeafNodeType::ValueOnIter point = cLeaf.beginValueOn();
			for (; point; ++point) {
				const vdb::Coord coord = point.getCoord();
				/*
				 * If the voxel is inside any bounding box the assign the
				 * interpolated value from volume 2, otherwise place directly
				 * the value from volume 1
				 */
				const float point1 = c1Leaf->getValue(point.pos());
				const float point2 = c2Leaf->getValue(point.pos());

				bool value_set = false;
				for (const auto& box : bbox) {
					if (box.isInside(coord)) {
						if (!isOnEdge(box, coord)) {
							point.setValue(
									interpolate(point1, point2, interp_r));
						} else {
							// If the point is on the edge of the bounding box
							// add less of the second volume to have a smoother
							// transition
							point.setValue(
									interpolate(point1, point2,
											1 - interp_r * 0.5));
						}
						value_set = true;
						voxel_changed = true;
						break;
					}
				}
				if (!value_set) {
					point.setValue(point1);
				}
			}
		}
	}
private:
	Accessor acc1;
	Accessor acc2;
	std::vector<vdb::CoordBBox> bbox;
	float interp_r;
};

/*
 * The syntax is parameters is [v] = combineHeatMap8(xyz, v0, v1, min, max,
 *    interp, seed)
 * xyz -> Mx3 matrix of coordinates for each v data
 * v0, v1 -> Column vector of size M of volume values
 * min -> Row vector with the min [x, y, z] coordinates of xyz
 * max -> Row vector with the max [x, y, z] coordinates of xyz
 * interp -> interpolation factor for v0, for v1 is 1 - interp
 * seed -> seed for the internal random number generator
 * v -> output values
 */
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	vdb::initialize();

	if (nrhs > 7) {
		mexErrMsgTxt("Too many input arguments.");
	} else if (nrhs < 7) {
		mexErrMsgTxt("Not enough input arguments.");
	}

	if (nlhs > 1) {
		mexErrMsgTxt("Too many output arguments.");
	}

	// Rename all the input and output variables
	const mxArray *xyz = prhs[0], *v0 = prhs[1], *v1 = prhs[2], *boxmin =
			prhs[3], *boxmax = prhs[4], *interp = prhs[5], *seedp = prhs[6];
	mxArray **vp = plhs;

	if (mxGetM(boxmin) != 1 || mxGetM(boxmax) != 1 || mxGetN(boxmin) != 3
			|| mxGetN(boxmax) != 3) {
		mexErrMsgTxt("Min and max must be 1x3 vectors.");
	}

	if (mxGetM(interp) != 1 || mxGetN(interp) != 1) {
		mexErrMsgTxt("interp must be 1x1 vector.");
	}

	if (mxGetM(seedp) != 1 || mxGetN(seedp) != 1) {
		mexErrMsgTxt("seedp must be 1x1 vector.");
	}

	// Copy the input data in two datasets
	vdb::FloatGrid::Ptr grid1 = vdb::FloatGrid::create();
	array2voxelDataset(v0, xyz, grid1);

	vdb::FloatGrid::Ptr grid2 = vdb::FloatGrid::create();
	array2voxelDataset(v1, xyz, grid2);

	// Get the min and max range in Coord variables
	double *datap = mxGetPr(boxmin);
	const vdb::Coord min(datap[0], datap[1], datap[2]);

	datap = mxGetPr(boxmax);
	const vdb::Coord max(datap[0], datap[1], datap[2]);

	datap = mxGetPr(interp);
	const float interp_f = datap[0];

	if (interp_f < 0 || interp_f > 1) {
		mexErrMsgTxt("interp must be in the range [0..1].");
	}

	datap = mxGetPr(seedp);
	unsigned seed_f = static_cast<unsigned>(datap[0]);

	// Copying the whole grid is faster than inserting the elements
	vdb::FloatGrid::Ptr resgrid = grid1->deepCopy();

	vdb::tree::LeafManager<vdb::FloatTree> leafNodes(resgrid->tree());

	// Do the combination, if no voxel value was changed using the second grid
	// then try again with another set of random indices
	voxel_changed = false;
	while (!voxel_changed) {
		leafNodes.foreach(
				Combine2<vdb::FloatTree>(grid1->tree(), grid2->tree(), min, max,
						interp_f, seed_f++));
	}
	// Return the result, the values in v are in the same order as the input
	voxelDatasetValues2arrayOrdered(resgrid, xyz, vp);
}
