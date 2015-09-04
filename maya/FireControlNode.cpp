/*
 * FireControlNode.cpp
 *
 *  Created on: 4 Sep 2015
 *      Author: gdp24
 */

#include "FireControlNode.h"

#include <maya/MPlug.h>
#include <maya/MDataBlock.h>
#include <maya/MDataHandle.h>
#include <maya/MGlobal.h>
#include <maya/MFnTypedAttribute.h>
#include <maya/MFnNurbsSurfaceData.h>
#include <maya/MFnNurbsSurface.h>
#include <maya/MPointArray.h>
#include <maya/MAngle.h>
#include <maya/MItGeometry.h>
#include <maya/MMatrix.h>
#include <maya/MFnStringData.h>
#include <assert.h>
#include <float.h>

const MTypeId FireControlNode::id(0x00344);

MObject FireControlNode::density_file;
MObject FireControlNode::density_file_first;
MObject FireControlNode::density_scale;
MObject FireControlNode::density_offset;
MObject FireControlNode::density_read_mode;
MObject FireControlNode::temperature_file;
MObject FireControlNode::temperature_file_first;
MObject FireControlNode::temperature_scale;
MObject FireControlNode::temperature_offset;
MObject FireControlNode::temperature_read_mode;
MObject FireControlNode::interpolation_mode;
MObject FireControlNode::fuel_type;
MObject FireControlNode::visual_adaptation_factor;
MObject FireControlNode::intensity;
MObject FireControlNode::shadow_threshold;
MObject FireControlNode::decay;

// Outputs
MObject FireControlNode::density_file_out;
MObject FireControlNode::density_scale_out;
MObject FireControlNode::density_offset_out;
MObject FireControlNode::density_read_mode_out;
MObject FireControlNode::temperature_file_out;
MObject FireControlNode::temperature_scale_out;
MObject FireControlNode::temperature_offset_out;
MObject FireControlNode::temperature_read_mode_out;
MObject FireControlNode::interpolation_mode_out;
MObject FireControlNode::fuel_type_out;
MObject FireControlNode::visual_adaptation_factor_out;
MObject FireControlNode::intensity_out;
MObject FireControlNode::shadow_threshold_out;
MObject FireControlNode::decay_out;

MStatus FireControlNode::compute(const MPlug& plug, MDataBlock& data) {
	MStatus stat;

	// If asked for the outputSurface then compute it
	if (plug == density_file_out) {
		MDataHandle input_handle = data.inputValue(density_file);
		MDataHandle output_handle = data.outputValue(density_file_out);

		const MString& value = input_handle.asString();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_scale_out) {
		MDataHandle input_handle = data.inputValue(density_scale);
		MDataHandle output_handle = data.outputValue(density_scale_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_offset_out) {
		MDataHandle input_handle = data.inputValue(density_offset);
		MDataHandle output_handle = data.outputValue(density_offset_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == density_read_mode_out) {
		MDataHandle input_handle = data.inputValue(density_read_mode);
		MDataHandle output_handle = data.outputValue(density_read_mode_out);

		const int& value = input_handle.asInt();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_file_out) {
		MDataHandle input_handle = data.inputValue(temperature_file);
		MDataHandle output_handle = data.outputValue(temperature_file_out);

		const MString& value = input_handle.asString();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_scale_out) {
		MDataHandle input_handle = data.inputValue(temperature_scale);
		MDataHandle output_handle = data.outputValue(temperature_scale_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_offset_out) {
		MDataHandle input_handle = data.inputValue(temperature_offset);
		MDataHandle output_handle = data.outputValue(temperature_offset_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == temperature_read_mode_out) {
		MDataHandle input_handle = data.inputValue(temperature_read_mode);
		MDataHandle output_handle = data.outputValue(temperature_read_mode_out);

		const int& value = input_handle.asInt();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == interpolation_mode_out) {
		MDataHandle input_handle = data.inputValue(interpolation_mode);
		MDataHandle output_handle = data.outputValue(interpolation_mode_out);

		const int& value = input_handle.asInt();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == fuel_type_out) {
		MDataHandle input_handle = data.inputValue(fuel_type);
		MDataHandle output_handle = data.outputValue(fuel_type_out);

		const int& value = input_handle.asInt();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == visual_adaptation_factor_out) {
		MDataHandle input_handle = data.inputValue(visual_adaptation_factor);
		MDataHandle output_handle = data.outputValue(
				visual_adaptation_factor_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == intensity_out) {
		MDataHandle input_handle = data.inputValue(intensity);
		MDataHandle output_handle = data.outputValue(intensity_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == shadow_threshold_out) {
		MDataHandle input_handle = data.inputValue(shadow_threshold);
		MDataHandle output_handle = data.outputValue(shadow_threshold_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}
	if (plug == decay_out) {
		MDataHandle input_handle = data.inputValue(decay);
		MDataHandle output_handle = data.outputValue(decay_out);

		const float& value = input_handle.asFloat();
		output_handle.set(value);

		data.setClean(plug);
		return MS::kSuccess;
	}

	return MS::kUnknownParameter;
}

void *FireControlNode::creator() {
	return new FireControlNode();
}

MStatus FireControlNode::initialize() {
	MFnNumericAttribute nAttr;
	MFnTypedAttribute tAttr;
	MFnStringData stringFn;

	density_file = tAttr.create("density_file", "df", MFnData::kString,
			stringFn.create("Density file path"));
	density_scale = nAttr.create("density_scale", "ds", MFnNumericData::kFloat,
			1e12f);
	density_offset = nAttr.create("density_offset", "do",
			MFnNumericData::kFloat, 0.0f);
	density_read_mode = nAttr.create("density_read_mode", "drm",
			MFnNumericData::kInt, 1);
	temperature_file = tAttr.create("temperature_file", "tf", MFnData::kString,
			stringFn.create("Temperature file path"));
	temperature_scale = nAttr.create("temperature_scale", "ts",
			MFnNumericData::kFloat, 500.0f);
	temperature_offset = nAttr.create("temperature_offset", "to",
			MFnNumericData::kFloat, 0.0f);
	temperature_read_mode = nAttr.create("temperature_read_mode", "trm",
			MFnNumericData::kInt, 2);
	interpolation_mode = nAttr.create("interpolation_mode", "im",
			MFnNumericData::kInt, 0);
	fuel_type = nAttr.create("fuel_type", "ft", MFnNumericData::kInt, 1);
	visual_adaptation_factor = nAttr.create("visual_adaptation_factor", "vaf",
			MFnNumericData::kFloat, 0);
	intensity = nAttr.create("intensity", "int", MFnNumericData::kFloat, 1.0f);
	shadow_threshold = nAttr.create("shadow_threshold", "st",
			MFnNumericData::kFloat, 0.0f);
	decay = nAttr.create("decay", "d", MFnNumericData::kFloat, 2.0f);

	// Outputs
	density_file_out = tAttr.create("density_file_out", "dfo",
			MFnData::kString);
	tAttr.setHidden(true);

	density_scale_out = nAttr.create("density_scale_out", "dso",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	density_offset_out = nAttr.create("density_offset_out", "doo",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	density_read_mode_out = nAttr.create("density_read_mode_out", "drmo",
			MFnNumericData::kInt);
	nAttr.setHidden(true);

	temperature_file_out = tAttr.create("temperature_file_out", "tfo",
			MFnData::kString);
	tAttr.setHidden(true);

	temperature_scale_out = nAttr.create("temperature_scale_out", "tso",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	temperature_offset_out = nAttr.create("temperature_offset_out", "too",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	temperature_read_mode_out = nAttr.create("temperature_read_mode_out",
			"trmo", MFnNumericData::kInt);
	nAttr.setHidden(true);

	interpolation_mode_out = nAttr.create("interpolation_mode_out", "imo",
			MFnNumericData::kInt);
	nAttr.setHidden(true);

	fuel_type_out = nAttr.create("fuel_type_out", "fto", MFnNumericData::kInt);
	nAttr.setHidden(true);

	visual_adaptation_factor_out = nAttr.create("visual_adaptation_factor_out",
			"vafo", MFnNumericData::kFloat);
	nAttr.setHidden(true);

	intensity_out = nAttr.create("intensity_out", "into",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	shadow_threshold_out = nAttr.create("shadow_threshold_out", "sto",
			MFnNumericData::kFloat);
	nAttr.setHidden(true);

	decay_out = nAttr.create("decay_out", "do", MFnNumericData::kFloat);
	nAttr.setHidden(true);


	addAttribute(density_file);
	addAttribute(density_scale);
	addAttribute(density_offset);
	addAttribute(density_read_mode);
	addAttribute(temperature_file);
	addAttribute(temperature_scale);
	addAttribute(temperature_offset);
	addAttribute(temperature_read_mode);
	addAttribute(interpolation_mode);
	addAttribute(fuel_type);
	addAttribute(visual_adaptation_factor);
	addAttribute(intensity);
	addAttribute(shadow_threshold);
	addAttribute(decay);

	// Outputs
	addAttribute(density_file_out);
	addAttribute(density_scale_out);
	addAttribute(density_offset_out);
	addAttribute(density_read_mode_out);
	addAttribute(temperature_file_out);
	addAttribute(temperature_scale_out);
	addAttribute(temperature_offset_out);
	addAttribute(temperature_read_mode_out);
	addAttribute(interpolation_mode_out);
	addAttribute(fuel_type_out);
	addAttribute(visual_adaptation_factor_out);
	addAttribute(intensity_out);
	addAttribute(shadow_threshold_out);
	addAttribute(decay_out);

	attributeAffects(density_file, density_file_out);
	attributeAffects(density_scale, density_scale_out);
	attributeAffects(density_offset, density_offset_out);
	attributeAffects(density_read_mode, density_read_mode_out);
	attributeAffects(temperature_file, temperature_file_out);
	attributeAffects(temperature_scale, temperature_scale_out);
	attributeAffects(temperature_offset, temperature_offset_out);
	attributeAffects(temperature_read_mode, temperature_read_mode_out);
	attributeAffects(interpolation_mode, interpolation_mode_out);
	attributeAffects(fuel_type, fuel_type_out);
	attributeAffects(visual_adaptation_factor, visual_adaptation_factor_out);
	attributeAffects(intensity, intensity_out);
	attributeAffects(shadow_threshold, shadow_threshold_out);
	attributeAffects(decay, decay_out);

	return MS::kSuccess;
}
