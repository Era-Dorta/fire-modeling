/*
 * To compile call 
 * mex class_interface_mex.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/
 */
#include "mex.h"
#include "class_handle.h"
#include <openvdb/openvdb.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	
    openvdb::initialize();
    
    // Get the command string
    char cmd[64];
	if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd)))
		mexErrMsgTxt("First input should be a command string less than 64 characters long.");
        
    // New
    if (!strcmp("new", cmd)) {
        // Check parameters
        if (nlhs != 1)
            mexErrMsgTxt("New: One output expected.");
        // Return a handle to a new C++ instance
        openvdb::FloatGrid::Ptr aux_grid = openvdb::FloatGrid::create();
        plhs[0] = convertPtr2Mat<openvdb::FloatGrid>(new openvdb::FloatGrid);
        return;
    }
    
    // Check there is a second input, which should be the class instance handle
    if (nrhs < 2)
		mexErrMsgTxt("Second input should be a class instance handle.");
    
    // Delete
    if (!strcmp("delete", cmd)) {
        // Destroy the C++ object
        destroyObject<openvdb::FloatGrid>(prhs[1]);
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    }
    
    // Get the class instance pointer from the second input
    openvdb::FloatGrid *grid_instance = convertMat2Ptr<openvdb::FloatGrid>(prhs[1]);
    
    // Call the various class methods
    // Train    
    if (!strcmp("train", cmd)) {
        // Check parameters
        if (nlhs < 0 || nrhs < 2)
            mexErrMsgTxt("Train: Unexpected arguments.");
        // Call the method
        //grid_instance->train();
        return;
    }
    // Test    
    if (!strcmp("test", cmd)) {
        // Check parameters
        if (nlhs < 0 || nrhs < 2)
            mexErrMsgTxt("Test: Unexpected arguments.");
        // Call the method
        //grid_instance->test();
        return;
    }
    
    // Got here, so command not recognized
    mexErrMsgTxt("Command not recognized.");
}