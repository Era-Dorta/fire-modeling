/*
 * FireControlNode.h
 *
 *  Created on: 4 Sep 2015
 *      Author: gdp24
 */

#ifndef SRC_FIRECONTROLNODE_H_
#define SRC_FIRECONTROLNODE_H_

#include <maya/MPxNode.h>
#include <maya/MFnNumericAttribute.h>
#include <maya/MTypeId.h>

class FireControlNode : public MPxNode
{
public:
	virtual MStatus compute(const MPlug& plug, MDataBlock& data) override;

	static  void *creator();
	static  MStatus initialize();

	static const MTypeId id;

public:
	// Inputs
	static MObject density_file;
	static MObject density_scale;
	static MObject density_offset;
	static MObject density_read_mode;
	static MObject temperature_file;
	static MObject temperature_scale;
	static MObject temperature_offset;
	static MObject temperature_read_mode;
	static MObject interpolation_mode;
	static MObject fuel_type;
	static MObject visual_adaptation_factor;
	static MObject intensity;
	static MObject shadow_threshold;
	static MObject decay;
	static MObject march_increment;
	static MObject cast_shadows;

	// Outputs
	static MObject density_file_out;
	static MObject density_scale_out;
	static MObject density_offset_out;
	static MObject density_read_mode_out;
	static MObject temperature_file_out;
	static MObject temperature_scale_out;
	static MObject temperature_offset_out;
	static MObject temperature_read_mode_out;
	static MObject interpolation_mode_out;
	static MObject fuel_type_out;
	static MObject visual_adaptation_factor_out;
	static MObject intensity_out;
	static MObject shadow_threshold_out;
	static MObject decay_out;
	static MObject march_increment_out;
	static MObject cast_shadows_out;

private:
	static MObject density_file_first;
	static MObject temperature_file_first;
};

#endif /* SRC_FIRECONTROLNODE_H_ */
